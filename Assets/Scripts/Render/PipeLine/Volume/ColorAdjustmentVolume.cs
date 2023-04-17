using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Rendering.Pipline
{
    [Serializable,VolumeComponentMenu("Custom/ColorAdjustment")]
    public class ColorAdjustmentVolume : VolumeBase
    {
        public ClampedFloatParameter m_Saturation=new ClampedFloatParameter(1,0,2);
        public ClampedFloatParameter m_Brightness=new ClampedFloatParameter(1,0,2);
        public ClampedFloatParameter m_Contrast=new ClampedFloatParameter(1,-2,3);
        
        public override bool IsActive()
        {
            return this.active;
        }

        public override void Setup()
        {
            throw new System.NotImplementedException();
        }

        public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier renderTargetIdentifier)
        {
            throw new System.NotImplementedException();
        }
    }
}
