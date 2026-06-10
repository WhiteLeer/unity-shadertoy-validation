Shader "Shadertoy/MdGBWG_BufferB"
{
    Properties
    {
        _STResolution("ST Resolution", Vector) = (512,288,0.001953125,0.003472222)
        _STTime("ST Time", Float) = 0
        _LandTex("Land", 2D) = "black" {}
        _PrevBTex("PrevB", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "BufferB"
            Cull Off ZWrite Off ZTest Always
            HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _STResolution;
                float _STTime;
            CBUFFER_END

            sampler2D _LandTex;
            sampler2D _PrevBTex;

            #define MAPRES float2(144.0,72.0)
            #define PASS1 float2(0.0,0.0)
            #define PASS2 float2(0.0,0.5)
            #define PASS3 float2(0.5,0.0)
            #define PASS4 float2(0.5,0.5)
            #define N float2(0.0, 1.0)
            #define E float2(1.0, 0.0)
            #define S float2(0.0,-1.0)
            #define W float2(-1.0, 0.0)
            #define PI 3.14159265359

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; float2 fragCoord : TEXCOORD1; };

            float4 NormPdf(float x)
            {
                float2 sigma = float2(6.0, 4.0);
                float2 v = 0.39894 * exp(-0.5 * x * x / (sigma * sigma)) / sigma;
                return float4(v, 0.0, 0.0);
            }

            float4 Buf(float2 uv)
            {
                return tex2D(_PrevBTex, uv);
            }

            float4 Mslp(float2 uv)
            {
                float lat = 180.0 * (uv.y * _STResolution.y / MAPRES.y) - 90.0;
                float land = tex2D(_LandTex, uv).x;
                float4 r = 0.0.xxxx;
                if (land > 0.0)
                {
                    r.x = 1012.5 - 6.0 * cos(lat * PI / 45.0);
                    r.y = 15.0 * sin(lat * PI / 90.0);
                }
                else
                {
                    r.x = 1014.5 - 20.0 * cos(lat * PI / 30.0);
                    r.y = 20.0 * sin(lat * PI / 35.0) * abs(lat) / 90.0;
                }
                return r;
            }

            float2 WrapMap(float2 p)
            {
                float2 m = fmod(p, MAPRES);
                if (m.x < 0.0) m.x += MAPRES.x;
                if (m.y < 0.0) m.y += MAPRES.y;
                return m;
            }

            float4 Pass1(float2 uv)
            {
                float4 r = 0.0.xxxx;
                [loop] for (int k = -20; k <= 20; k++)
                {
                    r += Mslp(uv + (float)k * E / _STResolution.xy) * NormPdf((float)k);
                }
                return r;
            }

            float4 Pass2(float2 uv)
            {
                float4 r = 0.0.xxxx;
                [loop] for (int k = -20; k <= 20; k++)
                {
                    r += Buf(uv + (float)k * N / _STResolution.xy + PASS1) * NormPdf((float)k);
                }
                return r;
            }

            float4 Pass3(float2 uv)
            {
                float4 c = Buf(uv + PASS2);
                float t = fmod(_STTime, 12.0);
                float delta = c.y * (1.0 - 2.0 * smoothstep(1.5, 4.5, t) + 2.0 * smoothstep(7.5, 10.5, t));
                return float4(c.x + delta, 0.0, 0.0, 0.0);
            }

            float4 Pass4(float2 uv)
            {
                float2 p = uv * _STResolution.xy;
                float n = Buf(WrapMap(p + N) / _STResolution.xy + PASS3).x;
                float e = Buf(WrapMap(p + E) / _STResolution.xy + PASS3).x;
                float s = Buf(WrapMap(p + S) / _STResolution.xy + PASS3).x;
                float w = Buf(WrapMap(p + W) / _STResolution.xy + PASS3).x;
                float2 grad = float2(e - w, n - s) / 2.0;
                float lat = 180.0 * frac(uv.y * _STResolution.y / MAPRES.y) - 90.0;
                float2 coriolis = 15.0 * sin(lat * PI / 180.0) * float2(-grad.y, grad.x);
                float2 v = coriolis - grad;
                return float4(v, 0.0, 0.0);
            }

            Varyings Vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                OUT.fragCoord = IN.uv * _STResolution.xy;
                return OUT;
            }

            half4 Frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.fragCoord / _STResolution.xy;
                if (uv.x < 0.5)
                {
                    if (uv.y < 0.5) return Pass1(uv - PASS1);
                    return Pass2(uv - PASS2);
                }
                else
                {
                    if (uv.y < 0.5) return Pass3(uv - PASS3);
                    return Pass4(uv - PASS4);
                }
            }
            ENDHLSL
        }
    }
}
