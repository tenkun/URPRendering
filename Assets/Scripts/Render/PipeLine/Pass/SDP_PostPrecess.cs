using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Rendering.Pipline
{
    public class SDP_PostProcess : ScriptableRenderPass
    {
        private ComputeShader colorAdjustmentCS = RenderResources.FindComputeShader("ColorAdjustment");
        private Material colorAdjustmentMat=new Material(RenderResources.FindPostProcess("Game/PostProcess/ColorAdjustment"));
       
        public FilterMode filterMode { get; set; }
        private string m_ProfilerTag;
        private RenderTargetIdentifier source;
        private RenderTargetIdentifier destination;
        private RenderTargetIdentifier temp1;
        private RenderTargetIdentifier temp2;
        int temporaryRTId1 = Shader.PropertyToID("_TempRT1");
        int temporaryRTId2 = Shader.PropertyToID("_TempRT2");
        
        ColorAdjustmentVolume colorAdjustmentVolume;

        private SRF_PostProcess.Settings m_settings;

        private List<VolumeBase> m_Volumes;

        public SDP_PostProcess(string profilterTag, SRF_PostProcess.Settings settings, List<VolumeBase> volumes)
        {
            m_ProfilerTag = profilterTag;
            m_settings = settings;
            m_Volumes = volumes;
        }

        public bool SetupVolume()
        {
            int activeCount=0;
            foreach (var volume in m_Volumes)
            {
                volume.Setup();
                if (volume.IsActive())
                {
                    activeCount++;
                }
            }

            return activeCount > 0; 
        }
        
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            RenderTextureDescriptor blitTargetDescriptor = new RenderTextureDescriptor(cameraTextureDescriptor.width, cameraTextureDescriptor.height,cameraTextureDescriptor.colorFormat,cameraTextureDescriptor.depthBufferBits);
            blitTargetDescriptor.enableRandomWrite = true;
            
            cmd.GetTemporaryRT(temporaryRTId1, blitTargetDescriptor, filterMode);
            temp1 = new RenderTargetIdentifier(temporaryRTId1);
            cmd.GetTemporaryRT(temporaryRTId2,blitTargetDescriptor,filterMode);
            temp2 = new RenderTargetIdentifier(temporaryRTId2);
        }

        public override void OnCameraSetup(CommandBuffer cmd,ref RenderingData renderingData)
        {
            if(!m_settings.m_ColorAdjustment)
                return;
            
            var renderer = renderingData.cameraData.renderer;
            source =  renderer.cameraColorTargetHandle;
            if (this.renderPassEvent == RenderPassEvent.AfterRendering)
            {
                var destinationId = Shader.PropertyToID("_AfterPostProcessTexture");
                destination = new RenderTargetIdentifier(destinationId);
            }
            else
            {
                destination = source;
            }

            var postStack = VolumeManager.instance.stack;
            colorAdjustmentVolume = postStack.GetComponent<ColorAdjustmentVolume>();
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
            cmd.Clear();


            // colorAdjustmentMat.SetFloat("_Contrast",colorAdjustmentVolume.m_Contrast.value);
            // colorAdjustmentMat.SetFloat("_Brightness",colorAdjustmentVolume.m_Brightness.value);
            // colorAdjustmentMat.SetFloat("_Saturate",colorAdjustmentVolume.m_Saturation.value);
            // cmd.Blit( source, destination, colorAdjustmentMat,-1);
            if (m_Volumes.Count <= 1)
            {
                if (!m_Volumes[0].IsActive())
                {
                    CommandBufferPool.Release(cmd);
                    return;
                }
            }
            cmd.Blit(source,temp1);
            foreach (var volume in m_Volumes)
            {
                if(!volume.IsActive())
                    continue;

                using (new ProfilingScope(cmd,profilingSampler))
                {
                    volume.Render(cmd,ref renderingData,temp1,temp2);
                }
                CoreUtils.Swap(ref temp1,ref temp2);
            }
            cmd.Blit(temp1, destination);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
        
        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(temporaryRTId1);
            cmd.ReleaseTemporaryRT(temporaryRTId2);
        }
        
    }
}
