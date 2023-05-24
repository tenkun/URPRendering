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
                float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_SSRTexture);SAMPLER(sampler_SSRTexture);
            TEXTURE2D(_SSPRTex);SAMPLER(sampler_SSPRTex);
            INSTANCING_BUFFER_START
                INSTANCING_PROP(float4,_Color)
                INSTANCING_PROP(float4,_MainTex_ST)
            INSTANCING_BUFFER_END
            
            v2f vert (a2v v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv = TRANSFORM_TEX_INSTANCE(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
				UNITY_SETUP_INSTANCE_ID(i);
                float4 screenPos=TransformHClipToScreen(i.positionCS);
                float depth=SampleSceneDepth(screenPos.xy);
                float3 positionWS=TransformNDCToWorld(screenPos,depth);
               // float3 finalCol=SAMPLE_TEXTURE2D(_SSRTexture,sampler_SSRTexture,screenPos.xy).rgb;
                float4 reflectCol=SAMPLE_TEXTURE2D(_SSPRTex,sampler_SSPRTex,screenPos.xy).rgba;
                float3 finalCol=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,screenPos.xy).rgb;
                finalCol=lerp(finalCol,reflectCol.rgb,reflectCol.a);
                return float4(finalCol,1);
            }
            ENDHLSL
        }
    }
}