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
            for (int i = m_Volumes.Count - 1; i >= 0; --i)
            {
                if (!m_Volumes[i].IsActive())
                {
                    m_Volumes.RemoveAt(i);
                }
            }

            return m_Volumes.Count > 0; 
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

        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
            cmd.Clear();

            if (m_Volumes.Count <= 1)
            {
                if (!m_Volumes[0].CheckValid(renderingData))
                {
                    CommandBufferPool.Release(cmd);
                    return;
                }
            }
            cmd.Blit(source,temp1);
            foreach (var volume in m_Volumes)
            {
                if(!volume.CheckValid(renderingData))
                    continue;

                bool success = false;
                using (new ProfilingScope(cmd,profilingSampler))
                {
                    success=volume.Render(cmd,ref renderingData,temp1,temp2);
                }
                if(!success)
                    continue;
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
            // foreach (var item in m_Volumes)
            // {
            //     item.Dispose();
            // }
        }
        
    }
}
