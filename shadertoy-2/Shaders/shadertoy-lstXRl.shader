Shader "Shadertoy/lstXRl_RayMarchingExperiment43"
{
    Properties
    {
        _Channel0("Channel0 Cubemap", Cube) = "" {}
        _Channel1("Channel1 Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode" = "UniversalForward" }

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURECUBE(_Channel0);
            SAMPLER(sampler_Channel0);
            TEXTURE2D(_Channel1);
            SAMPLER(sampler_Channel1);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                return output;
            }

            float3 iResolution;
            float iTime;
            float4 iMouse;

            float3 mod3(float3 x, float y)
            {
                return x - y * floor(x / y);
            }

            float3 sampleChannel1(float2 uv)
            {
                return SAMPLE_TEXTURE2D_LOD(_Channel1, sampler_Channel1, uv, 0).rrr;
            }

            float3 sampleChannel0(float3 dir)
            {
                return SAMPLE_TEXTURECUBE_LOD(_Channel0, sampler_Channel0, dir, 0).rgb;
            }

            float4 displ(float3 p)
            {
                float2 g = p.xz;
                float3 col = sampleChannel1(g + iTime * 0.1);
                col = clamp(col, 0.0, 1.0);
                float dist = dot(col, float3(0.1, 0.1, 0.1));
                return float4(dist, col);
            }

            float4 mapf(float3 p, inout float dstepf)
            {
                float4 disp1 = displ(p * 0.1);
                float4 disp2 = displ(p * 0.2);
                float m = length(p);
                float me = m - 4.78 + disp1.x;
                float mi = m - 4.5 - disp1.x;
                float mk = m - 4.5 + disp2.x;
                float mei = max(-mi, me);
                if (mk < mei)
                {
                    dstepf += 0.025;
                    return float4(mk, disp2.y * float3(0.2, 0.5, 0.2));
                }
                dstepf += 0.015;
                return float4(mei, disp1.y * float3(0.5, 0.2, 0.5));
            }

            float softshadow(float3 ro, float3 rd, float mint, float tmax, inout float dstepf)
            {
                float res = 1.0;
                float t = mint;
                [loop]
                for (int i = 0; i < 16; i++)
                {
                    float h = mapf(ro + rd * t, dstepf).x;
                    res = min(res, 8.0 * h / t);
                    t += clamp(h, 0.02, 0.10);
                    if (h < 0.001 || t > tmax) break;
                }
                return clamp(res, 0.0, 1.0);
            }

            float3 calcNormal(float3 pos, inout float dstepf)
            {
                float3 eps = float3(0.03, 0.0, 0.0);
                float3 nor = float3(
                    mapf(pos + eps.xyy, dstepf).x - mapf(pos - eps.xyy, dstepf).x,
                    mapf(pos + eps.yxy, dstepf).x - mapf(pos - eps.yxy, dstepf).x,
                    mapf(pos + eps.yyx, dstepf).x - mapf(pos - eps.yyx, dstepf).x
                );
                return normalize(nor);
            }

            float calcAO(float3 pos, float3 nor, inout float dstepf)
            {
                float occ = 0.0;
                float sca = 1.0;
                [loop]
                for (int i = 0; i < 5; i++)
                {
                    float hr = 0.01 + 0.12 * i / 4.0;
                    float3 aopos = nor * hr + pos;
                    float dd = mapf(aopos, dstepf).x;
                    occ += -(dd - hr) * sca;
                    sca *= 0.95;
                }
                return clamp(1.0 - 3.0 * occ, 0.0, 1.0);
            }

            float march(float3 ro, float3 rd, float rmPrec, float maxd, float mapPrec, inout float dstepf)
            {
                float s = rmPrec;
                float so = s;
                float d = 0.0;
                [loop]
                for (int i = 0; i < 250; i++)
                {
                    if (s < rmPrec || s > maxd) break;
                    s = mapf(ro + rd * d, dstepf).x;
                    s *= (s > so ? 1.5 : 1.0);
                    so = s;
                    d += s * mapPrec;
                }
                return d;
            }

            float3 toLinearSrgb(float3 c)
            {
                return c;
            }

            void mainImage(out float4 fragColor, in float2 fragCoord)
            {
                float dstepf = 0.0;

                float time = iTime * 0.25;
                float cam_a = time;
                float cam_e = 5.52;
                float cam_d = 1.88;

                float3 camUp = float3(0.0, 1.0, 0.0);
                float3 camView = float3(0.0, 0.0, 0.0);
                float li = 0.6;
                float prec = 0.00001;
                float maxd = 50.0;
                float refl_i = 0.45;
                float refr_a = 0.7;
                float refr_i = 0.8;
                float bii = 0.35;
                float marchPrecision = 0.5;

                if (iMouse.z > 0.0) cam_e = iMouse.x / iResolution.x * 10.0;
                if (iMouse.z > 0.0) cam_d = iMouse.y / iResolution.y * 50.0;

                float2 s = iResolution.xy;
                float2 uv = (fragCoord * 2.0 - s) / s.y;

                float3 col = float3(0.0, 0.0, 0.0);

                float3 ro = float3(-sin(cam_a) * cam_d, cam_e + 1.0, cos(cam_a) * cam_d);
                float3 rov = normalize(camView - ro);
                float3 u = normalize(cross(camUp, rov));
                float3 v = cross(rov, u);
                float3 rd = normalize(rov + uv.x * u + uv.y * v);

                float b = bii;
                float d = march(ro, rd, prec, maxd, marchPrecision, dstepf);

                if (d < maxd)
                {
                    float3 p = ro + rd * d;
                    float3 n = calcNormal(p, dstepf);

                    b = li;
                    float3 reflRay = reflect(rd, n);
                    float3 refrRay = refract(rd, n, refr_a);

                    float3 cubeRefl = sampleChannel0(reflRay) * refl_i;
                    float3 cubeRefr = sampleChannel0(refrRay) * refr_i;

                    col = cubeRefl + cubeRefr + pow(b, 15.0);

                    float occ = calcAO(p, n, dstepf);
                    float3 lig = normalize(float3(-0.6, 0.7, -0.5));
                    float amb = clamp(0.5 + 0.5 * n.y, 0.0, 1.0);
                    float dif = clamp(dot(n, lig), 0.0, 1.0);
                    float bac = clamp(dot(n, normalize(float3(-lig.x, 0.0, -lig.z))), 0.0, 1.0) * clamp(1.0 - p.y, 0.0, 1.0);
                    float dom = smoothstep(-0.1, 0.1, reflRay.y);
                    float fre = pow(clamp(1.0 + dot(n, rd), 0.0, 1.0), 2.0);
                    float spe = pow(clamp(dot(reflRay, lig), 0.0, 1.0), 16.0);

                    dif *= softshadow(p, lig, 0.02, 2.5, dstepf);
                    dom *= softshadow(p, reflRay, 0.02, 2.5, dstepf);

                    float3 brdf = float3(0.0, 0.0, 0.0);
                    brdf += 1.20 * dif * float3(1.00, 0.90, 0.60);
                    brdf += 1.20 * spe * float3(1.00, 0.90, 0.60) * dif;
                    brdf += 0.30 * amb * float3(0.50, 0.70, 1.00) * occ;
                    brdf += 0.40 * dom * float3(0.50, 0.70, 1.00) * occ;
                    brdf += 0.30 * bac * float3(0.25, 0.25, 0.25) * occ;
                    brdf += 0.40 * fre * float3(1.00, 1.00, 1.00) * occ;
                    brdf += 0.02;
                    col = col * brdf;

                    col = lerp(col, float3(0.8, 0.9, 1.0), 1.0 - exp(-0.0005 * d * d));
                    col = lerp(col, mapf(p, dstepf).yzw, 0.5);
                }
                else
                {
                    b += 0.1;
                    col = sampleChannel0(rd);
                }

                fragColor = float4(col * dstepf, 1.0);
            }

            float4 Frag(Varyings input) : SV_Target
            {
                iResolution = float3(_ScreenParams.xy, 1.0);
                iTime = _Time.y;
                iMouse = float4(0.0, 0.0, 0.0, 0.0);

                float4 col = 0;
                mainImage(col, input.uv * iResolution.xy);
                return col;
            }

            ENDHLSL
        }
    }
}
