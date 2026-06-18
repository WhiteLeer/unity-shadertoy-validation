Shader "Shadertoy/XdB3DG_AnisotropicHighlights"
{
    Properties
    {
        _Channel0 ("Channel 0", 2D) = "white" {}
        _Channel1 ("Channel 1", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode"="SRPDefaultUnlit" }
            HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _ChannelResolution0;
                float4 _ChannelResolution1;
                float4 _STResolution;
                float _STTime;
                float4 _STMouse;
            CBUFFER_END

            sampler2D _Channel0;
            sampler2D _Channel1;

            static const float traceStart = 0.1;
            static const float traceEnd = 40.0;

            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.vertex.xyz);
                output.uv = input.uv;
                return output;
            }

            float2 Noise(float3 x)
            {
                float3 p = floor(x);
                float3 f = frac(x);
                f = f * f * (3.0 - 2.0 * f);
                float2 uv = (p.xy + float2(37.0, 17.0) * p.z) + f.xy;
                float4 rg = tex2Dlod(_Channel0, float4((uv + 0.5) / 256.0, 0.0, 0.0));
                return lerp(rg.yw, rg.xz, f.z);
            }

            float DistanceField(float3 pos)
            {
                float p = 16.0;
                pos = pow(abs(pos), (p / 2.0).xxx);
                return pow(dot(pos, pos), 1.0 / p) - 1.0;
            }

            float3 Sky(float3 ray)
            {
                return lerp(float3(0.8, 0.8, 0.8), float3(0.0, 0.0, 0.0), exp2(-(1.0 / max(ray.y, 0.01)) * float3(0.4, 0.6, 1.0)));
            }

            float3 Shade(float3 pos, float3 ray, float3 normal, float3 lightDir, float3 lightCol)
            {
                float ndotl = dot(normal, lightDir);
                float3 light = lightCol * max(0.0, ndotl);
                light += lerp(float3(0.01, 0.04, 0.08), 0.1.xxx, (-normal.y + 1.0));

                float3 h = normalize(lightDir - ray);

                float3 coord = pos * 0.6 + _STTime * float3(0.0, 0.0, 0.0);
                coord.xy = coord.xy * 0.7071 + coord.yx * 0.7071 * float2(1.0, -1.0);
                coord.xz = coord.xz * 0.7071 + coord.zx * 0.7071 * float2(1.0, -1.0);
                float3 aniso = float3(Noise(coord), Noise(coord.yzx).x) * 2.0 - 1.0;
                aniso -= normal * dot(aniso, normal);

                float anisotropy = min(1.0, length(aniso));
                aniso /= max(anisotropy, 1e-5);
                anisotropy = 0.8;

                float ah = abs(dot(h, aniso));
                float nh = max(0.0, dot(normal, h));

                float q = exp2((1.0 - anisotropy) * 3.0);
                nh = pow(nh, q * 10.0);
                nh *= pow(1.0 - ah * anisotropy, 16.0);
                float3 specular = lightCol * nh * exp2((1.0 - anisotropy) * 1.0);
                specular *= smoothstep(0.0, 0.5, ndotl);

                float3 reflection = Sky(reflect(ray, normal));
                float fresnel = pow(1.0 + dot(normal, ray), 5.0);
                fresnel = lerp(0.0, 0.2, fresnel);

                return lerp(light * 0.1.xxx, reflection, fresnel) + specular;
            }

            float Trace(float3 pos, float3 ray)
            {
                float t = traceStart;
                float h = 0.0;
                [loop]
                for (int i = 0; i < 60; i++)
                {
                    h = DistanceField(pos + t * ray);
                    if (h < 0.001)
                    {
                        break;
                    }
                    t += h;
                }

                if (t > traceEnd)
                {
                    return 0.0;
                }
                return t;
            }

            float3 NormalAt(float3 pos, float3 ray)
            {
                float2 delta = float2(0.0, 0.001);
                float3 grad;
                grad.x = DistanceField(pos + delta.yxx) - DistanceField(pos - delta.yxx);
                grad.y = DistanceField(pos + delta.xyx) - DistanceField(pos - delta.xyx);
                grad.z = DistanceField(pos + delta.xxy) - DistanceField(pos - delta.xxy);
                float gdr = dot(grad, ray);
                grad -= max(0.0, gdr) * ray;
                return normalize(grad);
            }

            float3 RayDir(float zoom, float2 fragCoord)
            {
                return float3(fragCoord.xy - _STResolution.xy * 0.5, _STResolution.x * zoom);
            }

            float3 RotateRay(inout float3 v, float2 a)
            {
                float4 cs = float4(cos(a.x), sin(a.x), cos(a.y), sin(a.y));
                v.yz = v.yz * cs.x + v.zy * cs.y * float2(-1.0, 1.0);
                v.xz = v.xz * cs.z + v.zx * cs.w * float2(1.0, -1.0);

                float3 p;
                p.xz = float2(-cs.w, -cs.z) * cs.x;
                p.y = cs.y;
                return p;
            }

            void BarrelDistortion(inout float3 ray, float degree)
            {
                ray.z /= degree;
                ray.z = ray.z * ray.z - dot(ray.xy, ray.xy);
                ray.z = degree * sqrt(max(ray.z, 0.0));
            }

            float3 LensFlare(float3 ray, float3 light, float2 fragCoord)
            {
                float2 dirtuv = fragCoord.xy / _STResolution.x;
                float dirt = 1.0 - tex2D(_Channel1, dirtuv).r;
                float l = max(0.0, dot(light, ray));
                return (pow(l, 20.0) * dirt * 0.1 + pow(l, 100.0)) * float3(1.05, 1.0, 0.95);
            }

            float4 Frag(Varyings input) : SV_Target
            {
                float2 fragCoord = input.uv * _STResolution.xy;
                float3 ray = RayDir(1.0, fragCoord);
                BarrelDistortion(ray, 0.5);
                ray = normalize(ray);
                float3 localRay = ray;

                float2 mouseNorm = _STMouse.yx / max(_STResolution.yx, 1.0.xx) - 0.5;
                float3 pos = 6.0 * RotateRay(ray, float2(0.4, _STTime * 0.1 + 0.5) + float2(1.6, -6.3) * mouseNorm);

                float3 col;
                float3 lightDir = normalize(float3(3.0, 2.0, -1.0));

                float t = Trace(pos, ray);
                if (t > 0.0)
                {
                    float3 p = pos + ray * t;
                    float s = Trace(p, lightDir);
                    float3 n = NormalAt(p, ray);
                    col = Shade(p, ray, n, lightDir, (s > 0.0) ? 0.0.xxx : float3(0.98, 0.95, 0.92));
                    col = lerp(0.8.xxx, col, exp2(-t * float3(0.4, 0.6, 1.0) / 100.0));
                }
                else
                {
                    col = Sky(ray);
                }

                float sun = Trace(pos, lightDir);
                if (sun == 0.0)
                {
                    col += LensFlare(ray, lightDir, fragCoord);
                }

                col *= smoothstep(0.5, 0.0, dot(localRay.xy, localRay.xy));

                float3 c = col - 1.0;
                c = sqrt(c * c + 0.01);
                col = lerp(col, 1.0.xxx - c, 0.48);

                float2 grainuv = fragCoord.xy + floor(_STTime * 60.0) * float2(37.0, 41.0);
                float2 filmNoise = tex2D(_Channel0, 0.5 * grainuv / max(_ChannelResolution0.xy, 1.0.xx)).rb;
                col *= lerp(1.0.xxx, lerp(float3(1.0, 0.5, 0.0), float3(0.0, 0.5, 1.0), filmNoise.x), 0.1 * filmNoise.y);

                return float4(pow(max(col, 0.0), (1.0 / 2.6).xxx), 1.0);
            }
            ENDHLSL
        }
    }
}
