using System.Collections;
using System.Collections.Generic;
using UnityEngine.Rendering.Universal;
using UnityEngine;

namespace Rendering.Pipline
{
    public class SDF_Extended : ScriptableRendererFeature
    {
        public RenderResources m_Resources;
        
        private SDP_GlobalParameters m_GlobalParameters;
        
        public override void Create()
        {
            if(!m_Resources)
                return;
            
            m_GlobalParameters = new SDP_GlobalParameters();
            m_GlobalParameters.renderPassEvent = RenderPassEvent.BeforeRendering;
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if(!m_Resources)
                return;
            
            renderer.EnqueuePass(m_GlobalParameters);
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
        }
    }
}