#ifndef PBR_Func_INCLUDE
#define PBR_Func_INCLUDE

float NDF(float NdotH,float roughness)
{
    float squareA=roughness*roughness;
    float squareNdotH=NdotH*NdotH;
    float denom=PI*pow(squareNdotH*(squareA-1)+1,2);
    return squareA/denom;
}

float GeometrySchlickGGX(float dot,float k)
{
    float denom=lerp(dot,1,k);
    return  dot/denom;
}

float  G_Function(float NdotL,float NdotV,float roughness)
{
    float k=pow(1+roughness,2)/8;
    float Gnl=GeometrySchlickGGX(NdotL,k);
    float Gnv=GeometrySchlickGGX(NdotV,k);
    return Gnl*Gnv;
}

float3 Fresnel_Term(float HdotV,float3 f0)
{
    float f=exp2((-5.55473*HdotV-6.98316)*HdotV);
    return lerp(f,1,f0);
}

float3 BRDFSection(float NdotH,float NdotL,float NdotV,float HdotV,float roughness,float3 f0)
{
    float D=NDF(NdotH,roughness);
    float G=G_Function(NdotL,NdotV,roughness);
    float3 F=Fresnel_Term(HdotV,f0);
    float denom=4*NdotL*NdotV;
    float3 specSection=D*G*F/denom;
    return specSection;
}

float3 BRDFSpecular(float NdotH,float NdotL,float NdotV,float HdotV,float roughness,float3 f0,float4 color)
{
    float3 specSection=BRDFSection(NdotH,NdotL,NdotV,HdotV,roughness,f0);
    float3 specCol=specSection*color.rgb*NdotL*PI;
    return  specCol;
}

float3 BRDFDiffuse(float NdotL,float LdotH,float metallic,float3 f0,float3 albedo,float4 color)
{
    float3 ks=Fresnel_Term(LdotH,f0);
    float3 kd=(1-ks)*(1-metallic);
    float3 diffCol=kd*albedo*color.rgb*NdotL;
    return  diffCol;
}

real3 IndirFresnel_Term(float HdotV,float3 f0,float roughness)
{
    float f=exp2((-5.55473*HdotV-6.98316)*HdotV);
    return f0+f*saturate(1-roughness-f0);
}

real3 SH_IndirectionDiff(float3 normalWS)
{
    real4 SHCoefficients[7];
    SHCoefficients[0]=unity_SHAr;
    SHCoefficients[1]=unity_SHAg;
    SHCoefficients[2]=unity_SHAb;
    SHCoefficients[3]=unity_SHBr;
    SHCoefficients[4]=unity_SHBg;
    SHCoefficients[5]=unity_SHBb;
    SHCoefficients[6]=unity_SHC;
    float3 col=SampleSH9(SHCoefficients,normalWS);
    return  max(0,col);
}

float3 IndirectionDiffuse(float HdotV,float3 f0,float roughness,float metallic,float3 albedo,float3 normalWS,float ao)
{
    float3 shCol=SH_IndirectionDiff(normalWS)*ao;
    float3 ks=IndirFresnel_Term(HdotV,f0,roughness);
    float3 kd=(1-ks)*(1-metallic);
    float3 diffCol=shCol*albedo*kd;
    return  diffCol;
}

real3 IndirSpecCube(float3 normalWS,float3 viewWS,float roughness,float ao)
{
    float3 reflectWS=reflect(-viewWS,normalWS);
    roughness=roughness*(1.7-0.7*roughness);
    float MidLevel=roughness*6;
    float4 specCol=SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,samplerunity_SpecCube0,reflectWS,MidLevel);
    #if !defined(UNITY_USE_NATIVE_HDR)
    return  DecodeHDREnvironment(specCol,unity_SpecCube0_HDR)*ao;
    #else
    return specCol.xyz*ao;
    #endif
}

real3 IndirSpecFactor(float NdotV,float roughness,float smoothness,float3 brdfSpec,float3 f0)
{
   
    #ifdef UNITY_COLORSPACE_GAMMA
    float surReduction=1-0.28*roughness;
    #else
    float surReduction=1/(roughness*roughness+1);
    #endif
    #if defined(SHADER_API_GLES)
    float reflectivity=brdfSpec.x;
    #else
    float reflectivity=max(max(brdfSpec.x,brdfSpec.y),brdfSpec.z);
    #endif
    half grazingTSection=saturate(reflectivity+smoothness);
    float fre=Pow4(1-NdotV);
    //float Fre=exp2((-5.55473*NdotV-6.98316)*NdotV);
    return lerp(f0,grazingTSection,fre)*surReduction;
    
}

real3 IndirectionSpec(float NdotH,float NdotL,float LdotH,float NdotV,float3 normalWS,float3 viewWS,float roughness,float smoothness,float3 f0,float ao)
{
    real3 cube=IndirSpecCube(normalWS,viewWS,roughness,ao);
    float3 brdfSpec=BRDFSection(NdotH,NdotL,NdotV,LdotH,roughness,f0);
    real3 factor=IndirSpecFactor(NdotV,roughness,smoothness,brdfSpec,f0);
    real3 specCol=cube*factor;
    return specCol;
}

#endif