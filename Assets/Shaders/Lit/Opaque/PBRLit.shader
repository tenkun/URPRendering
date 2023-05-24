Shader "Game/Lit/Transparency/Lit"
{
    Properties
    {
        _MainTex("Main Tex",2D)="white"{}
        _Color("Color Tint",Color)=(1,1,1,1)
        _NormalTex("Normal Tex",2D)="bump"{}
        [NoScaleOffset]_MaskMap("Mask Map",2D)="white"{}
        _Metallic("Metallic",Range(0,1))=1
        _Smoothness("Smoothness",Range(0,1))=1
        _SpecularColor("Specular Color",Color)=(1,1,1,1)
        _OcclusionAmount("Occlusion Amount",Range(0,1))=1
    }
    SubShader
    {
        Tags {"RenderType"="Transparent"}
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma  shader_feature _MaskMapOn

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Shaders/Includes/PBR_Func.hlsl"

            struct a2v
            {
                float3 positionOS : POSITION;
                float3 normalOS:NORMAL;
                float4 tangentOS:TANGENT;
                float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                half3 normalWS:NORMAL;
                float2 uv : TEXCOORD0;
                float3 viewDirWS:TEXCOORD1;
                half3 tangentWS:TEXCOORD2;
                half3 biTangentWS:TEXCOORD3;
                float3 positionWS:TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex);SAMPLER(sampler_NormalTex);
            TEXTURE2D(_MaskMap);SAMPLER(sampler_MaskMap);\
            float4 _Color;
            float4 _MainTex_ST;
            float4 _NormalTex_ST;
            float4 _SpecularColor;
            float _Smoothness;
            float _Metallic;
            float _OcclusionAmount;
            
            v2f vert (a2v v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.positionWS=TransformObjectToWorld(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normalWS=normalize(TransformObjectToWorldNormal(v.normalOS));
                o.viewDirWS=GetWorldSpaceViewDir(TransformObjectToWorld(v.positionOS));
                o.tangentWS=normalize(TransformObjectToWorldDir(v.tangentOS.xyz));
                o.biTangentWS=cross(o.normalWS,o.tangentWS)*v.tangentOS.w;
                return o;
            }
            
            float4 frag (v2f i) : SV_Target
            {
				UNITY_SETUP_INSTANCE_ID(i);
                half3 normalWS=normalize(i.normalWS);
                half3 tangentWS=normalize(i.tangentWS);
                half3 biTangentWS=normalize(i.biTangentWS);
                half3x3 tbn=half3x3(tangentWS,biTangentWS,normalWS);
                half3 viewDirWS=normalize(i.viewDirWS);
                
               
                //Normal
                float3 normal=UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.uv));
                normal=mul(transpose(tbn),normal);
                normal.z=pow(saturate(1-pow(normal.x,2)-pow(normal.y,2)),0.5);
                

                //Light
                Light light=GetMainLight();
                half3 lightDir=normalize(light.direction);
                float3 albedo= SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv)* _Color;

                //pbr

                float4 mask=SAMPLE_TEXTURE2D(_MaskMap,sampler_MaskMap,i.uv);
                float metallic=mask.r*_Metallic;
                float ao=mask.g*_OcclusionAmount;
                float smoothness=mask.a*_Smoothness;


                half3 halfDirWS=normalize(lightDir+viewDirWS);
                float roughness=pow(1-smoothness,2);
                float3 f0=lerp(0.04,albedo,metallic);
                float NdotV=max(saturate(dot(normal,viewDirWS)),0.0000001);
                float NdotL=max(saturate(dot(normal,lightDir)),0.0000001);
                float HdotV=max(saturate(dot(halfDirWS,viewDirWS)),0.0000001);
                float NdotH=max(saturate(dot(normal,halfDirWS)),0.0000001);
                float LdotH=max(saturate(dot(lightDir,halfDirWS)),0.0000001);

                float3 diffcol=BRDFDiffuse(NdotL,LdotH,metallic,f0,albedo,float4(light.color,1));
                float3 specCol=BRDFSpecular(NdotH,NdotL,NdotV,HdotV,roughness,f0,_SpecularColor);
                float3 directCol=diffcol+specCol;
                
                float3 inDirDiff=IndirectionDiffuse(HdotV,f0,roughness,metallic,albedo,normal,ao);
                float3 inDirSpec=IndirectionSpec(NdotH,NdotL,LdotH,NdotV,normal,viewDirWS,roughness,smoothness,f0,ao);
                float3 inDirCol=inDirDiff+inDirSpec;

                float3 finalCol=directCol+inDirCol;
                return float4(finalCol,1);
            }
            ENDHLSL
        }

    }
}
