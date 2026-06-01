Shader "Shadertoy/XsdBDS_ToonyFire"
{
    Properties
    {
        _Channel0("Channel0", 2D) = "white" {}
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

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            TEXTURE2D(_Channel0);
            SAMPLER(sampler_Channel0);
            float4 _STResolution;
            float _STTime;

            static const int NUM_OCTAVES = 4;
            static const float NUM_STEPS = 4.0;
            static const float FLAME_SIZE = 5.7;

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float NoiseTexel(int2 ip)
            {
                int2 p = int2(ip.x & 255, ip.y & 255);
                return _Channel0.Load(int3(p, 0)).x;
            }

            float Noise2D(float2 x)
            {
                int2 p = (int2)floor(x);
                float2 f = frac(x);
                f = f * f * (3.0 - 2.0 * f);

                float rgA = NoiseTexel(p + int2(0, 0));
                float rgB = NoiseTexel(p + int2(1, 0));
                float rgC = NoiseTexel(p + int2(0, 1));
                float rgD = NoiseTexel(p + int2(1, 1));

                return lerp(lerp(rgA, rgB, f.x), lerp(rgC, rgD, f.x), f.y);
            }

            float ComputeFBM(float2 pos)
            {
                float amplitude = 1.0;
                float sum = 0.0;
                float maxAmp = 0.0;
                [loop]
                for (int i = 0; i < NUM_OCTAVES; ++i)
                {
                    sum += Noise2D(pos) * amplitude;
                    maxAmp += amplitude;
                    amplitude *= 0.5;
                    pos *= 2.0;
                }
                return sum / maxAmp;
            }

            float3 firePaletteCheap(float i)
            {
                return pow(float3(1.65, 1.2, 1.0) * i, float3(1.0, 2.5, 12.0));
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.uv * _STResolution.xy;
                float2 ndc = (2.0 * fragCoord - _STResolution.xy) / _STResolution.y;
                float uvy = (ndc.y + 1.0) * 0.5;

                float noise = ComputeFBM(ndc * float2(2.0, 1.0) * 3.5 + float2(0.0, -_STTime * 7.0));
                float noise2 = ComputeFBM(ndc + float2(-_STTime * sin(_STTime * 0.005) * 0.3 - 50.0, 121.0));
                noise *= pow(max(noise2, 1e-4), 0.55);

                float2 mouseEffect = float2(1.4, 0.85);
                noise *= (FLAME_SIZE - pow(uvy * 21.0 * mouseEffect.y + abs(ndc.x) * 14.0, 0.57) * mouseEffect.x);

                noise = saturate(noise);
                noise = floor(noise * NUM_STEPS) / NUM_STEPS;
                float3 fireColor = firePaletteCheap(noise);
                return float4(fireColor, 1.0);
            }
            ENDHLSL
        }
    }
}
