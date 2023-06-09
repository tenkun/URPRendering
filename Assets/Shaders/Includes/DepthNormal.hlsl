#ifndef DepthNormal
#define DepthNormal
TEXTURE2D(_CameraNormalTexture);SAMPLER(sampler_CameraNormalTexture);
float4 _CameraNormalTexture_TexelSize;

inline float3 DecodeViewNormalStereo(float4 enc4 )
{
    float kScale = 1.7777;
    float3 nn = enc4.xyz*float3(2*kScale,2*kScale,0) + float3(-kScale,-kScale,1);
    float g = 2.0 / dot(nn.xyz,nn.xyz);
    float3 n;
    n.xy = g*nn.xy;
    n.z = g-1;
    return n;
}

inline float DecodeFloatRG(float2 enc)
{
    float2 kDecodeDot=float2(1.0,1/255.0);
    return dot(enc,kDecodeDot);
}

inline void DecodeDepthNormal(float4 enc,out float depth,out float3 normal)
{
    depth=DecodeFloatRG(enc.zw);
    normal=DecodeViewNormalStereo(enc);
}


half3 SampleNormalWS(float2 uv)
{
    half3 normalEncoded=SAMPLE_TEXTURE2D(_CameraNormalTexture,sampler_CameraNormalTexture,uv).rgb;
    return normalEncoded*2.h-1.h;
}

half3 BlendNormal(half3 _normal1,half3 _normal2,uint _blendMode)
{
    half3 blendNormal=half3(0.h,0.h,1.h);
    [branch]switch (_blendMode)
    {
        default:blendNormal=0.h;break;
    case  0u://Linear
        {
            blendNormal=_normal1+_normal2;
        }
        break;
    case 1u://Overlay
        {
            blendNormal=Blend_Overlay(_normal1*.5h+.5h,_normal2*.5h+.5h);
            blendNormal=blendNormal*2-1;
        }
        break;
    case  2u://Partial Derivative
        {
            half2 pd=_normal1.xy*_normal2.z+_normal2.xy*_normal1.z;
            blendNormal=half3(pd,_normal1.z*_normal2.z);
        }
        break;
    case 3u://Unreal Developer Network
        {
            blendNormal=half3(_normal1.xy+_normal2.xy,_normal1.z);
        }
        break;
    case  4u://Reoriented
        {
            half3 t=_normal1*half3(1.h,1.h,1.h)+half3(0.h,0.h,1.h);
            half3 u=_normal2*half3(-1.h,-1.h,1.h);
            blendNormal=t*dot(t,u)-u*t.z;
        }
        break;;
    }
    return  normalize(blendNormal);
}

#endif