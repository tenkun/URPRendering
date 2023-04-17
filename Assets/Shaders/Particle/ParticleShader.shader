Shader "Unlit/ParticleShader"
{ 
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 col:COLOR;
            };

            struct particleData
            {
                float3 pos;
                float4 color;
            };
            
            StructuredBuffer<particleData>_particleDataBuffer;

            v2f vert (uint id : SV_VertexID)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(float4(_particleDataBuffer[id].pos,0));
                o.col=_particleDataBuffer[id].color;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                return i.col;
            }
            ENDHLSL
        }
    }
}
