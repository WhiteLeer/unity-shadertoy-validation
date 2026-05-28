Shader "Shadertoy/ldScDh_BufferA"
{
    Properties
    {
        _Channel0("Channel0", 2D) = "black" {}
        _Channel1("Channel1", 2D) = "gray" {}
        _Channel2("Channel2", 2D) = "gray" {}
        _Channel3("Channel3", 2D) = "black" {}
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
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            TEXTURE2D(_Channel1); SAMPLER(sampler_Channel1);
            TEXTURE2D(_Channel2); SAMPLER(sampler_Channel2);

            float4 _STResolution;
            float _STTime;

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float3x3 setCamera(float3 ro, float3 ta, float cr)
            {
                float3 cw = normalize(ta - ro);
                float3 cp = float3(sin(cr), cos(cr), 0.0);
                float3 cu = normalize(cross(cw, cp));
                float3 cv = normalize(cross(cu, cw));
                return float3x3(cu, cv, cw);
            }

            float sdBox(float3 p, float3 b)
            {
                float3 d = abs(p) - b;
                return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
            }

            float sdRhombus2D(float2 p, float2 b)
            {
                p = abs(p);
                float h = clamp((-2.0 * (p.x * b.x - p.y * b.y) + dot(b, b)) / dot(b, b), -1.0, 1.0);
                float2 q = p - 0.5 * b * float2(1.0 - h, 1.0 + h);
                float d = length(q);
                d *= sign(p.x * b.y + p.y * b.x - b.x * b.y);
                return d;
            }

            float hash21(float2 p)
            {
                p = frac(p * float2(0.3183099, 0.3678794) + float2(0.1, 0.7));
                p *= 17.0;
                return frac(p.x * p.y * (p.x + p.y));
            }

            float noise2(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                float a = hash21(i + float2(0.0, 0.0));
                float b = hash21(i + float2(1.0, 0.0));
                float c = hash21(i + float2(0.0, 1.0));
                float d = hash21(i + float2(1.0, 1.0));
                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }

            float fbm(float2 p)
            {
                float f = 0.0;
                float a = 0.5;
                float2 q = p;
                [unroll(5)]
                for (int i = 0; i < 5; i++)
                {
                    f += a * noise2(q);
                    q = q * 2.02 + float2(13.1, 7.7);
                    a *= 0.5;
                }
                return f;
            }

            float terrainHeight(float2 xz)
            {
                float tex = SAMPLE_TEXTURE2D(_Channel2, sampler_Channel2, xz * 0.00012 + float2(0.35, 0.35)).r;
                float h = 90.0 * tex - 65.0;
                h -= 8.0 * SAMPLE_TEXTURE2D(_Channel2, sampler_Channel2, xz * 0.002).r;
                h += 12.0 * (fbm(xz * 0.0025) - 0.5);
                h = lerp(h, -7.2, 1.0 - smoothstep(16.0, 60.0, length(xz)));
                return h;
            }

            float templeSDF(float3 p)
            {
                float d = 1e5;

                // stepped podium
                d = min(d, sdBox(p - float3(0.0, -6.2, 0.0), float3(18.0, 0.65, 10.0)));
                d = min(d, sdBox(p - float3(0.0, -5.1, 0.0), float3(15.5, 0.55, 8.7)));
                d = min(d, sdBox(p - float3(0.0, -4.1, 0.0), float3(13.8, 0.45, 7.5)));

                // main floor
                d = min(d, sdBox(p - float3(0.0, -2.4, 0.0), float3(12.0, 0.45, 6.5)));

                // column rows
                [unroll(2)]
                for (int iz = 0; iz < 2; iz++)
                {
                    float z = (iz == 0) ? -5.0 : 5.0;
                    [unroll(9)]
                    for (int ix = 0; ix < 9; ix++)
                    {
                        float x = -16.0 + ix * 4.0;
                        float3 q = p - float3(x, 0.0, z);
                        float col = length(q.xz) - 0.85 + 0.04 * q.y;
                        col = max(col, abs(q.y - 0.3) - 5.3);
                        d = min(d, col);
                    }
                }
                [unroll(4)]
                for (int iz = 0; iz < 4; iz++)
                {
                    float z = -3.0 + iz * 2.0;
                    [unroll(2)]
                    for (int ix = 0; ix < 2; ix++)
                    {
                        float x = (ix == 0) ? -16.0 : 16.0;
                        float3 q = p - float3(x, 0.0, z);
                        float col = length(q.xz) - 0.85 + 0.04 * q.y;
                        col = max(col, abs(q.y - 0.3) - 5.3);
                        d = min(d, col);
                    }
                }

                // roof blocks
                d = min(d, sdBox(p - float3(0.0, 7.0, 0.0), float3(18.0, 1.0, 10.0)));
                d = min(d, sdBox(p - float3(0.0, 8.2, 0.0), float3(19.0, 0.2, 11.0)));

                // triangular pediment (approx)
                float2 yz = p.yz - float2(8.5, 0.0);
                float ped = sdRhombus2D(yz, float2(2.5, 9.0));
                ped = max(ped, abs(p.x) - 19.0);
                d = min(d, ped);

                return d;
            }

            float2 mapScene(float3 p)
            {
                float2 res = float2(1e5, 0.0);

                float h = terrainHeight(p.xz);
                float ground = (p.y - h) * 0.35;
                if (ground < res.x) res = float2(ground, 2.0);

                float t = templeSDF(p);
                if (t < res.x) res = float2(t, 1.0);

                return res;
            }

            float3 calcNormal(float3 p, float t)
            {
                float e = 0.001 * t;
                float2 h = float2(1.0, -1.0) * 0.5773;
                float3 n =
                    h.xyy * mapScene(p + h.xyy * e).x +
                    h.yyx * mapScene(p + h.yyx * e).x +
                    h.yxy * mapScene(p + h.yxy * e).x +
                    h.xxx * mapScene(p + h.xxx * e).x;
                return normalize(n);
            }

            float softShadow(float3 ro, float3 rd, float k)
            {
                float res = 1.0;
                float t = 0.03;
                [loop]
                for (int i = 0; i < 40; i++)
                {
                    float h = mapScene(ro + rd * t).x;
                    res = min(res, k * h / t);
                    t += clamp(h, 0.02, 0.4);
                    if (res < 0.001 || t > 40.0) break;
                }
                return saturate(res);
            }

            float ambientOcclusion(float3 p, float3 n)
            {
                float occ = 0.0;
                float sca = 1.0;
                [unroll(6)]
                for (int i = 1; i <= 6; i++)
                {
                    float h = 0.03 + 0.15 * i;
                    float d = mapScene(p + n * h).x;
                    occ += (h - d) * sca;
                    sca *= 0.7;
                }
                return saturate(1.0 - 1.6 * occ);
            }

            float3 skyColor(float3 rd)
            {
                float t = saturate(0.5 + 0.5 * rd.y);
                float3 col = lerp(float3(0.12, 0.14, 0.17), float3(0.42, 0.50, 0.60), t);
                float sun = pow(saturate(dot(rd, normalize(float3(0.7, 0.1, 0.4)))), 12.0);
                col += float3(1.0, 0.35, 0.08) * sun * 0.08;
                return col;
            }

            float3 materialColor(float matId, float3 p, float3 n)
            {
                if (matId < 1.5)
                {
                    float t0 = SAMPLE_TEXTURE2D(_Channel1, sampler_Channel1, p.xz * 0.03).r;
                    float t1 = SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, p.xz * 0.008).r;
                    float c = saturate(0.35 + 0.5 * t0 + 0.35 * t1);
                    return lerp(float3(0.47, 0.43, 0.38), float3(0.79, 0.74, 0.66), c);
                }

                float dirt = SAMPLE_TEXTURE2D(_Channel2, sampler_Channel2, p.xz * 0.0018).r;
                return lerp(float3(0.23, 0.21, 0.18), float3(0.43, 0.39, 0.32), dirt);
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 uv = i.uv;
                float2 p = (2.0 * uv - 1.0);
                p.y *= _STResolution.y / max(1.0, _STResolution.x);

                float time = _STTime;
                float3 ro = float3(20.0, 10.5, -36.0);
                ro += float3(1.2 * sin(time * 0.12), 0.0, 0.0);
                float3 ta = float3(0.0, 1.5, 0.0);

                float3x3 ca = setCamera(ro, ta, 0.0);
                // Avoid row/column convention pitfalls: build ray explicitly from camera basis vectors.
                float3 rd = normalize(p.x * ca[0] + p.y * ca[1] + 2.2 * ca[2]);

                float2 hit = float2(-1.0, 0.0);
                float t = 0.1;
                const float tmax = 260.0;

                [loop]
                for (int s = 0; s < 260; s++)
                {
                    float3 pos = ro + rd * t;
                    float2 h = mapScene(pos);
                    if (h.x < 0.00012 * t)
                    {
                        hit = float2(t, h.y);
                        break;
                    }
                    if (t > tmax)
                    {
                        break;
                    }
                    t += h.x;
                }

                float3 col = skyColor(rd);
                if (hit.x > 0.0)
                {
                    float3 pos = ro + rd * hit.x;
                    float3 n = calcNormal(pos, hit.x);
                    float3 lig = normalize(float3(0.7, 0.1, 0.4));

                    float dif = saturate(dot(n, lig));
                    float sha = softShadow(pos + n * 0.01, lig, 8.0);
                    float occ = ambientOcclusion(pos, n);
                    float bac = saturate(0.3 + 0.7 * dot(n, normalize(float3(-lig.x, 0.0, -lig.z))));
                    float fre = pow(saturate(1.0 + dot(n, rd)), 3.0);
                    float spe = pow(saturate(dot(reflect(rd, n), lig)), 18.0) * dif;

                    float3 mate = materialColor(hit.y, pos, n);

                    float3 light = 0.0;
                    light += 0.70 * dif * float3(1.0, 0.9, 0.65) * sha;
                    light += 0.14 * bac * float3(0.25, 0.26, 0.28) * occ;
                    light += 0.10 * fre * float3(1.0, 1.0, 1.0) * occ;
                    light += 0.12 * spe * float3(1.0, 0.92, 0.72) * sha;
                    light += 0.05;

                    col = mate * light;

                    float fog = exp(-0.00045 * hit.x * hit.x);
                    col = lerp(skyColor(rd), col, fog);
                }

                // NaN guard + soft tonemap to avoid white blowout on desktop drivers.
                if (any(col != col)) col = float3(0.0, 0.0, 0.0);
                col = max(col, 0.0);
                col = col / (1.0 + col);
                col = pow(col, 1.0 / 2.2);
                return float4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
