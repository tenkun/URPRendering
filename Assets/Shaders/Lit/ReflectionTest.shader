Shader "Game/Unfinished/ReflectionTest"
{
    Properties
    {
        _MainTex("Main Tex",2D)="white"{}
        _Color("Color Tint",Color)=(1,1,1,1)
    }
    SubShader
    {
        Tags { "Queue"="Transparent"}
        Blend Off
    	ZTest Less
    	ZWrite Off
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/Shaders/Includes/Instance.hlsl"
            #include "Assets/Shaders/Includes/ValueMapping.hlsl"
            #include "Assets/Shaders/Includes/DepthPreCompute.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct a2v
            {
                float3 positionOS : POSITION;
                float3 normalOS:NORMAL;
                float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS:TEXCOORD1;
                float3 viewDirWS:TEXCOORD2;
                float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_SSRTex);SAMPLER(sampler_SSRTex);
            TEXTURE2D(_SSPRTex);
            SamplerState sampler_TrilinearClampAniso8;
            SamplerState sampler_pointclamp;
            INSTANCING_BUFFER_START
                INSTANCING_PROP(float4,_Color)
                INSTANCING_PROP(float4,_MainTex_ST)
            INSTANCING_BUFFER_END

            half4 PrefilteredReflection(float3 normal,float3 viewDir,float2 uv,Texture2D<float4> sampleTex)
            {
                float ndotV=saturate(dot(normal,viewDir));
                float3 biTangent=normalize(normal/ndotV-viewDir*ndotV);
                float3 tangent=cross(biTangent,viewDir);
                float3 dRdx=tangent*(0.9*(1-ndotV)+0.1);
                float3 dRDy=biTangent*(-3*(1-ndotV)+4);
                float4 col= SAMPLE_TEXTURE2D(sampleTex,sampler_TrilinearClampAniso8,uv);
                float4 anisoCol=SAMPLE_TEXTURE2D_GRAD(sampleTex,sampler_TrilinearClampAniso8,uv,length(dRdx),length(dRDy));
                col=lerp(col,anisoCol,ndotV);
                return col;
            }
            
            v2f vert (a2v v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.normalWS=normalize(TransformObjectToWorldNormal(v.normalOS));
                float3 positionWS=TransformObjectToWorld(v.positionOS);
                o.viewDirWS=normalize(_WorldSpaceCameraPos-positionWS);
                o.uv = TRANSFORM_TEX_INSTANCE(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
				UNITY_SETUP_INSTANCE_ID(i);
                float4 screenPos=TransformHClipToScreen(i.positionCS);
                float depth=SampleSceneDepth(screenPos.xy);
                float3 positionWS=TransformNDCToWorld(screenPos.xy,depth);
                //float3 finalCol=SAMPLE_TEXTURE2D(_SSRTex,sampler_SSRTex,screenPos.xy).rgb;
                float4 reflectCol=SAMPLE_TEXTURE2D(_SSPRTex,sampler_pointclamp,screenPos.xy).rgba;
                float3 finalCol=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,screenPos.xy).rgb;
                //reflectCol=PrefilteredReflection(i.normalWS,i.viewDirWS,screenPos.xy,_SSPRTex);
                finalCol=lerp(finalCol,reflectCol.rgb,reflectCol.a);
                return float4(finalCol,1);
            }
            ENDHLSL
        }
    }
}