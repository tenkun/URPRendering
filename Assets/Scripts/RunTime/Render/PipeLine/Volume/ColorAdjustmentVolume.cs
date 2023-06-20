using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEditor.ShaderGraph.Drawing.Colors;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Rendering.Pipline
{
    [Serializable,VolumeComponentMenu("Custom/ColorAdjustment")]
    public class ColorAdjustmentVolume : VolumeBase
    {
        public ClampedFloatParameter m_Saturation=new ClampedFloatParameter(1,0,2,true);
        public ClampedFloatParameter m_Brightness=new ClampedFloatParameter(1,0,2,true);
        public ClampedFloatParameter m_Contrast=new ClampedFloatParameter(1,-2,3,true);

        public override PostProcessInjectionPoint InjectionPoint => PostProcessInjectionPoint.BeforePostProcess;

        public override PostProcessShaderType ShaderType => PostProcessShaderType.Material;

        private ComputeShader colorAdjustmentCS;

        private Material colorAdjustmentMat;

        private void Awake()
        {
            colorAdjustmentMat=CoreUtils.CreateEngineMaterial(RenderResources.FindPostProcess("Game/PostProcess/ColorAdjustment"));
        }

        public override bool IsActive()
        {
            if (colorAdjustmentMat == null)
                return false;
            return this.active;
        }

        public override bool CheckValid(RenderingData renderingData)
        {
            var layer = renderingData.cameraData.volumeLayerMask;
            if (!VolumeManager.instance.IsComponentActiveInMask<ColorAdjustmentVolume>(layer))
                return false;
            return IsActive();
        }

        public override bool Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source,
            RenderTargetIdentifier destination)
        {
            // RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            // int kernelId = colorAdjustmentCS.FindKernel("ColorAdjustment");
            // cmd.SetComputeFloatParam(colorAdjustmentCS,"Brightness",m_Brightness.value);
            // cmd.SetComputeFloatParam(colorAdjustmentCS,"Saturation",m_Saturation.value);
            // cmd.SetComputeFloatParam(colorAdjustmentCS,"Contrast",m_Contrast.value);
            // cmd.SetComputeTextureParam(colorAdjustmentCS,kernelId,"Result",destination);
            // cmd.SetComputeTextureParam(colorAdjustmentCS,kernelId,"Source",source);
            // cmd.DispatchCompute(colorAdjustmentCS,kernelId,(int)desc.width/8,(int)desc.height/8,1);
            colorAdjustmentMat.SetFloat("_Contrast",m_Contrast.value);
            colorAdjustmentMat.SetFloat("_Brightness",m_Brightness.value);
            colorAdjustmentMat.SetFloat("_Saturate",m_Saturation.value);
            cmd.Blit( source, destination, colorAdjustmentMat,-1);
            return true;
        }

        public override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
            CoreUtils.Destroy(colorAdjustmentMat);
        }
    }
}
