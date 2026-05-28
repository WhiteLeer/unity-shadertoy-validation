Shader "Shadertoy/ltGyz1_BufferA"
{
    Properties
    {
        _Channel1("Channel1", 2D) = "black" {}
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
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            TEXTURE2D(_Channel1);
            SAMPLER(sampler_Channel1);

            float4 _STResolution;
            float _STTime;
            float4 _STMouse;

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float hash31(float3 p)
            {
                p = frac(p * float3(0.1031, 0.11369, 0.13787));
                p += dot(p, p.yzx + 19.19);
                return frac((p.x + p.y) * p.z);
            }

            float3 hash33(float3 p)
            {
                return float3(
                    hash31(p + float3(1.0, 0.0, 0.0)),
                    hash31(p + float3(0.0, 1.0, 0.0)),
                    hash31(p + float3(0.0, 0.0, 1.0))
                );
            }

            float valueNoise3(float3 p)
            {
                float3 i = floor(p);
                float3 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);

                float n000 = hash31(i + float3(0, 0, 0));
                float n100 = hash31(i + float3(1, 0, 0));
                float n010 = hash31(i + float3(0, 1, 0));
                float n110 = hash31(i + float3(1, 1, 0));
                float n001 = hash31(i + float3(0, 0, 1));
                float n101 = hash31(i + float3(1, 0, 1));
                float n011 = hash31(i + float3(0, 1, 1));
                float n111 = hash31(i + float3(1, 1, 1));

                float x00 = lerp(n000, n100, f.x);
                float x10 = lerp(n010, n110, f.x);
                float x01 = lerp(n001, n101, f.x);
                float x11 = lerp(n011, n111, f.x);
                float y0 = lerp(x00, x10, f.y);
                float y1 = lerp(x01, x11, f.y);
                return lerp(y0, y1, f.z);
            }

            float Kapow(float3 p)
            {
                p = floor(p) + smoothstep(0.0, 1.0, frac(p));
                return valueNoise3((p + 0.5) / 2.0);
            }

            float Kaboom(float3 p)
            {
                int3 ip = (int3)floor(p);
                p = frac(p);
                float closest = 10.0;
                float randomness = 0.7;
                const int kernel = 2;

                [loop]
                for (int k = 0; k <= kernel; k++)
                {
                    [loop]
                    for (int j = 0; j <= kernel; j++)
                    {
                        [loop]
                        for (int i = 0; i <= kernel; i++)
                        {
                            float3 rand = hash33(float3(ip + int3(i, j, k)));
                            float3 dp = p - float3((float)i, (float)j, (float)k) + (float)kernel * 0.5 + (rand - 0.5) * randomness;
                            float d = length(dp);
                            closest = min(closest, d);
                        }
                    }
                }
                return closest * closest;
            }

            float Fraggaboom(float3 p, float r, float3 s)
            {
                p /= r;
                return r * ((length(p) - 1.0) * 0.8 - 0.5 * lerp(Kapow(2.0 * (p + s)), 1.0 - Kaboom(1.0 * (p + s)), 0.8));
            }

            float Badaboom(float3 p, float r, float3 s, float m)
            {
                p /= r;
                return lerp(
                    1.0 - Kapow(2.0 * (p + s)),
                    lerp(1.0 - Kaboom(1.0 * (p + s)), 1.0 - Kaboom(5.0 * (p + s)), 0.2),
                    m
                );
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.uv * _STResolution.xy;
                float2 iResolution = _STResolution.xy;
                float2 iMouse = _STMouse.xy;

                float scale = sqrt(frac(_STTime / 3.0));
                float3 uvwOffset = float3(0.0, 2.0, -1.0) * sqrt(frac(_STTime / 3.0)) * 2.4 + floor(_STTime / 3.0);

                float3 pos = float3(2.0 * (iMouse - iResolution * 0.5) / iResolution.y, -3.0);
                float3 ray = float3((fragCoord - iResolution * 0.5) / iResolution.y, 1.0);

                float3 camK = normalize(-pos);
                float3 camI = normalize(cross(float3(0, 1, 0), camK));
                float3 camJ = cross(camK, camI);
                ray = ray.x * camI + ray.y * camJ + ray.z * camK;
                ray = normalize(ray);

                float pixelSizePerMetre = length(float2(length(ddx(ray)), length(ddy(ray))));
                float t = 0.0, lastt = 0.0, h = 0.0, smallesth = 1e30, closestt = 0.0, sdf = 0.0, lastsdf = 0.0;

                [loop]
                for (int marchStep = 0; marchStep < 200; marchStep++)
                {
                    float epsilon = pixelSizePerMetre * t;
                    lastsdf = sdf;
                    sdf = Fraggaboom(pos + ray * t, scale, uvwOffset);
                    h = sdf + epsilon * 0.5;
                    if (h < epsilon) break;
                    if (h < smallesth) { closestt = t; smallesth = h; }
                    lastt = t;
                    t += h;
                }

                float epsilon2 = pixelSizePerMetre * t;
                if (h < epsilon2 * 2.0)
                {
                    t = lerp(lastt, t, (0.0 - lastsdf) / max(1e-6, (sdf - lastsdf)));
                }
                else if (t < 1e10)
                {
                    t = closestt;
                }
                else
                {
                    float3 bg = float3(0.03, 0.05, 0.07) * (1.0 - 0.6 * sin(5.0 * fragCoord.y / iResolution.y));
                    return float4(bg, 1.0);
                }

                pos = pos + ray * t;

                float d = 0.1;
                float nDotR = (Fraggaboom(pos - 0.5 * d * ray, scale, uvwOffset) - Fraggaboom(pos + 0.5 * d * ray, scale, uvwOffset)) / d;
                float rim = smoothstep(0.2, 0.05, nDotR);

                float3 col = lerp(float3(0.3, 0.04, 0.0), float3(10.0, 2.5, 1.0), rim);
                col = lerp(float3(0.99, 0.25, 0.0), col, step(0.55, Badaboom(pos, scale, uvwOffset, 0.7)));
                col = lerp(float3(0.01, 0.01, 0.01), col, step(0.42, Badaboom(pos, scale * 1.05, uvwOffset, 0.5)));

                return float4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
