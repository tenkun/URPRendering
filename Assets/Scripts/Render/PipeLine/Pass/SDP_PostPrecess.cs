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
        int temporaryRTId = Shader.PropertyToID("_TempRT");
        
        ColorAdjustmentVolume colorAdjustmentVolume;

        private SRF_PostProcess.Settings m_settings;
        
        int sourceId;
        int destinationId;
        bool isSourceAndDestinationSameTarget;

        public SDP_PostProcess(string name, SRF_PostProcess.Settings settings)
        {
            m_ProfilerTag = name;
            m_settings = settings;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {

        }

        public override void OnCameraSetup(CommandBuffer cmd,ref RenderingData renderingData)
        {
            if(!m_settings.m_ColorAdjustment)
                return;
            RenderTextureDescriptor blitTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            blitTargetDescriptor = new RenderTextureDescriptor(blitTargetDescriptor.width, blitTargetDescriptor.height,blitTargetDescriptor.colorFormat,blitTargetDescriptor.depthBufferBits);
            blitTargetDescriptor.enableRandomWrite = true;
            blitTargetDescriptor.depthStencilFormat = GraphicsFormat.None;

            isSourceAndDestinationSameTarget = m_settings.sourceType == m_settings.destinationType &&
                                               (m_settings.sourceType == BufferType.CameraColor);

            var renderer = renderingData.cameraData.renderer;

            if (m_settings.sourceType == BufferType.CameraColor)
            {
                sourceId = -1;
                source = renderer.cameraColorTargetHandle;
            }
            else
            {
                sourceId = KGlobalParametersID.kSourceTex;
                cmd.GetTemporaryRT(sourceId, blitTargetDescriptor, filterMode);
                source = new RenderTargetIdentifier(sourceId);
            }

            if (isSourceAndDestinationSameTarget)
            {
                destinationId = temporaryRTId;
                cmd.GetTemporaryRT(destinationId, blitTargetDescriptor, filterMode);
                destination = new RenderTargetIdentifier(destinationId);
            }
            else if (m_settings.destinationType == BufferType.CameraColor)
            {
                destinationId = -1;
                destination = renderer.cameraColorTargetHandle;
            }
            else
            {
                destinationId = KGlobalParametersID.kDestinationTex;
                cmd.GetTemporaryRT(destinationId, blitTargetDescriptor, filterMode);
                destination = new RenderTargetIdentifier(destinationId);
            }

            var postStack = VolumeManager.instance.stack;
            colorAdjustmentVolume = postStack.GetComponent<ColorAdjustmentVolume>();
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if(!m_settings.m_ColorAdjustment)
                return;
            CommandBuffer cmd = CommandBufferPool.Get("Color Adjustment");
            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            int kernelId = colorAdjustmentCS.FindKernel("ColorAdjustment");
            cmd.SetComputeFloatParam(colorAdjustmentCS,"Brightness",colorAdjustmentVolume.m_Brightness.value);
            cmd.SetComputeFloatParam(colorAdjustmentCS,"Saturation",colorAdjustmentVolume.m_Saturation.value);
            cmd.SetComputeFloatParam(colorAdjustmentCS,"Contrast",colorAdjustmentVolume.m_Contrast.value);
            cmd.SetComputeTextureParam(colorAdjustmentCS,kernelId,"Result",destination);
            cmd.SetComputeTextureParam(colorAdjustmentCS,kernelId,"Source",source);
            cmd.DispatchCompute(colorAdjustmentCS,kernelId,(int)desc.width/8,(int)desc.height/8,1);
            int tempColorTargetID=Shader.PropertyToID("_TempColorTarget");
            cmd.GetTemporaryRT(tempColorTargetID,desc);
            RenderTargetIdentifier tempColorTarget = new RenderTargetIdentifier(tempColorTargetID);
            cmd.Blit(renderingData.cameraData.renderer.cameraColorTargetHandle,tempColorTarget);
            // colorAdjustmentMat.SetFloat("_Contrast",colorAdjustmentVolume.m_Contrast.value);
            // colorAdjustmentMat.SetFloat("_Brightness",colorAdjustmentVolume.m_Brightness.value);
            // colorAdjustmentMat.SetFloat("_Saturate",colorAdjustmentVolume.m_Saturation.value);
            // cmd.Blit( source, destination, colorAdjustmentMat,-1);
            
            cmd.Blit(destination, source);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
        
        public override void FrameCleanup(CommandBuffer cmd)
        {
            if (destinationId != -1)
                cmd.ReleaseTemporaryRT(destinationId);

            if (source == destination && sourceId != -1)
                cmd.ReleaseTemporaryRT(sourceId);
            //CoreUtils.Destroy(colorAdjustmentMat);
        }
        
    }
}
