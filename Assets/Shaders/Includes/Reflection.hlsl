#ifndef Reflection
#define Reflection
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

TEXTURE2D(_SSRTex);SAMPLER(sampler_SSRTex);
TEXTURE2D(_SSPRTex);SAMPLER(sampler_SSPRTex);
TEXTURE2D(_PlanarTex);SAMPLER(sampler_PlanarTex);

float GetReflectionFresnel(float3 viewDir,float3 normal,float fresnelPower){
    float a = 1 - dot(viewDir,normal);
    return pow(a,fresnelPower);
}

half3 GetProbeReflect(float3 reflectDir,float3 positionWS)
{
    reflectDir=BoxProjectedCubemapDirection(reflectDir,positionWS,unity_SpecCube0_ProbePosition,unity_SpecCube0_BoxMin,unity_SpecCube0_BoxMax);
    half4 envCol=SAMPLE_TEXTURECUBE(unity_SpecCube0,samplerunity_SpecCube0,reflectDir);
    float3 envHdrCol=DecodeHDREnvironment(envCol,unity_SpecCube0_HDR);
    return envHdrCol;
}

half4 SampleSSPRTexture(float2 uv)
{
    float4 col=SAMPLE_TEXTURE2D(_SSPRTex,sampler_SSPRTex,uv);
    return col;
}

half3 SampleSSRTexture(float2 uv)
{
    float3 col=SAMPLE_TEXTURE2D(_SSRTex,sampler_SSRTex,uv).rgb;
    return col;
}

half3 SamplePlanarTexture(float2 uv)
{
    float3 col=SAMPLE_TEXTURE2D(_PlanarTex,sampler_PlanarTex,uv).rgb;
    return col;
}

half3 GetReflectionColor(float2 uv,float3 sourceCol,float fresnel,uint reflectType)
{
    half3 reflectCol=0;
    [branch]switch (reflectType)
    {
        default:break;
    case 0u:
        {
            half3 planarCol=SamplePlanarTexture(uv);
            reflectCol=lerp(sourceCol,planarCol,fresnel);
        }
        break;
    case 1u:
        {
            half3 ssrCol=SampleSSRTexture(uv);
            reflectCol=lerp(sourceCol,sourceCol+ssrCol,fresnel);
        }
        break;
    case 2u:
        {
            half4 ssprCol=SampleSSPRTexture(uv);
            reflectCol=lerp(sourceCol,sourceCol.rgb+ssprCol.rgb,ssprCol.a*fresnel);
        }
        break;
    }
    return reflectCol;
}
#endif