Shader "Game/Effect/LightVolume"
{
    Properties
    {
        _MainTex("Main Tex",2D)="white"{}
        _Color("Color Tint",Color)=(1,1,1,1)
        _LightPos("Light position",Vector)=(0,0,0,0)
    }
    SubShader
    {
        Tags { "Queue"="Transparent"}
		Blend One One
        ZWrite Off
        Cull Back
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct a2v
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float4 positionHCS : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            float InScatter(float3 orginPos,float3 dir,float3 lightPos,float depth)
            {
                float3 q=orginPos-lightPos;
                float b=dot(dir,q);
                float c=dot(q,q);
                float iv=1.0f/sqrt(c-b*b);
                float l=iv*(atan((depth+b)*iv)-atan(b*iv));
                return l;
            }

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            INSTANCING_BUFFER_START
                INSTANCING_PROP(float4,_Color)
                INSTANCING_PROP(float4,_LightPos)
            INSTANCING_BUFFER_END
            
            v2f vert (a2v v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.positionHCS = o.positionCS;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 screenPos=TransformClipToScreen(i.positionHCS);
                float rawDepth=SampleSceneDepth(screenPos.xy);
                float3 positionWS=TransformNDCToWorld(screenPos.xy,rawDepth);
                float depth=RawToEyeDepth(rawDepth);

                float4 shadowPos=TransformWorldToShadowCoord(positionWS);
                float intensity=MainLightRealtimeShadow(shadowPos);
                float3 finalCol;
                return float4(finalCol,1);
            }
            ENDHLSL
        }
    }
}