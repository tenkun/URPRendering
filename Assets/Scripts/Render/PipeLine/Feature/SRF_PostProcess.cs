using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.Linq;
using UnityEngine.Rendering;
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
            // public RenderPassEvent m_RenderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
            public BufferType sourceType = BufferType.CameraColor;
            public BufferType destinationType = BufferType.CameraColor;
        }

        public Settings settings = new Settings();
        private SDP_PostProcess afterOpaqueAndSky;
        private SDP_PostProcess beforePostProcess;
        private SDP_PostProcess afterPostProcess;

        private List<VolumeBase> _volumeBases;

        public override void Create()
        {
            if (!m_Resources)
                return;

            var stack = VolumeManager.instance.stack;
            _volumeBases = VolumeManager.instance.baseComponentTypeArray.Where(t =>
                    t.IsSubclassOf(typeof(VolumeBase)) && stack.GetComponent(t) != null)
                .Select(t => stack.GetComponent(t) as VolumeBase).ToList();

            var afterOpaqueAndSkyVolume = _volumeBases
                .Where(v => v.InjectionPoint == PostProcessInjectionPoint.AfterOpaqueAndSky)
                .OrderBy(v => v.OrderInPass).ToList();
            afterOpaqueAndSky = new SDP_PostProcess(this.name,this.settings,afterOpaqueAndSkyVolume);
            afterOpaqueAndSky.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;

            var beforePostProcessVolume = _volumeBases
                .Where(v => v.InjectionPoint == PostProcessInjectionPoint.BeforePostProcess)
                .OrderBy(v => v.OrderInPass).ToList();
            beforePostProcess = new SDP_PostProcess(this.name,this.settings,beforePostProcessVolume);
            beforePostProcess.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
            
            var afterPostProcessVolume = _volumeBases
                .Where(v => v.InjectionPoint == PostProcessInjectionPoint.AfterPostProcess)
                .OrderBy(v => v.OrderInPass).ToList();
            afterPostProcess = new SDP_PostProcess(this.name,this.settings,afterPostProcessVolume);
            afterPostProcess.renderPassEvent = RenderPassEvent.AfterRendering;
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (!m_Resources)
                return;
            
            if(afterOpaqueAndSky.SetupVolume())
                renderer.EnqueuePass(afterOpaqueAndSky);
            
            if(beforePostProcess.SetupVolume())
                renderer.EnqueuePass(beforePostProcess);
            
            if(afterPostProcess.SetupVolume())
                renderer.EnqueuePass(afterPostProcess);
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
            if (disposing && _volumeBases != null)
            {
                foreach (var volume in _volumeBases)
                {
                    volume.Dispose();
                }
            }
        }
    }
}

