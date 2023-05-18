using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Rendering.Pipline
{
    [VolumeComponentMenu("Custom/Reflection/ScreenSpacePlanarReflection")]
    public class ScreenSpacePlanarReflectionVolume : VolumeBase
    {
        public override bool IsActive()
        {
            return this.active;
        }

        public override bool CheckValid(RenderingData renderingData)
        {
            var layerMask = renderingData.cameraData.volumeLayerMask;
            if (!VolumeManager.instance.IsComponentActiveInMask<ScreenSpacePlanarReflectionVolume>(layerMask))
                return false;
            return false;
        }

        public override bool Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source,
            RenderTargetIdentifier destination)
        {
            Debug.Log("planar reflection");
            //throw new System.NotImplementedException();
            return false;
        }
    }    
}

