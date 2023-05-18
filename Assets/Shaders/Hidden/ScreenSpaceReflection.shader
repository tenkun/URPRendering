Shader "Hidden/SSR"
{
    Properties
    {
        _MainTex("Main Tex",2D)="white"{}
        _MaxDistance("Max RayMarching Distance",Range(0,1000))=500
        _MaxStep("Max RayMarching Step",Int)=64
        _MaxSearchCount("Max RayMarching BinarySearch Count",Int)=8
        _StepSize("RayMarching Step Size",Range(1,10))=8
        _DepthThickness("Depth Thickness",Range(0,2))=0.01
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
            #include "Assets/Shaders/Functions/DepthNormal.hlsl"

            #define SSRDitherMatrix_m0 float4(0,0.5,0.125,0.625)
            #define SSRDitherMatrix_m1 float4(0.75,0.25,0.875,0.375)
            #define SSRDitherMatrix_m2 float4(0.187,0.687,0.0625,0.562)
            #define SSRDitherMatrix_m3 float4(0.937,0.437,0.812,0.312)
            
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
                float4 positionHCS:TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_CameraDepthNormalsTexture);SAMPLER(sampler_CameraDepthNormalsTexture);
            INSTANCING_BUFFER_START
                INSTANCING_PROP(float4,_Color)
                INSTANCING_PROP(float4,_MainTex_ST)
            INSTANCING_PROP(float,_MaxDistance)
            INSTANCING_PROP(int,_MaxStep)
            INSTANCING_PROP(int,_MaxBinarySearchCount)
            INSTANCING_PROP(int,_StepSize)
            INSTANCING_PROP(float,_DepthThickness)
            INSTANCING_BUFFER_END
            
            v2f vert (a2v v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.positionHCS=o.positionCS;
                o.uv = TRANSFORM_TEX_INSTANCE(v.uv, _MainTex);
                return o;
            }
    
            bool checkDepthCollision(float3 curPosWS,inout float2 hitPos,inout float depthDistant)
            {
                float4 screenPos=TransformClipToScreen(mul(_Matrix_VP,float4(curPosWS,1)));
                hitPos=screenPos.xy;
                float depth=screenPos.w;
                float compareDepth=SampleSceneDepth(screenPos.xy);
                compareDepth=RawToEyeDepth(compareDepth);
                depthDistant=abs(depth-compareDepth);
                if(depth>compareDepth&&screenPos.x>0&&screenPos.y>0&&screenPos.x<1&&screenPos.y<1)
                {
                    return true;
                }
                return false;
            }
    
            bool worldSpaceRaymarching(float3 orgin,float3 marchDir,float curStep,float dither,inout float2 hitPos)
            {
                float3 curPos=orgin;
                float depthDistant=0;
                [unroll(256)]
                for(int i=0;i<_MaxStep;i++)
                {
                    curPos+=marchDir*curStep+marchDir*dither;
                    if(length(curPos-orgin)>_MaxDistance)
                        return false;
                    
                    if(checkDepthCollision(curPos,hitPos,depthDistant))
                    {
                        if(depthDistant<_DepthThickness)
                            return true;
                        else
                        {
                            curPos-=marchDir*curStep;
                            curStep*=0.5;
                        }
                    }
                }
                return false;
            }
            
            float4 frag (v2f i) : SV_Target
            {
                float3 normalWS=SampleNormalWS(i.uv);
                float rawDepth=SampleSceneDepth(i.uv);
                float eyeDepth=RawToEyeDepth(rawDepth);
                float3 frustumCornersRay=TransformNDCToFrustumCornersRay(i.uv);
                float3 marchPositionWS=GetCameraPositionWS()+frustumCornersRay*eyeDepth;
                float3 marchDirWS=normalize(reflect(normalize(frustumCornersRay),normalWS));

                float2 ditherXY=i.positionCS.xy;
                float4x4 SSRDitherMatrix=float4x4(SSRDitherMatrix_m0,SSRDitherMatrix_m1,SSRDitherMatrix_m2,SSRDitherMatrix_m3);

                float2 xy=floor(fmod(ditherXY,4));
                float dither=SSRDitherMatrix[xy.y][xy.x];
                
                float marchStep=.3;
                float3 currentMarchPos=marchPositionWS+normalWS*marchStep*.5;
    
                float2 hitPos=0;
                float3 finalCol=0;
                if(worldSpaceRaymarching(currentMarchPos,marchDirWS,_StepSize,dither,hitPos))
                {
                    finalCol=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,hitPos).rgb;
                }
                return float4(finalCol.rgb,1);
            }
            ENDHLSL
        }
        
        Pass
        {
            HLSLPROGRAM
            #include "Assets/Shaders/Functions/Blur.hlsl"
            #pragma vertex vert_DownSample
            #pragma fragment frag_DownSample
            ENDHLSL
        }
        
        Pass
        {
            HLSLPROGRAM
            #include "Assets/Shaders/Functions/Blur.hlsl"
            #pragma vertex vert_UpSample
            #pragma fragment frag_UpSample
            ENDHLSL
        }
    }
}