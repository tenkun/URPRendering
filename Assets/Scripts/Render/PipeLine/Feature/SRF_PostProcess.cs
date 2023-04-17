using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using UnityEngine.Rendering.Universal;

namespace Rendering.Pipline
{
    public enum BufferType
    {
        CameraColor,
        Custom
    }
    
    public class SRF_PostProcess : ScriptableRendererFeature
    {
        public RenderResources m_Resources;
        [Serializable]
        public class Settings
        {
            public bool m_ColorAdjustment = true;
            public RenderPassEvent m_RenderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
            public BufferType sourceType = BufferType.CameraColor;
            public BufferType destinationType = BufferType.CameraColor;
        }

        public Settings settings = new Settings();
        private SDP_PostProcess blitPass;
        
        public override void Create()
        {
            if (!m_Resources)
                return;
            blitPass = new SDP_PostProcess(this.name,this.settings);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (!m_Resources)
                return;
            blitPass.renderPassEvent = settings.m_RenderPassEvent;
            renderer.EnqueuePass(blitPass);
        }
        
    }
}

