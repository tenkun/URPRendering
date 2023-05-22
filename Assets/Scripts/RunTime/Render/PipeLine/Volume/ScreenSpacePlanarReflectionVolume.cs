using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Rendering.Pipline
{
    [VolumeComponentMenu("Custom/Reflection/ScreenSpacePlanarReflection")]
    public class ScreenSpacePlanarReflectionVolume : VolumeBase
    {
        public ClampedFloatParameter m_RenderTextureSize = new ClampedFloatParameter(512,128,1024);
        public FloatParameter m_PlaneHeight = new FloatParameter(0);
        public ClampedFloatParameter m_FadeOutVetical = new ClampedFloatParameter(0.25f, 0, 1);
        public ClampedFloatParameter m_FadeOutHorizontal = new ClampedFloatParameter(0.35f, 0, 1);
        
        [Header("Performance")]
        public BoolParameter m_FillHole = new BoolParameter(false);

        public BoolParameter m_HDR = new BoolParameter(false);
        
        public override PostProcessInjectionPoint InjectionPoint => PostProcessInjectionPoint.AfterOpaqueAndSky;
        public override PostProcessShaderType ShaderType => PostProcessShaderType.Compute;

        private ComputeShader ssprCS;
        
        static readonly int ssprID = Shader.PropertyToID("_SSPRTex");
        static readonly int reDepthBufferID= Shader.PropertyToID("_ReDepthBufferRT");
        static readonly RenderTargetIdentifier sspr_Identifier =new RenderTargetIdentifier(ssprID);
        static readonly RenderTargetIdentifier reDepthBufferID_Identifier =new RenderTargetIdentifier(reDepthBufferID);
        
        const int SHADER_NUMTHREAD_X = 8; //must match compute shader's [numthread(x)]
        const int SHADER_NUMTHREAD_Y = 8; //must match compute shader's [numthread(y)]

        public override bool IsActive()
        {
            if (ssprCS == null)
                return false;
            return this.active;
        }

        public override bool CheckValid(RenderingData renderingData)
        {
            var layerMask = renderingData.cameraData.volumeLayerMask;
            if (!VolumeManager.instance.IsComponentActiveInMask<ScreenSpacePlanarReflectionVolume>(layerMask))
                return false;
            ssprCS = RenderResources.FindComputeShader("ScreenSpacePlanarReflect");
            return IsActive();
        }

        public override bool Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source,
            RenderTargetIdentifier destination)
        {
            float aspect = (float)Screen.width/Screen.height;
            Vector2 rtSize = new Vector2(
                    Mathf.CeilToInt(m_RenderTextureSize.value * aspect / SHADER_NUMTHREAD_X) * SHADER_NUMTHREAD_X,
                    Mathf.CeilToInt(m_RenderTextureSize.value / SHADER_NUMTHREAD_Y) * SHADER_NUMTHREAD_Y);
           
            RenderTextureFormat format = m_HDR.value ? RenderTextureFormat.ARGBHalf : RenderTextureFormat.ARGB32;
            if (renderingData.cameraData.cameraTargetDescriptor.colorFormat==RenderTextureFormat.ARGB32)
            {
                format = RenderTextureFormat.ARGB32;
            }
            
            RenderTextureDescriptor descriptor = new RenderTextureDescriptor(Mathf.CeilToInt(m_RenderTextureSize.value*aspect),
                Mathf.CeilToInt(m_RenderTextureSize.value),format);
            descriptor.enableRandomWrite = true;
            
            cmd.GetTemporaryRT(ssprID,descriptor,FilterMode.Bilinear);
            cmd.GetTemporaryRT(reDepthBufferID,descriptor,FilterMode.Bilinear);
            int ssprKernelId = ssprCS.FindKernel("ScreenSpacePlanarReflect");
            cmd.SetComputeFloatParam(ssprCS,Shader.PropertyToID("_PlaneHeight"),m_PlaneHeight.value);
            cmd.SetComputeVectorParam(ssprCS,Shader.PropertyToID("_RTSize"),rtSize);
            cmd.SetComputeTextureParam(ssprCS,ssprKernelId,ssprID,sspr_Identifier);
            cmd.SetComputeTextureParam(ssprCS,ssprKernelId,Shader.PropertyToID("_CameraOpaqueTexture"),renderingData.cameraData.renderer.cameraColorTargetHandle);
            cmd.SetComputeTextureParam(ssprCS,ssprKernelId,Shader.PropertyToID("_CameraDepthTexture"),renderingData.cameraData.renderer.cameraDepthTargetHandle);
            cmd.SetComputeTextureParam(ssprCS, ssprKernelId, reDepthBufferID, reDepthBufferID_Identifier);

            cmd.DispatchCompute(ssprCS, ssprKernelId, (int)rtSize.x / SHADER_NUMTHREAD_X,
                (int)rtSize.y / SHADER_NUMTHREAD_Y, 1);
            if (m_FillHole.value)
            {
                int fillHoleKernel = ssprCS.FindKernel("FillHoles");
                cmd.DispatchCompute(ssprCS,fillHoleKernel,Mathf.CeilToInt(rtSize.x/2),Mathf.CeilToInt(rtSize.y/2),1);
            }
            return false;
        }
    }    
}

