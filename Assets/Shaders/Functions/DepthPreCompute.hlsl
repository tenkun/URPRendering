float3 ReconstructWorldPosition(float depthNDC, float2 screenPos)
{
    float4 positionNDC=float4(screenPos*2-1,depthNDC,1);
    #if UNITY_UV_STARTS_AT_TOP
    positionNDC.y = -positionNDC.y;
    #endif
    float4 positionWS=mul(UNITY_MATRIX_I_VP,positionNDC);
    positionWS/=positionWS.w;
    return  positionWS.xyz;
}

float3 ReconstructWorldPosition(float depthNDC, float4 screenPos)
{
    float4 ndcPos=screenPos*2-1;
    #if UNITY_UV_STARTS_AT_TOP
    ndcPos.y = -ndcPos.y;
    #endif
    float3 clipVec=float3(ndcPos.x,ndcPos.y,ndcPos.z)*_ProjectionParams.z;
    float3 viewVec=mul(UNITY_MATRIX_I_VP,clipVec);
    float depth=Linear01Depth(depthNDC,_ProjectionParams);
    float3 viewPos=viewVec*depth;
    float3 worldPos=TransformViewToWorld(float4(viewPos,1));
    return  worldPos.xyz;
}

float GetDepthDiffVS(float bgDepth,float surfaceDepth)
{
    float depthVale=LinearEyeDepth(bgDepth, _ZBufferParams);
    float depthDiff=(depthVale-surfaceDepth)*0.05;
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