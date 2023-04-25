using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Rendering.Pipline
{
    [VolumeComponentMenu("Custom/Reflection")]
    public class ReflectionVolume : VolumeBase
    {
        public override bool IsActive()
        {
            return this.active;
        }

        public override bool CheckValid(RenderingData renderingData)
        {
            var layer = renderingData.cameraData.volumeLayerMask;
            if (!VolumeManager.instance.IsComponentActiveInMask<ReflectionVolume>(layer))
                return false;
            return true;
        }

        public override bool Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source,
            RenderTargetIdentifier destination)
        {
            return false;
        }
    }  
}
