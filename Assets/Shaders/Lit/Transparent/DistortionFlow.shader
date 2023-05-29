Shader "Game/Lit/Transparency/Water"
{
    Properties
    {
         _MainTex("Main Tex",2D)="white"{}
        _Color("Color Tint",Color)=(1,1,1,1)
        
        [Header(Flow)]
        [NoScaleOffset]_FlowTex("Flow Tex",2D)="white"{}
        _FlowStrength("Flow Strength",Range(0.1,1.5))=1
        _FlowOffset ("Flow Offset", Float) = 0
        _Speed("Speed",Range(0.1,2))=1
        _UJump("U jump per phase",Range(-0.25,0.25))=0.25
        _VJump("V jump per phase",Range(-0.25,0.25))=0.25
        _Tilling("Tilling",float)=1
        
         [Header(Normal)]
        [NoScaleOffset]_NormalTex("Normal Tex",2D)="bump"{}
    	_NormalStrength("Normal Strenght",Range(0,1))=0.3
        _DeriveHeightTex("Derive Height Tex",2D)="white"{}
        _HeightScale("Height Scale",float)=1
        _HeightScaleModulated("Height Scale Modulated",float)=1
    	
    	[Header(Wave)]
    	[Toggle(_WAVE)]_Wave("Enable",int)=1
    	[Foldout(_WAVE)]_WaveA ("Wave A (dir, steepness, wavelength)", Vector) = (1,0,0.5,10)
		[Foldout(_WAVE)]_WaveB ("Wave B", Vector) = (0,1,0.25,20)
		[Foldout(_WAVE)]_WaveC ("Wave C", Vector) = (1,1,0.15,10)
    	[Foldout(_WAVE)]_WaveSpeed ("Wave Speed", float) = 1
        
        [Header(highLight)]
        _Smoothness("Smoothness",Range(0,1))=1
        _SpecularColor("Specular Color",Color)=(1,1,1,1)
    	
         [Header(WaterFog)]
    	_WaterFogColor("Water Fog Color",Color)=(1,1,1,1)
    	_WaterFogDensity("Water Fog Desity",Range(0,2))=0.1
    	
         [Header(Refract)]
    	_RefractionStrength("Refract Strength",Range(0,1))=0.25
    	
    	[Header(Reflection)]
    	[Toggle(_REFLECT)]_ProbeReflect("Enable",int)=0
    	[Foldout(_REFLECT)][Enum(Planar,0,SSR,1,SSPR,2)]_ReflectType("Reflect Type",int)=2
    	[Foldout(_REFLECT)]_FresnelPower("Fresnel",Range(0,5))=1
	    [Foldout(_REFLECT)]_ReflectionStrength("Reflect Strength",Range(0,1))=0.25
    	[Toggle(_Anisotropic)]_Anisotropic("Anisotropic",int)=0
    	
    	[Header(Foam)]
    	[Toggle(_FOAM)]_Foam("Enable",int)=0
    	[NoScaleOffset][Foldout(_FOAM)]_FoamTex("Foam Tex",2D)="white"{}
    	[NoScaleOffset][Foldout(_FOAM)]_FoamRampTex("Foam Ramp Tex",2D)="white"{}
    	[Foldout(_FOAM)]_FoamPower("Foam Power",Range(0,1))=0.5
    	[Foldout(_FOAM)]_FoamAttenuation("Foam Attenuation",Range(1,5))=3
    	[Foldout(_FOAM)][MinMaxRange]_FoamRange("Range ",Range(0.01,20))=0
    	[Foldout(_FOAM)]_FoamRangeEnd("RangeEnd",Range(0.01,20))=1
    	
	    [Header(Caustics)]
    	[Toggle(_CAUSTICS)]_Caustics("Enable",int)=0
    	[NoScaleOffset][Foldout(_CAUSTICS)]_CausticsTex("Cautics Tex",2D)="white"{}
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
            #pragma shader_feature _REFLECT
            #pragma shader_feature _FOAM
            #pragma shader_feature _CAUSTICS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Shaders/Includes/Instance.hlsl"
            #include "Assets/Shaders/Includes/ValueMapping.hlsl"
            #include "Assets/Shaders/Includes/PBR_Func.hlsl"
            #include "Assets/Shaders/Includes/DepthPreCompute.hlsl"
            #include "Assets/Shaders/Includes/DepthNormal.hlsl"
            #include "Assets/Shaders/Includes/Reflection.hlsl"

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
            TEXTURE2D(_NormalTex);SAMPLER(sampler_NormalTex);
            TEXTURE2D(_DeriveHeightTex);SAMPLER(sampler_DeriveHeightTex);
            TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);
            TEXTURE2D(_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D(_FoamTex);SAMPLER(sampler_FoamTex);
            TEXTURE2D(_FoamRampTex);SAMPLER(sampler_FoamRampTex);
            TEXTURE2D(_CausticsTex);SAMPLER(sampler_CausticsTex);
            SamplerState sampler_point_clamp;
            INSTANCING_BUFFER_START
                INSTANCING_PROP(float4,_Color)
                INSTANCING_PROP(float4,_MainTex_ST)
                INSTANCING_PROP(float,_UJump)
                INSTANCING_PROP(float,_VJump)
				INSTANCING_PROP(float,_Tilling)
				INSTANCING_PROP(float,_Speed)
				INSTANCING_PROP(float,_FlowStrength)
				INSTANCING_PROP(float,_FlowOffset)
				INSTANCING_PROP(float4,_SpecularColor)
				INSTANCING_PROP(float,_Smoothness)
				INSTANCING_PROP(float,_NormalStrength)
				INSTANCING_PROP(float,_HeightScale)
				INSTANCING_PROP(float,_HeightScaleModulated)
				INSTANCING_PROP(float4,_WaveA)
				INSTANCING_PROP(float4,_WaveB)
				INSTANCING_PROP(float4,_WaveC)
				INSTANCING_PROP(float,_WaveSpeed)
				INSTANCING_PROP(float4,_CameraDepthTexture_TexelSize)
				INSTANCING_PROP(float4,_WaterFogColor)
				INSTANCING_PROP(float,_WaterFogDensity)
				INSTANCING_PROP(float,_RefractionStrength)
				INSTANCING_PROP(float,_FoamRange)
				INSTANCING_PROP(float,_FoamRangeEnd)
				INSTANCING_PROP(float,_ReflectionStrength)
				INSTANCING_PROP(float,_FresnelPower)
				INSTANCING_PROP(bool,_Anisotropic)
				INSTANCING_PROP(float,_FoamPower)
				INSTANCING_PROP(float,_FoamAttenuation)
				INSTANCING_PROP(int,_ReflectType)
            INSTANCING_BUFFER_END

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
            
            float3 ColorBelowWater(float4 screenPos,float3 normal)
            {
            	float2 uvOffset=normal.xz*_RefractionStrength;
            	float2 uv=screenPos.xy+uvOffset/screenPos.w;
            	float bgDepth=SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_point_clamp,uv).r;
            	float depthDiff=GetDepthDiffVS(bgDepth,screenPos.w);

            	uvOffset*=saturate(depthDiff);
            	uv=screenPos.xy+uvOffset/screenPos.w;
            	bgDepth=SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_point_clamp,uv).r;
            	depthDiff=GetDepthDiffVS(bgDepth,screenPos.w);
            	
            	float3 belowCol=SAMPLE_TEXTURE2D(_CameraOpaqueTexture,sampler_point_clamp,uv).rgb;
            	float fogFactor=exp2(-_WaterFogDensity*depthDiff);
            	return lerp(_WaterFogColor.rgb,belowCol,fogFactor);
            }

            float3 GetCaustics(float3 depthPositionWS,float2 normal)
            {
	            float2 uv=depthPositionWS.xz*float2(0.5,1)+normal*_ReflectionStrength;
            	return SAMPLE_TEXTURE2D(_CausticsTex,sampler_CausticsTex,uv).rgb;
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
                o.uv = TRANSFORM_TEX_INSTANCE(v.uv, _MainTex);
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
                rawDepth = lerp(UNITY_NEAR_CLIP_VALUE, 1, rawDepth);
				#endif
            	float3 positionDWS=TransformNDCToWorld(screenPos.xy,rawDepth);
            	float bgDepth=RawToEyeDepth(rawDepth);
            	float depthDist=bgDepth-screenPos.w;

            	//Light
                Light light=GetMainLight();
                half3 lightDir=normalize(light.direction);

            	//Flow
                float3 flow=SAMPLE_TEXTURE2D(_FlowTex,sampler_FlowTex,i.uv).rgb;
                flow.xy=flow.xy*2-1;
                flow*=_FlowStrength;
                //flowVec=float2(0,0);
                //float noise=SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,i.uv).r;
                float noise=SAMPLE_TEXTURE2D(_FlowTex,sampler_FlowTex,i.uv).a;
                float time = _Time.y * _Speed + noise;
                float2 jump=float2(_UJump,_VJump);
                
                float3 uvwA=flowUV(i.uv,jump,_FlowOffset,_Tilling,flow.xy,time,false);
                float3 uvwB=flowUV(i.uv,jump,_FlowOffset,_Tilling,flow.xy,time,true);

                //Normal
            	// float3 normalA=UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,uvwA.xy))*uvwA.z;
            	// float3 normalB=UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,uvwB.xy))*uvwB.z;
            	// normalA.z=pow(saturate(1-pow(normalA.x,2)-pow(normalA.y,2)),0.5);
            	// normalB.z=pow(saturate(1-pow(normalB.x,2)-pow(normalB.y,2)),0.5);
            	// float3 normal=BlendNormal(normalA,normalB,4);
            	// normal=lerp(normalWS,normalize(mul(transpose(tbn),normal)),_NormalStrength);
            	// normal=normalize(normal);

                //DerivativeHeight
            	float heightScale=flow.z * _HeightScaleModulated + _HeightScale;
                float3 dhA=UnpackDerivativeHeight(SAMPLE_TEXTURE2D(_DeriveHeightTex,sampler_DeriveHeightTex,uvwA.xy))*uvwA.z*heightScale;
                float3 dhB=UnpackDerivativeHeight(SAMPLE_TEXTURE2D(_DeriveHeightTex,sampler_DeriveHeightTex,uvwB.xy))*uvwB.z*heightScale;
                float3 dh= normalize(float3(-(dhA.xy + dhB.xy), 1));
            	dh=float3(dh.x,0,dh.y);
            	float3 normal = normalize(normalWS +dh);
            	
            	//refract
            	float3 albedo=ColorBelowWater(screenPos,dh);

            	//reflect
            	#if _REFLECT
            	float2 uvOffset=normal.xz*_ReflectionStrength;
            	float2 reflectUV=screenPos.xy+uvOffset/screenPos.w;
            	albedo=GetReflectionColor(reflectUV,albedo,viewDirWS,normal,_FresnelPower,_ReflectType,_Anisotropic);
            	#endif

            	#if _CAUSTICS
            	float3 castics=GetCaustics(positionDWS,normal.xz);
            	float ydiff=i.positionWS.y-positionDWS.y;
            	albedo+=castics*saturate(1-ydiff);
            	#endif
            	
                //half lambert
                // float3 diffuse=(dot(lightDir,normal)*0.5+0.5)*real4(light.color,1)*albedo;
                // //float3 diffuse=LightingLambert(light.color,lightDir,normal);
                // float3 specular=pow(max(0,dot(normalize(viewDirWS+lightDir),normal)),25)*light.color.rgb;
                // //float3 specular=LightingSpecular(light.color,lightDir,normal,normalize(GetCameraPositionWS()-i.positionWS),_SpecularColor,_Smoothness);
                // float3 finalCol=diffuse+specular;

                //pbr
                float metallic=0;
                float ao=0;
                float smoothness=_Smoothness;
                
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

                float3 finalCol=directCol+inDirCol;

            	#if _FOAM
            	float2 foamUV=i.positionWS.xz*0.1+time*0.005+normal.xz*0.05;
            	half3 foamMap = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, foamUV).rgb;
				half foamMask =  pow(max(0,1 - depthDist / lerp(0.1,1,_FoamPower)),_FoamAttenuation)+saturate((i.positionWS.y-_FoamRange)/(_FoamRangeEnd-_FoamRange));
				half3 foamRamp = SAMPLE_TEXTURE2D(_FoamRampTex, sampler_FoamRampTex, half2(foamMask, 0.5)).rgb;
				half3 foamCol = length(foamMap * foamRamp) * light.shadowAttenuation * light.color;
            	finalCol=lerp(finalCol,finalCol+foamCol,foamMask);
            	#endif
            	
            	return float4(finalCol,1);
            }
            ENDHLSL
        }
    }
}
