#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
float4 _MainTex_TexelSize;
float _BlurOffset;

struct a2v_fog
{
    half3 positionOS : POSITION;
    float2 uv : TEXCOORD0;
};

struct v2f_DownSample
{
    float4 positionCS:SV_POSITION;
    float2 uv:TEXCOORD1;
    float4 uv01:TEXCOORD2;
    float4 uv23:TEXCOORD03;
};

struct v2f_UpSample
{
    float4 positionCS:SV_POSITION;
    float4 uv01:TEXCOORD1;
    float4 uv23:TEXCOORD2;
    float4 uv45:TEXCOORD3;
    float4 uv67:TEXCOORD4;
};

v2f_DownSample vert_DownSample(a2v_fog v)
{
    v2f_DownSample o;
    o.positionCS=TransformObjectToHClip(v.positionOS);
    o.uv=v.uv;
    #if UNITY_UV_STARTS_AT_TOP
    o.uv.y=1-o.uv.y;
    #endif

    float2 offset=float2(1+_BlurOffset,1-_BlurOffset);

    o.uv01.xy=o.uv-_MainTex_TexelSize.xy*offset;
    o.uv01.zw=o.uv+_MainTex_TexelSize.xy*offset;
    o.uv23.xy=o.uv+float2(-_MainTex_TexelSize.x,_MainTex_TexelSize.y)*offset;
    o.uv23.zw=o.uv+float2(_MainTex_TexelSize.x,-_MainTex_TexelSize.y)*offset;

    return o;
}

float4 frag_DownSample(v2f_DownSample i):SV_Target
{
    float4 sum=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv)*4;
    sum+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv01.xy);
    sum+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv01.zw);
    sum+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv23.xy);
    sum+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv23.zw);

    return sum*0.125;
}

v2f_UpSample vert_UpSample(a2v_fog v)
{
    v2f_UpSample o;
    o.positionCS=TransformObjectToHClip(v.positionOS);
    float2 uv=v.uv;
    #if UNITY_UV_STARTS_AT_TOP
    uv.y=1-uv.y;
    #endif

    _MainTex_TexelSize*=0.5;
    float2 offset=float2(1+_BlurOffset,1-_BlurOffset);

    o.uv01.xy=uv+float2(-_MainTex_TexelSize.x*2,0)*offset;
    o.uv01.zw=uv+float2(-_MainTex_TexelSize.x,_MainTex_TexelSize.y)*offset;
    o.uv23.xy=uv+float2(0,_MainTex_TexelSize.y*2)*offset;
    o.uv23.zw=uv+_MainTex_TexelSize.xy*offset;
    o.uv45.xy=uv+float2(_MainTex_TexelSize.x*2,0)*offset;
    o.uv45.zw=uv+float2(_MainTex_TexelSize.x,-_MainTex_TexelSize.y)*offset;
    o.uv67.xy=uv+float2(0,-_MainTex_TexelSize.y*2)*offset;
    o.uv67.zw=uv-_MainTex_TexelSize.xy*offset;

    return o;
}

float4 frag_UpSample(v2f_UpSample i):SV_Target
{
    float4 sum=0;
    sum+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv01.xy);
    sum+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv01.zw)*2;
    sum+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv23.xy);
    sum+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv23.zw)*2;
    sum+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv45.xy);
    sum+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv45.zw)*2;
    sum+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv67.xy);
    sum+=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv67.zw)*2;

    return sum*0.0833;
}
