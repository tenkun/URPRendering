Shader"URPwater"{
    Properties{
        _MainTex("MainTex",2D) = "white"{}
        
        //<深度着色
        _DepthGradient1 ("DepthGradient1", Color) = (0.1098039,0.5960785,0.6196079,1)
        _DepthGradient2 ("DepthGradient2", Color) = (0.05882353,0.1960784,0.4627451,1)
        _DepthGradient3 ("DepthGradient3", Color) = (0,0.0625,0.25,1)
        _GradientPosition("position1,position2,position3,sceneDepth from shallow to deep",Vector) = (0.2,0.3,0.6,2)
        [Toggle] _ENABLE_GEOMETRY_WAVE("is ocean?",Float) = 1
        _WaveSpeed("WaveSpeed",Range(0,1)) = 0.01
        _WaveA("Wave A(dir,steepness,wavelength)",Vector) = (1,0,0,10)
        _WaveB("Wave B",Vector)  = (0,1,0.25,20)
        _WaveC("Wave C",vector) = (1,1,0.15,10)
        _Scale("Vertex number Scale",Range(0,10)) = 10
        _BumpTex("BumpTexture",2D) = "black"{}
        _Tiling("Bump Tiling",Range(0,10)) = 0.1
        _TilingB("Detail Bump Tiling",Range(0,10)) = 0.5
        _BumpHeightA("BumpHeight",Range(0,1)) = 0.4
        _BumpHeightB("Detail Bump Height",Range(0,1)) = 0.4
        [Toggle] _IS_USE_RAMP_TEX("is use ramp texture", Float) = 0
        _rampTex("rampTex",2D) = "white"{}
        //高光反射
        _SpeStrength("Specular Strength",Range(0,5)) = 1 
        _Glossiness ("Glossiness",Range(100,2000)) = 500
        //<折射
        _RefractionIntensity ("Refraction Intensity", Float ) = 60
        _RefractionGradientRange("RefractionGradientRange", Float) = 500
        //折射>
        
        //水体Shape
        _FlowMap("FlowMap",2D) = "black"{}
        _FlowMapSpeed("small Waves Speed",Range(0,10)) = 1
        _FlowStrength("FlowStrength",Range(0,1)) = 0.1
        _UJump ("U jump per phase", Range(-0.25, 0.25)) = 0.25
        _VJump ("V jump per phase", Range(-0.25, 0.25)) = 0.25
        _phaseOffset("Time phaseOffset",Range(0,1)) = 0.3

    }

    SubShader{
        Tags{
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
        }
        Pass{
            Name"Universal water rendering"
            Tags{"LightMode" = "UniversalForward"}
            Blend Off
            ZWrite On 
            HLSLPROGRAM
            #pragma vertex VERT
            #pragma fragment FRAG
            #pragma target 3.0
            #pragma shader_feature _ENABLE_GEOMETRY_WAVE_ON
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            #define UNITY_PROJ_COORD(a) a.xyzw/a.w
            #define UNITY_SAMPLE_DEPTH(a) a.r
            sampler2D _CameraOpaqueTexture;
            sampler2D _CameraDepthTexture;
            float4 _CameraDepthTexture_TexelSize;
            #include "WaterPreCompute.hlsl"
            CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_ST;
            
            uniform float4 _DepthGradient1;
            uniform float4 _DepthGradient2;
            uniform float4 _DepthGradient3;
            float _RefractionIntensity;
            float _RefractionGradientRange;
            
            
            float _SpeStrength;
            float _Glossiness;
            float _FlowMapSpeed;
            float _FlowStrength;
            float _phaseOffset;
            half _Tiling, _TilingB;
            float _UJump;
            float _VJump;
            float _BumpHeightA;
            float _BumpHeightB;
            float4 _WaveA,_WaveB,_WaveC;
            float _WaveSpeed;
            float _Scale;
            float4 _GradientPosition;
            float DepthDiffRefraction;

            
            CBUFFER_END
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_FlowMap);
            SAMPLER(sampler_FlowMap);
            TEXTURE2D(_BumpTex);
            SAMPLER(sampler_BumpTex);
            TEXTURE2D(_rampTex);
            SAMPLER(sampler_rampTex);
            

            struct VertexInput{
                float4 positionOS:POSITION;
                half3 normalOS:NORMAL;
                float2 uv:TEXCOORD;
                float4 tangentOS:TANGENT;
                
                
            };

            struct VertexOutput{
                float4 positionCS:SV_POSITION;
                float2 uv:TEXCOORD;
                half3 normalWS:TEXCOORD1;
                half3 positionWS:TEXCOORD2;
                float4 projPos:TEXCOORD3;

                
            };

            
            
            VertexOutput VERT(VertexInput v)
            {
                VertexOutput o;
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                
                #ifdef _ENABLE_GEOMETRY_WAVE_ON


                    float3 gridPoint = v.positionOS;

                    float3 tangent = float3(1,0,0);
                    float3 binormal = float3(0,0,1);
                    float3 position = gridPoint;
                    position += GerstnerWave(_WaveA,gridPoint,tangent,binormal,_WaveSpeed,_Scale); 
                    position += GerstnerWave(_WaveB,gridPoint,tangent,binormal,_WaveSpeed,_Scale);
                    position += GerstnerWave(_WaveC,gridPoint,tangent,binormal,_WaveSpeed,_Scale);
                    float3 normal = normalize(cross(binormal,tangent));
                    o.normalWS = TransformObjectToWorldNormal(normal);
                    v.positionOS.xyz = position;
                #endif
                
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.projPos = ComputeScreenPos(o.positionCS);
                o.projPos.z = -mul(UNITY_MATRIX_MV,v.positionOS).z;
                o.positionWS = TransformObjectToWorld(v.positionOS);
                
                o.uv = v.uv;
                
                return o;
            }
            
            
            float4 FRAG(VertexOutput i): SV_TARGET
            {

                
                //basic compute
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz- i.positionWS.xyz);
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                float3 mainLightDir = normalize(mainLight.direction);
                float3 halfDir = normalize(viewDirection + mainLightDir);

                //waterShape> FlowMap
                float4 flowDir = (SAMPLE_TEXTURE2D(_FlowMap,sampler_FlowMap,i.uv)*2.0-1.0)*_FlowStrength;
                float noise = flowDir.a*3;
                float phase0 = frac(_Time.y*0.1*_FlowMapSpeed+_phaseOffset+noise);
                float phase1 = frac(_Time.y*0.1*_FlowMapSpeed + 0.5+_phaseOffset+noise);

                float2 tiling_uv = i.uv*_MainTex_ST.xy+_MainTex_ST.zw;
                float2 flowUV = tiling_uv - flowDir.xy*phase0 + _UJump + _VJump;
                float2 flowUV1 = tiling_uv - flowDir.xy*phase1;
                half3 tex0 = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,flowUV);
                half3 tex1 = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,flowUV1);
                float flowLerp = abs((0.5-phase0)/0.5);
                half3 flowColor = lerp(tex0,tex1,flowLerp);

                //useBumpMap  TODO  交互性涟漪
                float3 BumpA = UnpackDerivativeHeight(SAMPLE_TEXTURE2D(_BumpTex,sampler_BumpTex,flowUV*_Tiling))*_BumpHeightA;
                float3 BumpB = UnpackDerivativeHeight(SAMPLE_TEXTURE2D(_BumpTex,sampler_BumpTex,flowUV1*_TilingB))*_BumpHeightB;
                float3 Bump = lerp(BumpA,BumpB,flowLerp);  
                float3 normalWS = normalize(i.normalWS +float3(Bump.x,0,Bump.y));
                //<waterShape
                //shading>
                
                float NdotV=max(saturate(dot(normalWS,viewDirection)),0.000001);//  
                float NdotL=max(saturate(dot(normalWS,mainLightDir)),0.000001);
                float HdotV=max(saturate(dot(halfDir,viewDirection)),0.000001);
                float NdotH=max(saturate(dot(halfDir,normalWS)),0.000001);
                float LdotH=max(saturate(dot(halfDir,mainLightDir)),0.000001);

                //<Debug 深度差
                
                #if UNITY_UV_STARTS_AT_TOP
                    float grabSign = -_ProjectionParams.x;
                #else
                    float grabSign = _ProjectionParams.x;
                #endif          

                float3 upWardVector = float4(0,1,0,1);
                float sceneZ = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture,UNITY_PROJ_COORD(i.projPos))),_ZBufferParams);
                float WaterZ = i.projPos.z;
                float3 Debug = pow(abs(dot(upWardVector,viewDirection)),2);
                float DepthDiff = pow((sceneZ - WaterZ),2);
               // DepthDiff /= _GradientPosition.a;//TODO 三阶颜色
               // DepthDiff = clamp(0,1,DepthDiff);
                float alpha = (0,1,DepthDiff);
                
                //refraction折射
                



                float4 screenPos = UNITY_PROJ_COORD(i.projPos);//除以w分量
                
                float3 refractionColor = ColorBelowWater
                (screenPos, WaterZ,Bump,grabSign,_RefractionIntensity,_GradientPosition,DepthDiff,DepthDiffRefraction);


                /*   float2 refractionUVOffset = Bump*0.01*_RefractionIntensity;
                float4 tex = tex2D(_CameraOpaqueTexture, screenPos);
                refractionUVOffset *= saturate((DepthDiff)/abs(_RefractionGradientRange)+0.001);
                float2 sceneRefractionUVs = float2(1,grabSign)*(screenPos)+float4(refractionUVOffset, refractionUVOffset).rg;
                sceneRefractionUVs = AlignWithGrabTexel(sceneRefractionUVs);
                float sceneZRefraction = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, sceneRefractionUVs)), _ZBufferParams);
                float DepthDiffRefraction = sceneZRefraction - WaterZ;
                
                if (DepthDiffRefraction < 0){
                    sceneRefractionUVs =  AlignWithGrabTexel(float2(1,grabSign)*screenPos);
                }
                
                sceneZRefraction = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, sceneRefractionUVs)), _ZBufferParams);
                DepthDiffRefraction = sceneZRefraction - WaterZ;
                DepthDiffRefraction /= _GradientPosition.a;//控制场景深度差值
                DepthDiffRefraction = clamp(0,1,DepthDiffRefraction);
                //DepthDiffRefraction *= 1/clamp(100,300,(WaterZ*0.01));//根据水平面深度差修正深度差
                //DepthDiffRefraction /= _SceanDepth;//TODO 三阶颜色
                //float4 refractionColor = tex2D(_CameraOpaqueTexture, sceneRefractionUVs) ;
                */
                //<折射
                float gradient1 = saturate(DepthDiffRefraction/_GradientPosition.x);
                float gradient2 = saturate(DepthDiffRefraction/(_GradientPosition.x +_GradientPosition.y));
                
                if (DepthDiffRefraction < 0)
                {
                    gradient1 = saturate((DepthDiff) / _GradientPosition.x);
                    gradient2 = saturate((DepthDiff) / (_GradientPosition.x +_GradientPosition.y));
                }


                float3 DepthColor = lerp(refractionColor.rgb,_DepthGradient2,DepthDiffRefraction);
                
                
                half3 spec = pow(saturate(dot(halfDir,normalWS)), _Glossiness)*mainLight.color*_SpeStrength;
                half3 ambient = _GlossyEnvironmentColor;
                // half3 diffuse = _DepthGradient1*flowColor;
                // half3 rimcolor = 
                half3 diffuse = dot(mainLightDir,normalWS)*_DepthGradient1*flowColor*mainLight.shadowAttenuation;
                diffuse = lerp(_DepthGradient2,_DepthGradient1,diffuse);

                half3 finalColor = DepthColor+spec;
                //<shading
                // return refractionColor;
                return float4(finalColor.rgb,1);
            }



            ENDHLSL

        }
        

        UsePass "Universal Render Pipeline/Lit/ShadowCaster" 
    }
}