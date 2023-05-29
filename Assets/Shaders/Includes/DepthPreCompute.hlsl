float3 _FrustumCornersRayBL;
float3 _FrustumCornersRayBR;
float3 _FrustumCornersRayTL;
float3 _FrustumCornersRayTR;

float4x4 _Matrix_VP;
float4x4 _Matrix_V;
float4x4 _Matrix_I_VP;
float4x4 _Matrix_P;
float4x4 _Matrix_I_P;

inline float RawToEyeDepthOrthographic(float _rawDepth,float4 _projectionParams)
{
    #if UNITY_REVERSED_Z
    _rawDepth=1.0f-_rawDepth;
    #endif
    return lerp(_projectionParams.y,_projectionParams.z,_rawDepth);
}

inline float RawToEyeDepthPerspective(float _rawDepth,float4 _zBufferParams)
{
    return LinearEyeDepth(_rawDepth,_zBufferParams);
}

float RawToEyeDepth(float _rawDepth)
{
    [branch]
    if(unity_OrthoParams.w)
        return RawToEyeDepthOrthographic(_rawDepth,_ProjectionParams);
    else
        return RawToEyeDepthPerspective(_rawDepth,_ZBufferParams);
}

float3 TransformNDCToFrustumCornersRay(float2 uv)
{
    return bilinearLerp(_FrustumCornersRayTL, _FrustumCornersRayTR, _FrustumCornersRayBL, _FrustumCornersRayBR, uv);
}

float3 TransformNDCToWorld_Perspective(float2 uv,float _rawDepth)
{
    return GetCameraPositionWS() + LinearEyeDepth(_rawDepth,_ZBufferParams) *  TransformNDCToFrustumCornersRay(uv);
}

float3 ReconstructWorldPosition(float2 screenUV,float rawDepth)
{
    float4 positionNDC=float4(screenUV*2-1,rawDepth,1);

    #if UNITY_UV_STARTS_AT_TOP
    positionNDC.y = -positionNDC.y;
    #endif

    float4 positionWS=mul( _Matrix_I_VP,positionNDC);
    positionWS/=positionWS.w;
    return  positionWS.xyz;
}

float3 TransformNDCToWorld(float2 uv,float rawDepth)
{
    if(unity_OrthoParams.w)
        return ReconstructWorldPosition(uv,rawDepth);
    else
        return TransformNDCToWorld_Perspective(uv,rawDepth);
}

float GetDepthDiffVS(float rawDepth,float surfaceDepth)
{
    float depth=RawToEyeDepth(rawDepth);
    float depthDiff=depth-surfaceDepth+0.001;
    return  depthDiff;
}

float4 TransformClipToScreen(float4 clipPos)
{
    float4 screenPos= clipPos;
    screenPos.xy/=screenPos.w;
    screenPos.xy=screenPos.xy*0.5+0.5;
       ;
    #if UNITY_UV_STARTS_AT_TOP
    screenPos.y=1.h-screenPos.y;
    #endif
    return  screenPos;
}

float4 TransformHClipToScreen(float4 hclipPos)
{
    float2 uv= hclipPos.xy/_ScaledScreenParams.xy;
    return  float4(uv,hclipPos.zw);
}