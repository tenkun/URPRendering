Shader "Hidden/PostPress/Fog"
{
    Properties
    {
        _MainTex("Main Tex",2D)="white"{}
        _Color("Color Tint",Color)=(1,1,1,1)
        [NoScaleOffset]_NoiseTex("Noise Tex",2D)="white"{}
        _NoiseAmount("Noise Amount",Range(0,2))=1
        _FogHeightDensity("Fog Density(Height)",Range(0,1))=0
        _FogDepthDensity("Fog Density(Depth)",Range(0,1))=0
        [MinMaxRange]_FogHeightRange("Range ",Range(0,10))=0
    	[HideInInspector]_FogHeightRangeEnd("",float)=1
        _FogSpeed("Fog Speed",Vector)=(0,0,0,0)
        [MinMaxRange]_FogDepthRange("Range ",Range(0,200))=0
        [HideInInspector]_FogDepthRangeEnd("",float)=100
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
            #include "Assets/Shaders/Includes/Instance.hlsl"
            #include "Assets/Shaders/Includes/ValueMapping.hlsl"
            #include "Assets/Shaders/Includes/DepthPreCompute.hlsl"

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
            TEXTURE2D(_NoiseTex);SAMPLER(sampler_NoiseTex);
            INSTANCING_BUFFER_START
                INSTANCING_PROP(float4,_Color)
            INSTANCING_PROP(float,_NoiseAmount)
            INSTANCING_PROP(float,_FogHeightDensity)
            INSTANCING_PROP(float,_FogDepthDensity)
            INSTANCING_PROP(float,_FogHeightRange)
            INSTANCING_PROP(float,_FogHeightRangeEnd)
            INSTANCING_PROP(float,_FogDepthRange)
            INSTANCING_PROP(float,_FogDepthRangeEnd)
            INSTANCING_PROP(float4,_FogSpeed)
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
				UNITY_SETUP_INSTANCE_ID(i);
                float3 finalCol=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv).rgb;

                float rawDepth=SampleSceneDepth(i.uv);
                float depth=RawToEyeDepth(rawDepth);
                float3 worldPos=TransformNDCToWorld(i.uv,rawDepth);

                float2 speed=_Time.y*_FogSpeed.xy;
                float noise=(SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,i.uv+speed).r-0.5)*_NoiseAmount;

                float fogDensity=(_FogHeightRangeEnd-worldPos.y)/(_FogHeightRangeEnd-_FogHeightRange);
                fogDensity=saturate(fogDensity*_FogHeightDensity*(1+noise));

                float depthDensity=(depth-_FogDepthRange)/(_FogDepthRangeEnd-_FogDepthRange);
                depthDensity=saturate(depthDensity*(_FogDepthDensity)*(1+noise));

                fogDensity+=depthDensity;
                fogDensity=saturate(fogDensity);
                finalCol=lerp(finalCol.rgb,_Color.rgb,fogDensity);
                return float4(finalCol,1);
            }
            ENDHLSL
        }
    }
}
