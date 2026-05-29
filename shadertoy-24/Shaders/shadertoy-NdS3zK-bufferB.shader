Shader "Shadertoy/NdS3zK_BufferB"
{
    Properties
    {
        _Channel0("Buffer A", 2D) = "black" {}
        _Channel1("Previous Buffer B", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "BufferB"
            Cull Off ZWrite Off ZTest Always
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS:POSITION; float2 uv:TEXCOORD0; };
            struct Varyings { float4 positionHCS:SV_POSITION; float2 uv:TEXCOORD0; float2 fragCoord:TEXCOORD1; };

            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            TEXTURE2D(_Channel1); SAMPLER(sampler_Channel1);
            float4 _STResolution;
            float _STFrame;

            float4 mod289(float4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            float4 permute(float4 x) { return mod289(((x * 34.0) + 1.0) * x); }
            float4 taylorInvSqrt(float4 r) { return 1.79284291400159 - 0.85373472095314 * r; }
            float2 fade2(float2 t) { return (t * t * t) * (t * (t * 6.0 - 15.0) + 10.0); }
            float mod1(float x, float y) { return x - y * floor(x / y); }
            float3 mod3(float3 x, float y) { return x - y * floor(x / y); }

            float Perlin(float2 position, float2 rep)
            {
                float4 pi = floor(float4(position.xy, position.xy)) + float4(0, 0, 1, 1);
                float4 pf = frac(float4(position.xy, position.xy)) - float4(0, 0, 1, 1);
                pi = pi - float4(rep.xy, rep.xy) * floor(pi / float4(rep.xy, rep.xy));
                pi = pi - 289.0 * floor(pi / 289.0);

                float4 ix = float4(pi.x, pi.z, pi.x, pi.z);
                float4 iy = float4(pi.y, pi.y, pi.w, pi.w);
                float4 fx = float4(pf.x, pf.z, pf.x, pf.z);
                float4 fy = float4(pf.y, pf.y, pf.w, pf.w);
                float4 ii = permute(permute(ix) + iy);

                float4 gx = 2.0 * frac(ii / 41.0) - 1.0;
                float4 gy = abs(gx) - 0.5;
                float4 tx = floor(gx + 0.5);
                gx -= tx;

                float2 g00 = float2(gx.x, gy.x);
                float2 g10 = float2(gx.y, gy.y);
                float2 g01 = float2(gx.z, gy.z);
                float2 g11 = float2(gx.w, gy.w);

                float4 norm = taylorInvSqrt(float4(dot(g00,g00), dot(g01,g01), dot(g10,g10), dot(g11,g11)));
                g00 *= norm.x; g01 *= norm.y; g10 *= norm.z; g11 *= norm.w;

                float n00 = dot(g00, float2(fx.x, fy.x));
                float n10 = dot(g10, float2(fx.y, fy.y));
                float n01 = dot(g01, float2(fx.z, fy.z));
                float n11 = dot(g11, float2(fx.w, fy.w));
                float2 fxy = fade2(pf.xy);
                float2 nx = lerp(float2(n00, n01), float2(n10, n11), fxy.x);
                return 2.3 * lerp(nx.x, nx.y, fxy.y);
            }

            float Hash(float n) { return frac(sin(n) * 43758.5453); }

            float Noise(float3 x)
            {
                float3 p = floor(x);
                float3 f = frac(x);
                f = f * f * (3.0 - 2.0 * f);
                float n = p.x + p.y * 57.0 + 113.0 * p.z;
                return lerp(
                    lerp(lerp(Hash(n + 0.0), Hash(n + 1.0), f.x), lerp(Hash(n + 57.0), Hash(n + 58.0), f.x), f.y),
                    lerp(lerp(Hash(n + 113.0), Hash(n + 114.0), f.x), lerp(Hash(n + 170.0), Hash(n + 171.0), f.x), f.y),
                    f.z);
            }

            float Worley(float3 pos, float numCells)
            {
                float3 p = pos * numCells;
                float d = 1.0e10;
                [unroll] for (int x = -1; x <= 1; x++)
                [unroll] for (int y = -1; y <= 1; y++)
                [unroll] for (int z = -1; z <= 1; z++)
                {
                    float3 tp = floor(p) + float3(x, y, z);
                    tp = p - tp - Noise(mod3(tp, numCells));
                    d = min(d, dot(tp, tp));
                }
                return 1.0 - clamp(d, 0.0, 1.0);
            }

            float FBM(float2 pos, float2 scale)
            {
                float res = 0.0;
                float freq = 1.0;
                float amp = 1.0;
                [unroll] for (int i = 0; i < 5; i++)
                {
                    float offset = float(5 - i);
                    float signValue = (i & 1) != 0 ? 1.0 : -1.0;
                    res += signValue * Perlin(freq * (pos + offset), freq * scale) * amp;
                    freq *= 2.0;
                    amp *= 0.5;
                }
                return res / 5.0;
            }

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                o.fragCoord = i.uv * _STResolution.xy;
                return o;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 uv = i.fragCoord / _STResolution.xy;
                float resolutionChanged = SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, (float2(0, 2) + 0.5) / _STResolution.xy).r;

                if (_STFrame < 1.0 || resolutionChanged > 0.0)
                {
                    float2 scale = float2(8.0, 15.0);
                    float heightNoise = 0.5 + 0.5 * FBM(scale * uv, scale);
                    float cellNoise = Worley(2.0 * float3(uv, 0.0), 2.0);
                    return float4(heightNoise, cellNoise, 0.0, 1.0);
                }

                return SAMPLE_TEXTURE2D(_Channel1, sampler_Channel1, uv);
            }
            ENDHLSL
        }
    }
}
