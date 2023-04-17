Shader "Game/PostProcess/ColorAdjustment"
{
    Properties
    {
        _MainTex("Main Tex",2D)="white"{}
        _Color("Color Tint",Color)=(1,1,1,1)
        _Saturate("Saturate",Range(0,2))=1
        _Brightness("Brightness",Range(0,2))=1
        _Contrast("Contrast",Range(-2,3))=1
    }
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/Shaders/Functions/Instance.hlsl"

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
                INSTANCING_PROP(float4,_Color)
                INSTANCING_PROP(float4,_MainTex_ST)
                INSTANCING_PROP(float,_Brightness)
            INSTANCING_PROP(float,_Contrast)
            INSTANCING_PROP(float,_Saturate)
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
                float3 finalCol=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv).rgb * INSTANCE(_Color).rgb;
                finalCol*=INSTANCE(_Brightness);
                float luminance=0.2125*finalCol.r+0.7154*finalCol.g+0.0721*finalCol.b;
                finalCol=lerp(float3(luminance,luminance,luminance),finalCol,INSTANCE(_Saturate));
                finalCol=lerp(float3(0.5,0.5,0.5),finalCol,INSTANCE(_Contrast));
                return float4(finalCol,1);
            }
            ENDHLSL
        }
    }
}