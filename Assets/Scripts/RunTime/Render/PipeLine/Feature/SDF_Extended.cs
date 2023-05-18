using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.Rendering.Universal;
using UnityEngine;
using UnityEngine.Rendering;

namespace Rendering.Pipline
{
    [Serializable]
    public struct SDFExtendedSetting
    {
        public bool m_Normal;
        public bool m_Mask;

        public static SDFExtendedSetting kDefault = new SDFExtendedSetting()
        {
            m_Normal = false,
            m_Mask = false,
        };
    }
    public class SDF_Extended : ScriptableRendererFeature
    {
        public RenderResources m_Resources;
        public SDFExtendedSetting m_Setting = SDFExtendedSetting.kDefault;
        
        private SDP_GlobalParameters m_GlobalParameters;
        private SDP_NormalTexture m_NormalTexture;
        
        public override void Create()
        {
            if(!m_Resources)
                return;
            
            m_GlobalParameters = new SDP_GlobalParameters();
            m_GlobalParameters.renderPassEvent = RenderPassEvent.BeforeRendering;

            if (m_Setting.m_Normal)
            {
                m_NormalTexture = new SDP_NormalTexture(RenderQueueRange.opaque,-1);
                m_NormalTexture.renderPassEvent = RenderPassEvent.AfterRenderingPrePasses;
                m_NormalTexture.renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
            }
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if(!m_Resources)
                return;
            
            renderer.EnqueuePass(m_GlobalParameters);
            
            if (m_Setting.m_Normal)
            {
                renderer.EnqueuePass(m_NormalTexture);
            }
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
        }
    }
}