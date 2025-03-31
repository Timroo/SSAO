
Shader "SSAO/NormalCompare"
{
    SubShader{
        CGINCLUDE
        #include "UnityCG.cginc"
        struct appdata{
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };  
        struct v2f{
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
        };
        v2f vert(appdata v){
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            return o;
        }  
        
        // 前向渲染
        sampler2D _CameraDepthNormalsTexture;
        // 延迟渲染
        sampler2D _CameraGBufferTexture2;


        ENDCG

        Cull Off ZWrite Off ZTest Always
        
        // 前向渲染
        Pass{
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            half4 frag(v2f i) : SV_Target{
                float2 uv = i.uv;
                float3 normalVS = tex2D(_CameraDepthNormalsTexture, uv).rgb * 2.0 - 1.0;
                float3 normalWS = mul((float3x3)unity_CameraToWorld, normalVS);
                return half4(normalize(normalWS), 1);
            }
            ENDCG
        }

        // 延迟渲染
        Pass{
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            half4 frag(v2f i) : SV_Target{
                float2 uv = i.uv;
                float3 normalWS = tex2D(_CameraGBufferTexture2, uv).xyz * 2.0 - 1.0;
                return half4(normalize(normalWS), 1);
            }
            ENDCG
        }
    }
}