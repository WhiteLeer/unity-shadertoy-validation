Shader "Shadertoy/ttXczl_Screenprinting"
{
    Properties
    {
        _Channel0("Channel0", 2D) = "white" {}
        _Channel1("Channel1", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode"="UniversalForward" }
            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/unity-shadertoy-validation/Common/Shaders/ShadertoyCompat.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            TEXTURE2D(_Channel1); SAMPLER(sampler_Channel1);
            float4 _STResolution;
            float _STTime;

            static const float CELL_SZ = 0.02;
            static const float COL_SEP = 0.2;
            static const float STR = 1.4;
            static const float LUM_EPS = 6.0;
            static const float SMOOTHNESS = 0.004;
            #define PI 3.14159265

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float2x2 Rot(float a)
            {
                float c = cos(a);
                float s = sin(a);
                return float2x2(c, -s, s, c);
            }

            float2 Mod2(float2 x, float y)
            {
                return x - y * floor(x / y);
            }

            float2 PMod(float2 p, float j)
            {
                return Mod2(p, j) - 0.5 * j;
            }

            float2 Hash22(float2 p)
            {
                float3 p3 = frac(float3(p.x, p.y, p.x) * float3(0.1031, 0.1030, 0.0973));
                p3 += dot(p3, p3.yzx + 33.33);
                return frac((p3.xx + p3.yz) * p3.zy);
            }

            float Noise(float2 p)
            {
                float2 fruv = frac(p);
                float2 fluv = floor(p);
                float a = lerp(Hash22(fluv).x, Hash22(fluv + float2(1, 0)).x, fruv.x);
                float b = lerp(Hash22(fluv + float2(0, 1)).x, Hash22(fluv + float2(1, 1)).x, fruv.x);
                return lerp(a, b, fruv.y);
            }

            float OpSmoothUnion(float d1, float d2, float k)
            {
                float h = saturate(0.5 + 0.5 * (d2 - d1) / k);
                return lerp(d2, d1, h) - k * h * (1.0 - h);
            }

            float SdCoolBall(float2 uv)
            {
                float sdBall = length(uv) - 0.4;
                sdBall = OpSmoothUnion(sdBall, length(uv + 0.5 + float2(sin(_STTime) * 0.1, sin(_STTime) * 0.1)) - 0.1, 0.4);
                sdBall = OpSmoothUnion(sdBall, length(uv - 0.5 + float2(sin(_STTime / 2.0 + cos(_STTime)) * 0.1, sin(_STTime / 2.0 + cos(_STTime)) * 0.1)) - 0.1, 0.4);
                sdBall = OpSmoothUnion(sdBall, length(uv - float2(-0.5, 0.2) + float2(sin(_STTime / 2.0), cos(_STTime + 4.0)) / 14.0) - 0.04, 0.3);
                return sdBall;
            }

            float3 GetImg(float2 fragCoord)
            {
                float2 uv = float2(fragCoord.y - 0.5 * _STResolution.y, fragCoord.x - 0.5 * _STResolution.x) / _STResolution.y;
                float3 col = float3(0, 0, 0);

                float2 puv = float2(AtanGLSL(uv.x, uv.y) / PI + 1.0, length(uv));
                if (puv.x < 0.4) col = float3(0.2, 0.5, 0.4) * 1.55;
                else if (puv.x < 1.0) col = float3(0.5, 0.5, 0.9);
                else if (puv.x < 1.4) col = float3(1.0, 0.716, 0.7);
                else col = float3(0.9, 0.6, 0.6);

                col = lerp(col, float3(1, 0.1, 0.6), smoothstep(1.0, 0.0, length(abs(uv.y)) * 4.0 + 0.3));
                uv = mul(uv, Rot(-1.2));
                col = lerp(col, float3(1, 0.1, 0.5), smoothstep(1.0, 0.0, length(abs(uv.y)) * 4.0 + 0.3));
                uv = mul(uv, Rot(-1.4));

                float3 bc = float3(1.0, 0.7, 0.6) * lerp(float3(1, 1, 1), float3(0.1, 0.0, 0.0), smoothstep(0.0, 1.0, uv.x + uv.y * 1.5 - 0.1 + length(uv) / 1.5));

                float dA = SdCoolBall(uv);
                float dB = SdCoolBall(uv - 0.04);
                col = lerp(col, float3(1, 1, 0.9), smoothstep(SMOOTHNESS, 0.0, dB));
                col = lerp(col, bc, smoothstep(SMOOTHNESS, 0.0, dA));

                col = lerp(col, float3(1, 0.7, 1), smoothstep(1.0, 0.0, length(uv + float2(0.13, 0.25)) * 18.0 + 0.3));
                col = lerp(col, float3(1, 0.7, 1), smoothstep(1.0, 0.0, length(uv + float2(0.7, 0.4)) * 14.0 + 0.3));
                return col;
            }

            float3 GetAvg(float2 U)
            {
                float3 n = GetImg(U + float2(0.0, 1.0) * LUM_EPS);
                float3 s = GetImg(U - float2(0.0, 1.0) * LUM_EPS);
                float3 e = GetImg(U + float2(1.0, 0.0) * LUM_EPS);
                float3 w = GetImg(U - float2(1.0, 0.0) * LUM_EPS);
                float3 se = GetImg(U + float2(1.0, -1.0) * LUM_EPS);
                float3 sw = GetImg(U + float2(-1.0, -1.0) * LUM_EPS);
                float3 ne = GetImg(U + float2(1.0, 1.0) * LUM_EPS);
                float3 nw = GetImg(U + float2(-1.0, 1.0) * LUM_EPS);
                return (n + e + w + s + ne + sw + se + nw) / 8.0;
            }

            float Dots(float2 p, float lum)
            {
                float2 q = p;
                p = mul(p, Rot(0.25 * PI));
                q /= (CELL_SZ / PI);
                float nrm = max(length(p), 1e-5);
                p -= length(sin(q)) * (p / nrm) * CELL_SZ / 6.0;
                p = PMod(p, CELL_SZ);
                nrm = max(length(p), 1e-5);
                p -= length(sin(q)) * (p / nrm) * CELL_SZ / 6.0;

                float n = Noise(q * 10.0);
                n = pow(n, 2.0) * 0.07;
                float lsz = pow(smoothstep(0.0, 1.0, lum * (0.45 + n)), STR) * CELL_SZ * 0.6;
                return smoothstep(0.003, 0.0, length(p) - lsz);
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.uv * _STResolution.xy;
                float2 uv = fragCoord / _STResolution.y;

                float3 tex = GetAvg(fragCoord);
                float lum = length(tex);
                float3 col = float3(0.1, 0.5, 0.9) * 0.1;
                col = lerp(col, floor(tex / COL_SEP) * COL_SEP, Dots(uv, lum));
                col = smoothstep(0.0, 1.0, col);
                col = pow(col, 0.4545);
                return float4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
