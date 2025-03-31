#ifndef SSAO_CGINC 
#define SSAO_CGINC 

#include "UnityCG.cginc"        
// GBuffer的访问函数 
#include "UnityGBuffer.cginc"

sampler2D _CameraGBufferTexture2;
float4x4 _VPMatrix_invers;
sampler2D _CameraDepthTexture;

// 伪随机数生成函数，返回的是（0,1）
float Hash(float2 p)
{
    // frac()：提取小数部分
    return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

// 构造一个伪随机三维方向[-1,1]
float3 GetRandomVec(float2 p)
{
    float3 vec = float3(0, 0, 0);
    vec.x = Hash(p) * 2 - 1;
    vec.y = Hash(p * p) * 2 - 1;
    vec.z = Hash(p * p * p) * 2 - 1;
    return normalize(vec);
}

// 随机半球三维方向（z坐标大于0，且偏移0.2）
float3 GetRandomVecHalf(float2 p)
{
    float3 vec = float3(0, 0, 0);
    vec.x = Hash(p) * 2 - 1;
    vec.y = Hash(p * p) * 2 - 1;
    vec.z = saturate(Hash(p * p * p) + 0.2);
    return normalize(vec);
}

// 返回给定采样点的世界坐标
// - 利用屏幕空间的 UV + 深度值
float4 GetWorldPos(float2 uv)
{
    float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
#if defined(UNITY_REVERSED_Z)
    rawDepth = 1 - rawDepth;
#endif
    float4 ndc = float4(uv.xy * 2 - 1, rawDepth * 2 - 1, 1);
    float4 wPos = mul(_VPMatrix_invers, ndc);
    wPos /= wPos.w;
    return wPos;
}

// 返回视角空间深度图（线性深度）
float GetEyeDepth(float2 uv)
{
    float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
    return LinearEyeDepth(rawDepth);
}

sampler2D _CameraDepthNormalsTexture;
// float4x4 _CameraToWorld;

// 从GBuffer2中读取 世界空间法线
float3 GetWorldNormal(float2 uv)
{    
    // 延迟渲染
    float3 wNor = tex2D(_CameraGBufferTexture2, uv).xyz * 2.0 - 1.0; //world normal
    // 前向渲染:效果很差
    // float3 normalVS = tex2D(_CameraDepthNormalsTexture, uv).rgb * 2.0 - 1.0;
    // float3 wNor = mul((float3x3)unity_CameraToWorld, normalVS);
    return wNor;

}

#endif