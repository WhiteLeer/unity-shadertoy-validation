Shader "Shadertoy/MtKcDG_BufferA"
{
    Properties
    {
        _Channel0("Channel0", 2D) = "black" {}
        _Channel1("Channel1", 2D) = "gray" {}
        _Channel2("Channel2", 2D) = "gray" {}
        _FlickerStrength("FlickerStrength", Float) = 0.02
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        Pass
        {
            Name "BufferA"
            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            TEXTURE2D(_Channel1); SAMPLER(sampler_Channel1);
            TEXTURE2D(_Channel2); SAMPLER(sampler_Channel2);

            float _FlickerStrength;
            float _STTime;

            static const float ST_PI = 3.1415927;

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float2 GetRes0()
            {
                uint w, h, levels;
                _Channel0.GetDimensions(0, w, h, levels);
                return float2((float)w, (float)h);
            }

            float2 GetRes1()
            {
                uint w, h, levels;
                _Channel1.GetDimensions(0, w, h, levels);
                return float2((float)w, (float)h);
            }

            float hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 34.45);
                return frac(p.x * p.y);
            }

            float4 getRand(float2 pos, float2 res1)
            {
                return SAMPLE_TEXTURE2D_LOD(_Channel1, sampler_Channel1, pos / res1, 0.0);
            }

            float compsignedmax(float3 c)
            {
                float3 a = abs(c);
                if (a.x > a.y && a.x > a.z) return c.x;
                if (a.y > a.x && a.y > a.z) return c.y;
                return c.z;
            }

            float4 getCol(float2 pos, float lod, float2 Res, float2 Res0)
            {
                float2 uv = (pos - 0.5 * Res) * min(Res0.y / Res.y, Res0.x / Res.x) / Res0 + 0.5;
                float4 col = SAMPLE_TEXTURE2D_LOD(_Channel0, sampler_Channel0, uv, lod);
                col = saturate(((col - 0.5) * 1.4 + 0.5));

                float4 bg = SAMPLE_TEXTURE2D_LOD(_Channel2, sampler_Channel2, uv, lod + 0.7);
                float rawKey = dot(col.xyz, float3(-0.6, 1.3, -0.6));
                float key = smoothstep(0.08, 0.42, rawKey);
                col = lerp(col, bg, key);
                return col;
            }

            float3 getValCol(float2 pos, float2 Res, float2 Res0)
            {
                float lod = 1.5 + log2(max(1.0, Res0.x / 600.0));
                return getCol(pos, lod, Res, Res0).xyz;
            }

            float2 getGradMax(float2 pos, float eps, float2 Res, float2 Res0)
            {
                float2 d = float2(eps, 0.0);
                float3 c1 = getValCol(pos + d.xy, Res, Res0);
                float3 c2 = getValCol(pos - d.xy, Res, Res0);
                float3 c3 = getValCol(pos + d.yx, Res, Res0);
                float3 c4 = getValCol(pos - d.yx, Res, Res0);
                return float2(
                    compsignedmax(c1 - c2),
                    compsignedmax(c3 - c4)
                ) / eps / 2.0;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 Res = _ScreenParams.xy;
                float2 Res0 = GetRes0();
                float2 Res1 = GetRes1();

                float2 pos = i.uv * Res;
                pos += 4.0 * sin(_STTime * 0.5 * float2(1.0, 1.7)) * Res.y / 400.0;

                float canv = 0.0;
                canv = max(canv, getRand((pos * float2(0.7, 0.03)).xy, Res1).x);
                canv = max(canv, getRand((pos * float2(0.7, 0.03)).yx, Res1).x);
                float4 fragColor = float4(0.93 + 0.07 * canv, 0.93 + 0.07 * canv, 0.93 + 0.07 * canv, 1.0);
                canv -= 0.5;

                int pidx0 = 0;
                float layerScaleFact = 0.85;
                float ls = layerScaleFact * layerScaleFact;
                int NumGrid = (int)((65536.0 / 2.0) * min(pow(Res.x / 1920.0, 0.5), 1.0) * (1.0 - ls));
                float aspect = Res.x / Res.y;
                int NumX = (int)(sqrt((float)NumGrid * aspect) + 0.5);
                int NumY = (int)(sqrt((float)NumGrid / aspect) + 0.5);
                int maxLayer = (int)(log2(10.0 / (float)NumY) / log2(layerScaleFact));
                maxLayer = min(maxLayer, 9);

                for (int layer = 9; layer >= 0; layer--)
                {
                    if (layer > maxLayer) continue;

                    int NumX2 = (int)((float)NumX * pow(layerScaleFact, (float)layer) + 0.5);
                    int NumY2 = (int)((float)NumY * pow(layerScaleFact, (float)layer) + 0.5);
                    NumX2 = max(1, NumX2);
                    NumY2 = max(1, NumY2);

                    [unroll(9)]
                    for (int ni = 0; ni < 9; ni++)
                    {
                        int nx = ni % 3 - 1;
                        int ny = ni / 3 - 1;

                        int n0 = (int)dot(floor(pos / Res.xy * float2((float)NumX2, (float)NumY2)), float2(1.0, (float)NumX2));
                        int pidx2 = n0 + NumX2 * ny + nx;
                        int pidx = pidx0 + pidx2;

                        float2 brushPos = (float2((float)(pidx2 % NumX2), (float)(pidx2 / NumX2)) + 0.5) / float2((float)NumX2, (float)NumY2) * Res;
                        float gridW = Res.x / (float)NumX2;
                        float gridW0 = Res.x / (float)NumX;
                        brushPos += gridW * (getRand(float2((float)pidx, 0.0), Res1).xy - 0.5);
                        brushPos.x += gridW * 0.5 * ((float)((pidx2 / NumX2) % 2) - 0.5);

                        float2 g = getGradMax(brushPos, gridW * 1.0, Res, Res0) * 0.5 + getGradMax(brushPos, gridW * 0.12, Res, Res0) * 0.5 + 0.0003 * sin(pos / Res * 20.0);
                        float gl = length(g);
                        float2 n = (gl > 1e-5) ? normalize(g) : float2(1.0, 0.0);
                        float2 t = float2(n.y, -n.x);

                        float wh = (gridW - 0.6 * gridW0) * 1.2;
                        float lh = wh;
                        float stretch = sqrt(1.5 * pow(3.0, 1.0 / (float)(layer + 1)));
                        float4 rnd = getRand(float2((float)pidx, 1.0), Res1);
                        wh *= (0.8 + 0.4 * rnd.y) / stretch;
                        lh *= (0.8 + 0.4 * rnd.z) * stretch;
                        float wh0 = wh;
                        wh /= 1.0 - 0.25 * abs(-1.0);
                        wh = (gl * 0.1 < 0.003 / max(1e-4, wh0) && wh0 < Res.x * 0.02 && layer != maxLayer) ? 0.0 : wh;

                        float2 uvb = float2(dot(pos - brushPos, n), dot(pos - brushPos, t)) / float2(max(1e-4, wh), max(1e-4, lh)) * 0.5;
                        uvb.x += 0.125;
                        uvb.x += uvb.y * uvb.y * -1.0;
                        uvb.x /= 1.0 - 0.25 * abs(-1.0);
                        uvb += 0.5;

                        float s = 1.0;
                        s *= uvb.x * (1.0 - uvb.x) * 6.0;
                        s *= uvb.y * (1.0 - uvb.y) * 6.0;
                        float s0 = s;
                        s = saturate((s - 0.5) * 2.0);

                        float pat = SAMPLE_TEXTURE2D_LOD(_Channel1, sampler_Channel1, uvb * 1.5 * sqrt(Res.x / 600.0) * float2(0.06, 0.006), 1.0).x +
                                    SAMPLE_TEXTURE2D_LOD(_Channel1, sampler_Channel1, uvb * 3.0 * sqrt(Res.x / 600.0) * float2(0.06, 0.006), 1.0).x;

                        s0 = s;
                        s *= 0.7 * pat;
                        float2 uv0 = uvb;
                        uv0.y = 1.0 - uv0.y;
                        float smask = saturate(max(cos(uv0.x * ST_PI * 2.0 + 1.5 * (rnd.x - 0.5)), (1.5 * exp(-uv0.y * uv0.y / 0.0225) + 0.2) * (1.0 - uv0.y)) + 0.1);
                        s += s0 * smask;
                        s -= 0.5 * uv0.y;

                        // Layer-aware weighting: finer layers contribute less, coarse layers shape the large strokes.
                        float layerT = (float)layer / max(1.0, (float)maxLayer);
                        float layerW = lerp(0.22, 1.0, pow(layerT, 0.75));

                        float3 dcol = getCol(brushPos, 1.0 + 0.35 * layerT, Res, Res0).xyz * lerp(s * 0.13 + 0.87, 1.0, smask);
                        s = saturate(s);
                        float alpha = s * step(-0.5, -abs(uv0.x - 0.5)) * step(-0.5, -abs(uv0.y - 0.5)) * layerW;
                        fragColor.rgb = lerp(fragColor.rgb, dcol, alpha);
                    }
                    pidx0 += NumX2 * NumY2;
                }

                fragColor.a = 1.0;
                return fragColor;
            }
            ENDHLSL
        }
    }
}
