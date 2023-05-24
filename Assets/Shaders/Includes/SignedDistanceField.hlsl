float sdCircle(float2 p,float2 center,float radius)
{
    return length(p-center)-radius;
}

float sdSphera(float3 p,float3 center, float radius)
{
    return length(p-center)-radius;
}

float sdRect(float2 p,float2 center,float2 size)
{
    float2 q=abs(p-center)-size;
    return length(max(q,0.0))+min(max(q.x,q.y),0.0);
}

float sdBox(float3 p,float3 center,float3 size)
{
    float3 q=abs(p-center)-size;
    return length(max(q,0.0))+min(max(q.x,max(q.y,q.z)),0.0);
}