#ifndef Reflection
#define Reflection
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

TEXTURE2D(_SSRTex);SAMPLER(sampler_SSRTex);
TEXTURE2D(_SSPRTex);SAMPLER(sampler_SSPRTex);
TEXTURE2D(_PlanarTex);SAMPLER(sampler_PlanarTex);
SamplerState sampler_Trilinear_Clamp_Aniso8;
SamplerState sampler_point_Clamp;

float GetReflectionFresnel(float3 viewDir,float3 normal,float fresnelPower){
    float a = 1 - dot(viewDir,normal);
    return pow(a,fresnelPower);
}

half4 AnisotropicReflection(float3 normal,float3 viewDir,float2 uv,Texture2D sampleTex)
{
    float ndotV=saturate(dot(normal,viewDir));
    float3 biTangent=normalize(normal/ndotV-viewDir*ndotV);
    float3 tangent=cross(biTangent,viewDir);
    float3 dRdx=tangent*(0.9*(1-ndotV)+0.1);
    float3 dRDy=biTangent*(-3*(1-ndotV)+4);
    float4 col= SAMPLE_TEXTURE2D(sampleTex,sampler_Trilinear_Clamp_Aniso8,uv);
    float4 anisoCol=SAMPLE_TEXTURE2D_GRAD(sampleTex,sampler_Trilinear_Clamp_Aniso8,uv,length(dRdx),length(dRDy));
    col=lerp(col,anisoCol,ndotV);
    return col;
}

half3 GetProbeReflect(float3 reflectDir,float3 positionWS)
{
    reflectDir=BoxProjectedCubemapDirection(reflectDir,positionWS,unity_SpecCube0_ProbePosition,unity_SpecCube0_BoxMin,unity_SpecCube0_BoxMax);
    half4 envCol=SAMPLE_TEXTURECUBE(unity_SpecCube0,samplerunity_SpecCube0,reflectDir);
    float3 envHdrCol=DecodeHDREnvironment(envCol,unity_SpecCube0_HDR);
    return envHdrCol;
}

half4 SampleSSPRTexture(float2 uv,bool anisotropic,float3 normal,float3 viewDir)
{
    if(anisotropic)
    {
        return AnisotropicReflection(normal,viewDir,uv,_SSPRTex);
    }
    float4 col=SAMPLE_TEXTURE2D(_SSPRTex,sampler_SSPRTex,uv);
    return col;
}

half3 SampleSSRTexture(float2 uv,bool anisotropic,float3 normal,float3 viewDir)
{
    if(anisotropic)
    {
        return AnisotropicReflection(normal,viewDir,uv,_SSRTex).rgb;
    }
    float3 col=SAMPLE_TEXTURE2D(_SSRTex,sampler_SSRTex,uv).rgb;
    return col;
}

half3 SamplePlanarTexture(float2 uv,bool anisotropic,float3 normal,float3 viewDir)
{
    if(anisotropic)
    {
        return AnisotropicReflection(normal,viewDir,uv,_PlanarTex).rgb;
    }
    float3 col=SAMPLE_TEXTURE2D(_PlanarTex,sampler_PlanarTex,uv).rgb;
    return col;
}


half3 GetReflectionColor(float2 uv,float3 sourceCol,float3 viewDir,float3 normal,float fresnelPower,uint reflectType,bool anisotropic=false)
{
    half3 reflectCol=0;
    float fresnel=GetReflectionFresnel(viewDir,normal,fresnelPower);
    [branch]switch (reflectType)
    {
        default:break;
    case 0u://Planar
        {
            half3 planarCol=SamplePlanarTexture(uv,anisotropic,normal,viewDir);
            reflectCol=lerp(sourceCol,planarCol,fresnel);
        }
        break;
    case 1u://SSR
        {
            half3 ssrCol=SampleSSRTexture(uv,anisotropic,normal,viewDir);
            reflectCol=lerp(sourceCol,sourceCol+ssrCol,fresnel);
        }
        break;
    case 2u://SSPR
        {
            half4 ssprCol=SampleSSPRTexture(uv,anisotropic,normal,viewDir);
            reflectCol=lerp(sourceCol,sourceCol.rgb+ssprCol.rgb,ssprCol.a*fresnel);
        }
        break;
    }
    return reflectCol;
}
#endif