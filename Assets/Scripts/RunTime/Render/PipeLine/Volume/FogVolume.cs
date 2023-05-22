using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Rendering.Pipline
{
    [VolumeComponentMenu("Custom/Fog")]
    public class FogVolume : VolumeBase
    {
        public ColorParameter m_FogColor=new ColorParameter(UnityEngine.Color.white);
        public TextureParameter m_NoiseTex = new TextureParameter(null);
        public ClampedFloatParameter m_NoiseAmount=new ClampedFloatParameter(1,0,2);
        public ClampedFloatParameter m_FogHeightDensity=new ClampedFloatParameter(1,0,1);
        public ClampedFloatParameter m_FogDepthDensity=new ClampedFloatParameter(1,0,1);
        public Vector2Parameter m_FogSpeed = new Vector2Parameter(new Vector2(0.1f, 0.1f));
        public FloatRangeParameter m_FogHeightRange = new FloatRangeParameter(new Vector2(0,1), 0, 10);
        public FloatRangeParameter m_FogDepthRange = new FloatRangeParameter(new Vector2(0,100), 0, 200);

        public override PostProcessInjectionPoint InjectionPoint => PostProcessInjectionPoint.BeforePostProcess;

        public override PostProcessShaderType ShaderType => PostProcessShaderType.Material;

        private Material fogMat;

        public override bool IsActive()
        {
            if (fogMat == null)
                return false;
            return this.active;
        }

        public override bool CheckValid(RenderingData renderingData)
        {
            var layer = renderingData.cameraData.volumeLayerMask;
            if (!VolumeManager.instance.IsComponentActiveInMask<FogVolume>(layer))
                return false;
            fogMat=CoreUtils.CreateEngineMaterial(RenderResources.FindPostProcess("Hidden/PostPress/Fog"));
            return IsActive();
        }

        public override bool Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source,
            RenderTargetIdentifier destination)
        {
            fogMat.SetColor("_Color",m_FogColor.value);
            fogMat.SetTexture("_NoiseTex",m_NoiseTex.value);
            fogMat.SetFloat("_NoiseAmount",m_NoiseAmount.value);
            fogMat.SetFloat("_FogHeightDensity",m_FogHeightDensity.value);
            fogMat.SetFloat("_FogDepthDensity",m_FogDepthDensity.value);
            fogMat.SetVector("_FogSpeed",m_FogSpeed.value);
            fogMat.SetFloat("_FogHeightRange",m_FogHeightRange.value.x);
            fogMat.SetFloat("_FogHeightRangeEnd",m_FogHeightRange.value.y);
            fogMat.SetFloat("_FogDepthRange",m_FogDepthRange.value.x);
            fogMat.SetFloat("_FogDepthRangeEnd",m_FogDepthRange.value.y);
            cmd.Blit(source, destination, fogMat,-1);
            return true;
        }

        public override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
            CoreUtils.Destroy(fogMat);
        }
    }
}

