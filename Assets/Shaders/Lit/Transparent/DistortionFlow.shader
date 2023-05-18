Shader "Game/Lit/Transparency/Water"
{
    Properties
    {
         _MainTex("Main Tex",2D)="white"{}
        _Color("Color Tint",Color)=(1,1,1,1)
        
        [Header(Flow)]
        _FlowTex("Flow Tex",2D)="white"{}
        _FlowStrength("Flow Strength",Range(0.1,1.5))=1
        _FlowOffset ("Flow Offset", Float) = 0
        _Speed("Speed",Range(0.1,2))=1
        _UJump("U jump per phase",Range(-0.25,0.25))=0.25
        _VJump("V jump per phase",Range(-0.25,0.25))=0.25
        _Tilling("Tilling",float)=1
        _NoiseTex("Noise Tex",2D)="white"{}
        
        [Header(Normal)]
        _NormalTex("Normal Tex",2D)="bump"{}
        _DeriveHeightTex("Derive Height Tex",2D)="white"{}
        _HeightScale("Height Scale",float)=1
        _HeightScaleModulated("Height Scale Modulated",float)=1
    	
    	[Header(Wave)]
    	[Toggle(_WAVE)]_Wave("Wave",int)=1
    	[Foldout(_WAVE)]_WaveA ("Wave A (dir, steepness, wavelength)", Vector) = (1,0,0.5,10)
		[Foldout(_WAVE)]_WaveB ("Wave B", Vector) = (0,1,0.25,20)
		[Foldout(_WAVE)]_WaveC ("Wave C", Vector) = (1,1,0.15,10)
    	[Foldout(_WAVE)]_WaveSpeed ("Wave Speed", float) = 1
        
        [Header(Mask)]
        [NoScaleOffset]_MaskMap("Mask Map",2D)="white"{}
        _Metallic("Metallic",Range(0,1))=1
        _Smoothness("Smoothness",Range(0,1))=1
        _SpecularColor("Specular Color",Color)=(1,1,1,1)
        _OcclusionAmount("Occlusion Amount",Range(0,1))=1
    	
    	[Header(WaterFog)]
    	_WaterFogColor("Water Fog Color",Color)=(1,1,1,1)
    	_WaterFogDensity("Water Fog Desity",Range(0,2))=0.1
    	
    	[Header(Refract)]
    	_RefractionStrength("Refract Strength",Range(0,1))=0.25
    	
    	[Header(Reflect)]
    	[Toggle(_PROBEREFLECT)]_ProbeReflect("Use Reflection Probe",int)=0
    	[Toggle(_PLANARREFLECT)]_PlanarReflect("Use Planar Reflection",int)=0
    	_ReflectionStrength("Reflect Strength",Range(0,1))=0.25
    	
    	[Header(Foam)]
    	[Toggle(_FOAM)]_Foam("Use Foam",int)=0
    	[Foldout(_FOAM)]_FoamTex("Foam Tex",2D)="white"{}
    	[Foldout(_FOAM)]_FoamPower("FoamPower",Range(0,1))=0.5
    	
    	[Header(Caustics)]
    	[Toggle(_CAUSTICS)]_Caustics("Use Caustics",int)=0
    	[Foldout(_CAUSTICS)]_CausticsTex("Cautics Tex",2D)="white"{}
    	[Foldout(_CAUSTICS)]_CausticsStrength("Caustics Strength",Range(0,1))=0.5
    }
    SubShader
    {
    	Tags { "Queue"="Transparent-1"}
		Blend Off
    	ZTest Less
    	ZWrite Off
        Pass
        {
        	Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _WAVE
            #pragma shader_feature _PROBEREFLECT
            #pragma shader_feature _PLANARREFLECT
            #pragma shader_feature _FOAM
            #pragma shader_feature _CAUSTICS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Shaders/Functions/ValueMapping.hlsl"
            #include "Assets/Shaders/Functions/PBR_Func.hlsl"
            #include "Assets/Shaders/Functions/DepthPreCompute.hlsl"

            #define UNITY_PROJ_COORD(a) a.xyzw/a.w
            #define UNITY_SAMPLE_DEPTH(a) a.r
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
                float4 positionHCS : SV_POSITION;
                half3 normalWS:NORMAL;
                float2 uv : TEXCOORD0;
                float3 viewDirWS:TEXCOORD1;
                half3 tangentWS:TEXCOORD2;
                half3 biTangentWS:TEXCOORD3;
                float3 positionWS:TEXCOORD4;
            	float4 positionCS:TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_FlowTex);SAMPLER(sampler_FlowTex);
            TEXTURE2D(_NoiseTex);SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_NormalTex);SAMPLER(sampler_NormalTex);
            TEXTURE2D(_DeriveHeightTex);SAMPLER(sampler_DeriveHeightTex);
            TEXTURE2D(_MaskMap);SAMPLER(sampler_MaskMap);
            TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);
            TEXTURE2D(_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D(_ReflectTex);SAMPLER(sampler_ReflectTex);
            TEXTURE2D(_FoamTex);SAMPLER(sampler_FoamTex);
            TEXTURE2D(_CausticsTex);SAMPLER(sampler_CausticsTex);
            TEXTURE2D(_SSRTexture);SAMPLER(sampler_SSRTexture);
            float4 _CameraDepthTexture_TexelSize;
            float4 _ReflectTex_TexelSize;
            float4 _Color;
            float4 _MainTex_ST;
            float4 _NormalTex_ST;
            float4 _FlowTex_ST;
            float4 _DeriveHeightTex_ST;
            float _UJump;
            float _VJump;
            float4 _SpecularColor;
            float _Smoothness;
            float _Metallic;
            float _OcclusionAmount;
            float _Tilling;
            float _Speed;
            float _FlowStrength;
            float _FlowOffset;
            float _HeightScale;
            float _HeightScaleModulated;
            float4 _WaveA;
            float4 _WaveB;
            float4 _WaveC;
            float _WaveSpeed;
            float4 _WaterFogColor;
            float _WaterFogDensity;
            float _RefractionStrength;
            float _ReflectionStrength;
            float _FoamPower;

            float3 flowUV(float2 uv,float2 jump,float flowOffset,float tiling ,float2 flowVec,float time,bool flowB)
            {
                	float phaseOffset = flowB ? 0.5 : 0;
	                float progress = frac(time + phaseOffset);
	                float3 uvw;
	                uvw.xy = uv - flowVec * (progress + flowOffset);
	                uvw.xy *= tiling;
	                uvw.xy += phaseOffset;
	                uvw.xy += (time - progress) * jump;
	                uvw.z = 1 - abs(1 - 2 * progress);
	                return uvw;
            }

            float3 UnpackDerivativeHeight(float4 textureData)
            {
                float3 dh = textureData.agb;
				dh.xy = dh.xy * 2 - 1;
				return dh;
            }

            float3 GerstnerWave(float4 wave,float3 p,inout float3 tangent,inout float3 binormal)
            {
            	float steepness=wave.z;
	            float wavelength=wave.w;
            	float k=2*PI/wavelength;
            	float c=sqrt(9.8/k)*_WaveSpeed;
            	float2 d=normalize(wave.xy);
            	float f=k*(dot(d,p.xz)-c*_Time.y);
            	float a=steepness/k;
            	tangent+=float3(
            		-d.x*d.x*steepness*sin(f),
            		d.x*steepness*cos(f),
            		-d.x*d.y*steepness*sin(f));
            	binormal+=float3(
            		-d.x*d.y*steepness*sin(f),
            		d.y*steepness*cos(f),
            		-d.y*d.y*steepness*sin(f));
            	return float3(d.x*a*cos(f),a*sin(f),d.y*a*cos(f));
            }

            float2 AlignWithGrabTexel(float2 uv)
            {
	            #if UNITY_UV_STARTS_AT_TOP
            	if(_CameraDepthTexture_TexelSize.y<0)
            	{
            		uv.y=1-uv.y;
            	}
            	#endif
            	return (floor(uv*_CameraDepthTexture_TexelSize.zw)+0.5)*abs(_CameraDepthTexture_TexelSize.xy);
            	
            }

            float GetReflectionCoefficient(float3 viewDir,float3 normal,float fresnelPower){
				float a = 1 - dot(viewDir,normal);
				return pow(a,fresnelPower);
			}
            

            float3 GetFoamAtten(float3 poistionWS,float4 screenPos)
            {
            	float depth=SAMPLE_TEXTURE2D_X(_CameraDepthTexture,sampler_CameraDepthTexture,screenPos.xy).r;
            	float3 bgPositionWS=ReconstructWorldPosition(screenPos.xy,depth);
            	float dist=distance(poistionWS,bgPositionWS)+0.1;
            	return pow(max(0,1 - dist / lerp(0.1,1,_FoamPower)),3);
            }

            float3 GetCaustics(float3 depthPositionWS,float2 normal)
            {
	            float2 uv=depthPositionWS.xz*float2(0.5,1)+normal*0.1;
            	return SAMPLE_TEXTURE2D(_CausticsTex,sampler_CausticsTex,uv).rgb;
            }
            
            float3 ColorBelowWater(float4 screenPos,float3 tangentSpaceNormal)
            {
            	float2 uvOffset=tangentSpaceNormal.xz*_RefractionStrength;
            	uvOffset.y *=_CameraDepthTexture_TexelSize.z * abs(_CameraDepthTexture_TexelSize.y);
            	float2 uv=AlignWithGrabTexel(screenPos.xy+uvOffset/screenPos.w);
            	float bgDepth=SAMPLE_TEXTURE2D_X(_CameraDepthTexture,sampler_CameraDepthTexture,uv).r;
            	float depthDiff=GetDepthDiffVS(bgDepth,screenPos.w);

            	uvOffset*=saturate(depthDiff);
            	uv=AlignWithGrabTexel(screenPos.xy+uvOffset/screenPos.w);
            	bgDepth=SAMPLE_TEXTURE2D_X(_CameraDepthTexture,sampler_CameraDepthTexture,uv).r;
            	depthDiff=GetDepthDiffVS(bgDepth,screenPos.w);
            	
            	float3 grab=SAMPLE_TEXTURE2D(_CameraOpaqueTexture,sampler_CameraOpaqueTexture,screenPos.xy).rgb;
            	float fogFactor=exp2(-_WaterFogDensity*depthDiff);
            	return lerp(_WaterFogColor,grab,fogFactor);
            }
            
			v2f vert (a2v v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
            	float3 positionWS=TransformObjectToWorld(v.positionOS);
                float3 normalWS=normalize(TransformObjectToWorldNormal(v.normalOS));
				float3 tangentWS=normalize(TransformObjectToWorldDir(v.tangentOS.xyz));;
                float3 biTangentWS=cross(normalWS,tangentWS)*v.tangentOS.w;
            	#if defined(_WAVE)
				float3 p = positionWS;
				p += GerstnerWave(_WaveA, p, tangentWS, biTangentWS);
				p += GerstnerWave(_WaveB, p, tangentWS, biTangentWS);
				p += GerstnerWave(_WaveC, p, tangentWS, biTangentWS);
            	positionWS=p;
            	normalWS= normalize(cross(biTangentWS, tangentWS));
            	#endif
            	o.positionWS=positionWS;
                o.positionCS = TransformWorldToHClip(positionWS);
            	o.positionHCS=o.positionCS;
                o.normalWS=normalWS;
				o.tangentWS=tangentWS;
				o.biTangentWS=biTangentWS;
				o.viewDirWS=normalize(_WorldSpaceCameraPos-positionWS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
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
                float4 screenPos =TransformClipToScreen(i.positionCS);

            	//depth
            	real rawDepth=SAMPLE_TEXTURE2D_X(_CameraDepthTexture,sampler_CameraDepthTexture,screenPos.xy).r;
            	#if !UNITY_REVERSED_Z
				// Adjust z to match NDC for OpenGL
                rawDepth = lerp(UNITY_NEAR_CLIP_VALUE, 1, rawDepth);
				#endif
            	

            	//Flow
            	float3 flow=SAMPLE_TEXTURE2D(_FlowTex,sampler_FlowTex,i.uv).rgb;
                flow.xy=flow.xy*2-1;
                flow*=_FlowStrength;
                //flowVec=float2(0,0);
                //float noise=SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,i.uv).r;
                float noise=SAMPLE_TEXTURE2D(_FlowTex,sampler_FlowTex,i.uv).a;
                float time = _Time.y * _Speed + noise;
                float jump=float2(_UJump,_VJump);
                
                float3 uvwA=flowUV(i.uv,jump,_FlowOffset,_Tilling,flow.xy,time,false);
                float3 uvwB=flowUV(i.uv,jump,_FlowOffset,_Tilling,flow.xy,time,true);

                //Normal
             //    float3 normalA=UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,uvwA.xy))*uvwA.z;
             //    float3 normalB=UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,uvwB.xy))*uvwB.z;
             //    normalA=mul(transpose(tbn),normalA);
             //    normalB=mul(transpose(tbn),normalB);
             //    normalA.z=pow(saturate(1-pow(normalA.x,2)-pow(normalA.y,2)),0.5);
             //    normalB.z=pow(saturate(1-pow(normalB.x,2)-pow(normalB.y,2)),0.5);
             //    //float3 normal=normalize(normalA+normalB);

                //DerivativeHeight
                float heightScale=flow.z * _HeightScaleModulated + _HeightScale;
                float3 dhA=UnpackDerivativeHeight(SAMPLE_TEXTURE2D(_DeriveHeightTex,sampler_DeriveHeightTex,uvwA.xy))*uvwA.z*heightScale;
                float3 dhB=UnpackDerivativeHeight(SAMPLE_TEXTURE2D(_DeriveHeightTex,sampler_DeriveHeightTex,uvwB.xy))*uvwB.z*heightScale;
                float3 normal= normalize(float3((dhA.xy + dhB.xy), 1));
            	normal = normalize(normalWS +float3(normal.x,0,normal.y));
                float3 texA=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uvwA.xy)*uvwA.z;
                float3 texB=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uvwB.xy)*uvwB.z;

                //Light
                Light light=GetMainLight();
                half3 lightDir=normalize(light.direction);

            	//refract
            	//float3 albedo= (texA+texB)* _Color;
            	float3 albedo=ColorBelowWater(screenPos,normal);

            	//reflect
            	float3 reflectDir=reflect(-viewDirWS,normalWS);
            	half3 envHdrCol=albedo;
            	#if _PROBEREFLECT
            	reflectDir=BoxProjectedCubemapDirection(reflectDir,i.positionWS,unity_SpecCube0_ProbePosition,unity_SpecCube0_BoxMin,unity_SpecCube0_BoxMax);
            	half4 envCol=SAMPLE_TEXTURECUBE(unity_SpecCube0,samplerunity_SpecCube0,reflectDir);
            	envHdrCol=DecodeHDREnvironment(envCol,unity_SpecCube0_HDR);
            	#endif
            	
            	#if _PLANARREFLECT
            	// float2 uvOffset=normal.xz*_ReflectionStrength;
            	// uvOffset.y *=_ReflectTex_TexelSize.z * abs(_ReflectTex_TexelSize.y);
            	// float2 uv=AlignWithGrabTexel(screenPos.xy+uvOffset/screenPos.w);
            	// envHdrCol=SAMPLE_TEXTURE2D(_ReflectTex,sampler_ReflectTex,uv).rgb;
            	envHdrCol=SAMPLE_TEXTURE2D(_SSRTexture,sampler_SSRTexture,screenPos.xy).rgb;
            	#endif

            	float reflCoeff = GetReflectionCoefficient(viewDirWS,normal,1);
            	albedo+= lerp(0,envHdrCol,reflCoeff);

                //halflanbert
                // float3 diffuse=(dot(lightDir,normal)*0.5+0.5)*real4(light.color,1)*albedo;
                // //float3 diffuse=LightingLambert(light.color,lightDir,normal);
                // float3 specular=pow(max(0,dot(normalize(viewDirWS+lightDir),normal)),25)*light.color.rgb;
                // //float3 specular=LightingSpecular(light.color,lightDir,normal,normalize(GetCameraPositionWS()-i.positionWS),_SpecularColor,_Smoothness);
                // float3 finalCol=diffuse+specular;

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

                float3 finalCol=directCol;

            	#if _FOAM
            	float3 foamAtten=GetFoamAtten(i.positionWS,screenPos);
            	float2 foamUV=(uvwA+time*0.01+normal.xz*0.005)*30;
            	float foamalDiff=SAMPLE_TEXTURE2D(_FoamTex,sampler_FoamTex,foamUV).g;
            	half3 foamTerm=(light.color+diffcol)*foamalDiff;
            	finalCol=lerp(finalCol,foamTerm,foamAtten*foamalDiff);
            	#endif

            	#if _CAUSTICS
            	float3 worldPos=TransformNDCToWorld(screenPos.xy,rawDepth);
            	float3 castics=GetCaustics(worldPos,normal.xz);
            	float ydiff=i.positionWS.y-worldPos.y;
            	finalCol+=castics*saturate(1-ydiff);
            	#endif

            	//float depth1=SAMPLE_TEXTURE2D_X(_CameraDepthTexture,sampler_CameraDepthTexture,screenPos.xy).r;
            	//float3 worldPos1=ReconstructWorldPosition(depth1,screenPos);
            	return float4(finalCol,1);
            }
            ENDHLSL
        }
    }
}
