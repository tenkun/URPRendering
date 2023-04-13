#ifndef WATER_PRE_COMPUTE
#define WATER_PRE_COMPUTE


    float3 UnpackDerivativeHeight (float4 textureData) {
        float3 dh = textureData.agb;
        dh.xy = dh.xy * 2 - 1;
        return dh;
    }


    inline float3 _GetCameraDirection(float sp)
    {
        //float camDir
    }

    float3 FlowUV(float2 uv, float4 flowmap,float2 time,float speed,bool flowB,float noise,float U,float V){
        float phaseOffset = flowB?0.5:0;
        float phase = frac(_Time.y*0.1*speed+phaseOffset+noise);
        float3 flowUVW;
        flowUVW.xy = uv- flowmap.xy* phase;
        flowUVW.z = abs((0.5-phase)/0.5);
        return flowUVW;
    }


    float3 GerstnerWave(
    float4 wave,float3 position,inout float3 tangent,inout float3 binormal
    ,float waveSpeed,float scale)
    {

        float steepness = wave.z/scale;
        float wavelength = wave.w/scale;
        
        float k = 2*3.14/wavelength; 
        float c = sqrt(9.8/k);
        float2 d = normalize(wave.xy);
        float f = k*(dot(d,position.xz) - (waveSpeed/scale)*_Time.y);
        float a = steepness/k;
        
        tangent += float3(1-d.x*d.x*(steepness*sin(f)),
        d.x*(steepness*cos(f)),
        -d.x*d.y*(steepness*sin(f)));

        binormal += float3(
        -d.x*d.y*(steepness*sin(f)),
        d.y*(steepness*cos(f)),
        1-d.y*d.y*(steepness*sin(f))
        );

        
        return float3(d.x*(a*cos(f)),a*sin(f),d.y*(a*cos(f))
        );
    }



    

    float2 AlignWithGrabTexel(float2 uv){
        return (floor(uv*_CameraDepthTexture_TexelSize.zw)+ 0.5)*abs(_CameraDepthTexture_TexelSize.xy);
    }

    float3 ColorBelowWater
    (float4 screenPos,FLOAT WaterZ,float3 Bump,float grabSign,
    float refractionintensity,float4 GradiantPosition,float DepthDiff,
    inout float DepthDiffRefraction)
    {
        float2 refractionUVOffset = Bump*0.01*refractionintensity;
        float4 tex = tex2D(_CameraOpaqueTexture, screenPos);
        refractionUVOffset *= saturate((DepthDiff)/abs(refractionintensity)+0.001);
        float2 sceneRefractionUVs = float2(1,grabSign)*(screenPos)+float4(refractionUVOffset, refractionUVOffset).rg;
        sceneRefractionUVs = AlignWithGrabTexel(sceneRefractionUVs);
        
        float sceneZRefraction = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, sceneRefractionUVs)), _ZBufferParams);
        DepthDiffRefraction = sceneZRefraction - WaterZ;
        
        if (DepthDiffRefraction < 0){
            sceneRefractionUVs =  AlignWithGrabTexel(float2(1,grabSign)*screenPos);
        }
        
        sceneZRefraction = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, sceneRefractionUVs)), _ZBufferParams);
        DepthDiffRefraction = sceneZRefraction - WaterZ;
        DepthDiffRefraction /= GradiantPosition.a;//控制场景深度差值
        DepthDiffRefraction = clamp(0,1,DepthDiffRefraction);
        //DepthDiffRefraction *= 1/clamp(100,300,(WaterZ*0.01));//根据水平面深度差修正深度差

        //DepthDiffRefraction /= _SceanDepth;//TODO 三阶颜色
        float3 refractionColor = tex2D(_CameraOpaqueTexture, sceneRefractionUVs).xyz;
        return refractionColor;

    }     


    //D项 法线微表面分布函数 
    float D_Function(float NdotH,float roughness)
    {
        float a2=roughness*roughness;
        float NdotH2=NdotH*NdotH;
        
        //直接根据公式来
        float nom=a2;//分子
        float denom=NdotH2*(a2-1)+1;//分母
        denom=denom*denom*PI;
        return nom/denom;
    }

    //G项子项
    float G_section(float dot,float k)
    {
        float nom=dot;
        float denom=lerp(dot,1,k);
        return nom/denom;
    }

    //G项
    float G_Function(float NdotL,float NdotV,float roughness)
    {
        float k=pow(1+roughness,2)/8;
        float Gnl=G_section(NdotL,k);
        float Gnv=G_section(NdotV,k);
        return Gnl*Gnv;
    }

    //F项 直接光
    real3 F_Function(float HdotL,float3 F0)
    {
        float Fre=exp2((-5.55473*HdotL-6.98316)*HdotL);
        return lerp(Fre,1,F0);
    }

    //F项 间接光
    real3 IndirF_Function(float NdotV,float3 F0,float roughness)
    {
        float Fre=exp2((-5.55473*NdotV-6.98316)*NdotV);
        return F0+Fre*saturate(1-roughness-F0);
    }

#endif