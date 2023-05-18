using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using Color = System.Drawing.Color;

namespace Rendering.Pipline
{
    using static KRenderTexture;
    public class SDP_NormalTexture : ScriptableRenderPass
    {
        // private Material m_NormalMat =
        //      CoreUtils.CreateEngineMaterial("Hidden/Internal-DepthNormalsTexture");
        private Material m_NormalMat = CoreUtils.CreateEngineMaterial(RenderResources.FindInclude("Hidden/DepthNormal"));
        
        private FilteringSettings m_FilteringSettings;
        private  string m_ProfilerTag = "DepthNormals Prepass";
        private ShaderTagId m_ShaderTagId = new ShaderTagId("DepthOnly");

        public SDP_NormalTexture(RenderQueueRange renderQueueRange, LayerMask layerMask)
        {
            m_FilteringSettings = new FilteringSettings(renderQueueRange, layerMask);
        }
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            cmd.GetTemporaryRT(kCameraNormalTex, cameraTextureDescriptor.width, cameraTextureDescriptor.height, 0, FilterMode.Point, RenderTextureFormat.ARGB32);
            ConfigureTarget(RTHandles.Alloc(kRTCameraNormalTex));
           // ConfigureClear(ClearFlag.All, UnityEngine.Color.black);
            base.Configure(cmd, cameraTextureDescriptor);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
            // using (new ProfilingScope(cmd, new ProfilingSampler( m_ProfilerTag)))
            // {
            //     context.ExecuteCommandBuffer(cmd);
            //     cmd.Clear();
            //
            //     var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
            //     var drawSettings = CreateDrawingSettings(m_ShaderTagId, ref renderingData, sortFlags);
            //     drawSettings.perObjectData = PerObjectData.None;
            //
            //
            //     ref CameraData cameraData = ref renderingData.cameraData;
            //     Camera camera = cameraData.camera;
            //     if (cameraData.xr.enabled)
            //         context.StartMultiEye(camera);
            //
            //
            //     drawSettings.overrideMaterial = m_NormalMat;
            //
            //
            //     context.DrawRenderers(renderingData.cullResults, ref drawSettings,
            //         ref m_FilteringSettings);
            //
            //     cmd.SetGlobalTexture(kCameraNormalTex, depthAttachmentHandle.nameID);
            // }
            //
            // context.ExecuteCommandBuffer(cmd);
            cmd.Blit(null,kCameraNormalTex,m_NormalMat);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();    
            CommandBufferPool.Release(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            base.FrameCleanup(cmd);
            cmd.ReleaseTemporaryRT(kCameraNormalTex);
        }
    }
}

