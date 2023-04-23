using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public static  class KRenderTexture
{
    public static readonly int kCameraNormalTex = Shader.PropertyToID("_CameraNormalTexture");
    public static readonly RenderTargetIdentifier kRTCameraNormalTex = new RenderTargetIdentifier(kCameraNormalTex);
    
    public static readonly int kCameraMaskTex = Shader.PropertyToID("_CameraMaskTexture");
    public static readonly RenderTargetIdentifier kRTCameraMaskTex = new RenderTargetIdentifier(kCameraMaskTex);
    
    public static readonly int kCameraMotionVectorTex = Shader.PropertyToID("_CameraMotionVectorTexture");
    public static readonly RenderTargetIdentifier kRTCameraVectorMotionVectorTex = new RenderTargetIdentifier(kCameraMotionVectorTex);
    
    public static readonly int kCameraLightMaskTex = Shader.PropertyToID("_CameraLightMaskTexture");
    public static readonly RenderTargetIdentifier kRTCameraLightMaskTex = new RenderTargetIdentifier(kCameraLightMaskTex);
}

public static class KCameraParametersID
{
    public static readonly int kFrustumCornersRayBL = Shader.PropertyToID("_FrustumCornersRayBL");
    public static readonly int kFrustumCornersRayBR = Shader.PropertyToID("_FrustumCornersRayBR");
    public static readonly int kFrustumCornersRayTL = Shader.PropertyToID("_FrustumCornersRayTL");
    public static readonly int kFrustumCornersRayTR = Shader.PropertyToID("_FrustumCornersRayTR");

    public static readonly int kOrthoDirection = Shader.PropertyToID("_OrthoDirection");
    public static readonly int kOrthoBL = Shader.PropertyToID("_OrthoBL");
    public static readonly int kOrthoBR = Shader.PropertyToID("_OrthoBR");
    public static readonly int kOrthoTL = Shader.PropertyToID("_OrthoTL");
    public static readonly int kOrthoTR = Shader.PropertyToID("_OrthoTR");

    public static readonly int kMatrixV = Shader.PropertyToID("_Matrix_V");
    public static readonly int kMatrix_VP = Shader.PropertyToID("_Matrix_VP");
    public static readonly int kMatrix_I_VP = Shader.PropertyToID("_Matrix_I_VP");
}

public static class KGlobalParametersID
{
    public static readonly int kSourceTex = Shader.PropertyToID("_SourceTexture");
    public static readonly int kDestinationTex = Shader.PropertyToID("_DestinationTexture");
}