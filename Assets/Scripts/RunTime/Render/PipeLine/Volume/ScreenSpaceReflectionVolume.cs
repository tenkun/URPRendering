using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.U2D;

namespace Rendering.Pipline
{
    [VolumeComponentMenu("Custom/Reflection/ScreenSpaceReflection")]
    public class ScreenSpaceReflectionVolume : VolumeBase
    {
        [Header("SSR")]
        public ClampedFloatParameter m_MaxRayMarchingDistance = new ClampedFloatParameter(500,0,1000,true);
        public ClampedIntParameter m_MaxRayMarchingStep = new ClampedIntParameter(64, 0, 256);
        //public ClampedIntParameter m_MaxRayMarchingBinarySearchCount = new ClampedIntParameter(8, 0, 32);
        public ClampedFloatParameter m_RayMarchingStepSize = new ClampedFloatParameter(8, 1, 10);
        public ClampedFloatParameter m_DepthThickness = new ClampedFloatParameter(0.01f, 0, 2);

        [Header("Blur")] 
        public ClampedFloatParameter m_BlurRadius = new ClampedFloatParameter(5, 0, 15);
        public ClampedIntParameter m_Iteration = new ClampedIntParameter(4,1,10);
        public ClampedFloatParameter m_RTDownScaling = new ClampedFloatParameter(2,1,10);

        private Material ssrMat;
        int ssr_handle;

        private int[] downSampleID;
        private int[] upSampleID;
        
        public override PostProcessInjectionPoint InjectionPoint => PostProcessInjectionPoint.AfterOpaqueAndSky;

        public override bool IsActive()
        {
            if (ssrMat == null)
                return false;
            return this.active;
        }

        public override bool CheckValid(RenderingData renderingData)
        {
            var layer = renderingData.cameraData.volumeLayerMask;
            if (!VolumeManager.instance.IsComponentActiveInMask<ScreenSpaceReflectionVolume>(layer))
                return false;
            ssrMat = CoreUtils.CreateEngineMaterial(RenderResources.FindInclude("Hidden/SSR"));
            ssr_handle = Shader.PropertyToID("_SSRTexture");
            return true;
        }

        public override bool Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source,
            RenderTargetIdentifier destination)
        {
            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            #region ssr
            
            cmd.GetTemporaryRT(ssr_handle,descriptor,FilterMode.Bilinear);
            ssrMat.SetFloat("_MaxDistance",m_MaxRayMarchingDistance.value);
            ssrMat.SetInt("_MaxStep",m_MaxRayMarchingStep.value);
            //ssrMat.SetInt("_MaxSearchCount",m_MaxRayMarchingBinarySearchCount.value);
            ssrMat.SetFloat("_StepSize",m_RayMarchingStepSize.value);
            ssrMat.SetFloat("_DepthThickness",m_DepthThickness.value);
            ssrMat.SetFloat("_BlurOffset",m_BlurRadius.value);
            cmd.Blit(source, ssr_handle, ssrMat,0);
            
            #endregion

            #region dual-kawase

            int tw = (int)(descriptor.width / m_RTDownScaling.value);
            int th = (int)(descriptor.height / m_RTDownScaling.value);
            downSampleID = new int[16];
            upSampleID = new int[16];
            for (int i = 0; i < m_Iteration.value; i++)
            {
                downSampleID[i] = Shader.PropertyToID("_DownSample" + i);
                upSampleID[i] = Shader.PropertyToID("_UpSample" + i);
            }

            int temp = ssr_handle;
            for (int i = 0; i < m_Iteration.value; i++)
            {
                cmd.GetTemporaryRT(downSampleID[i], tw, th, descriptor.depthBufferBits, FilterMode.Bilinear,RenderTextureFormat.ARGB32);
                cmd.GetTemporaryRT(upSampleID[i],tw,th,descriptor.depthBufferBits,FilterMode.Bilinear,RenderTextureFormat.ARGB32);
                tw = Mathf.Max(tw /2, 1);
                th = Mathf.Max(th / 2, 1);
                cmd.Blit(temp,downSampleID[i],ssrMat,1);
                temp = downSampleID[i];
            }

            for (int i = 0; i < m_Iteration.value-2; i++)
            {
                cmd.Blit(temp,upSampleID[i],ssrMat,2);
                temp = upSampleID[i];
            }
            cmd.Blit(temp,ssr_handle);

            for (int i = 0; i < m_Iteration.value; i++)
            {
                cmd.ReleaseTemporaryRT(downSampleID[i]);
                cmd.ReleaseTemporaryRT(upSampleID[i]);
            }

            #endregion
            
            return false;
        }
    }  
}
