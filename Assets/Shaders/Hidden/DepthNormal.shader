Shader "Hidden/DepthNormal"
{
    Properties
    {
        _MainTex("Main Tex",2D)="white"{}
    }
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Assets/Shaders/Functions/Instance.hlsl"
            #include "Assets/Shaders/Functions/ValueMapping.hlsl"
            #include "Assets/Shaders/Functions/DepthPreCompute.hlsl"

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
            INSTANCING_BUFFER_START
                INSTANCING_PROP(float4,_CameraDepthTexture_TexelSize)
                INSTANCING_PROP(float4,_MainTex_ST)
            INSTANCING_BUFFER_END
            
            v2f vert (a2v v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 posWS=TransformNDCToWorld(i.uv,SampleSceneDepth(i.uv));

                float2 uvRight=i.uv+_CameraDepthTexture_TexelSize.xy*uint2(1,0);
                float3 right=TransformNDCToWorld(uvRight,SampleSceneDepth(uvRight));

                float2 uvUp=i.uv+_CameraDepthTexture_TexelSize.xy*uint2(0,1);
                float3 up=TransformNDCToWorld(uvUp,SampleSceneDepth(uvUp));

                float3 normal=normalize(cross(up-posWS,right-posWS));
                normal=normal*.5h+.5;
                return float4(normal,1);
            }
            ENDHLSL
        }
    }
}