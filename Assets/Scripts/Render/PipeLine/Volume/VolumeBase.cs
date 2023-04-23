using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Rendering.Pipline
{
    public enum PostProcessInjectionPoint
    {
        AfterOpaqueAndSky,
        BeforePostProcess,
        AfterPostProcess
    }

    public enum PostProcessShaderType
    {
        Material,
        Compute
    }
    
    public abstract class VolumeBase : VolumeComponent,IPostProcessComponent,IDisposable
    {
        public virtual int OrderInPass => 0;
        public virtual PostProcessInjectionPoint InjectionPoint => PostProcessInjectionPoint.AfterPostProcess;
        public virtual PostProcessShaderType ShaderType => PostProcessShaderType.Material;
        
        public abstract void Setup();

        public abstract void Render(CommandBuffer cmd, ref RenderingData renderingData,
            RenderTargetIdentifier source,RenderTargetIdentifier destination);

        #region  IPostProcessComponent

        public abstract bool IsActive();
        public virtual bool IsTileCompatible() => false;
        
        #endregion

        #region  IDisposable

        ~VolumeBase()
        {
            Dispose(false);
        }
        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }
        public virtual void Dispose(bool disposing) { }

        #endregion

    }

}