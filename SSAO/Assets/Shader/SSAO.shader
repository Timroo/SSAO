Shader "SSAO/SSAO"
{
    SubShader
    {
            CGINCLUDE
            #include "SSAO.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            sampler2D _MainTex, _AOTex, _SourceTex;
            float _SampleCount, _Radius, _RangeCheck, _AOInt;
            float4x4 _VMatrix, _PMatrix;
            float4 _AOCol;
            
            fixed4 frag (v2f i) : SV_Target
            {
                // 基本向量：视角空间深度、像素世界空间坐标、像素世界空间法线
                float eyeDepth = GetEyeDepth(i.uv);
                float4 wPos = GetWorldPos(i.uv);//world pos 
                float3 wNor = GetWorldNormal(i.uv);//world normal

                // 构建TBN矩阵（已知normal）
                float3 wTan = GetRandomVec(i.uv);
                float3 wBin = cross(wNor, wTan);
                wTan = cross(wBin, wNor);
                float3x3 TBN_Line = float3x3(wTan, wBin, wNor); // 切线空间

                // 环境光遮蔽采样-主循环
                float ao = 0;
                int sampleCount = (int)_SampleCount;
                [unroll(128)]
                for(int j = 0; j < sampleCount; j++)
                {
                // 【切线空间确定随机偏移】
                    //float3 offDir = _OffDirs[j];
                    // 半球随机方向
                    float3 offDir = GetRandomVecHalf(j * i.uv);
                    float scale = j / _SampleCount;
                    scale = lerp(0.01, 1, scale * scale);   // 距离衰减，靠近中心更密集（根据scale平方增长）
                    offDir *= scale * _Radius;
                    float weight = smoothstep(0,0.2,length(offDir));    //距离越小，权重越大
                    // float smoothstep(float edge0, float edge1, float x);
                    // 如果 x < edge0，返回 0。
                    // 如果 x > edge1，返回 1。

                // 【世界空间发生偏移】
                    offDir = mul(offDir, TBN_Line);             // 转到世界空间
                    float4 offPosW = float4(offDir, 0) + wPos;      // 世界空间偏移位置

                // 【NDC空间比较深度】
                    // 世界空间 - 视角空间 - 裁剪空间 - ndc空间
                    float4 offPosV = mul(_VMatrix, offPosW);
                    float4 offPosC = mul(_PMatrix, offPosV);
                    float2 offPosScr = offPosC.xy / offPosC.w;
                    offPosScr = offPosScr * 0.5 + 0.5;
                    // 采样深度与实际深度比较
                    // - 采样深度 > 实际深度，说明被挡住了 增加AO
                    float sampleDepth = GetEyeDepth(offPosScr);
                    float sampleZ = offPosC.w;          
                    // 距离差越大时遮蔽影响越小
                    // - 采样半径/深度插值
                        // 如果差值较小，商大，说明影响大
                        // 如果差值较大，商小，影响小          
                    float rangeCheck = smoothstep(0, 1.0, _Radius / abs(sampleZ - sampleDepth) * _RangeCheck * 0.1);
                    // 避免自己遮自己
                    float selfCheck = (sampleDepth < eyeDepth - 0.08) ?  1 : 0;                    
                    ao += (sampleDepth < sampleZ) ?  1 * rangeCheck * selfCheck * _AOInt * weight : 0;
                }
                // 平均处理
                // - AO越大表示越明亮（无遮挡
                ao = 1 - saturate((ao / sampleCount));
                return ao;
                
            }
            ENDCG

        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_final 

            fixed4 frag_final (v2f i) : SV_Target
            {
                // 不知道为什么感觉_MainTex被占用了一样，一直是灰的
                float4 scrTex = tex2D(_MainTex, i.uv);  
                float4 aoTex = tex2D(_AOTex, i.uv);
                float4 SourceTex = tex2D(_SourceTex, i.uv);

                // float4 finalCol = lerp(scrTex * _AOCol, scrTex, aoTex.x);

                // 根据aoTex的值进行插值，aoTex作为阴影的话，就是(0,1)
                float4 finalCol = lerp(SourceTex * _AOCol, SourceTex, aoTex.x);

                // return aoTex; // 只看模糊效果
                return finalCol;
            }

            ENDCG
        }
    }
}
