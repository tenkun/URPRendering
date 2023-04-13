using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ParticleEffect : MonoBehaviour
{
    public ComputeShader computeShader;
    public Material material;

    const int mParticleCount = 20000;
    ComputeBuffer mParticleDataBuffer;
    int kernelId;
    
    struct ParticleData
    {
        public Vector3 pos;
        public Color color;
    }

    private void Start()
    {
        mParticleDataBuffer = new ComputeBuffer(mParticleCount, 28);
        ParticleData[] particleDatas = new ParticleData[mParticleCount];
        mParticleDataBuffer.SetData(particleDatas);
        kernelId = computeShader.FindKernel("UpdateParticle");
    }

    private void Update()
    {
        computeShader.SetBuffer(kernelId,"ParticleBuffer",mParticleDataBuffer);
        computeShader.SetFloat("Time",Time.time);
        computeShader.Dispatch(kernelId,mParticleCount/10000,1,1);
        material.SetBuffer("_particleDataBuffer",mParticleDataBuffer);
    }

    private void OnRenderObject()
    {
        material.SetPass(0);
        Graphics.DrawProceduralNow(MeshTopology.Points,mParticleCount);
    }

    private void OnDestroy()
    {
        mParticleDataBuffer.Release();
        mParticleDataBuffer.Dispose();
    }
}
