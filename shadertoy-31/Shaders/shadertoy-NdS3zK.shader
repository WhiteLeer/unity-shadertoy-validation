Shader "Shadertoy/NdS3zK_OceanElemental"
{
    Properties
    {
        _Channel0("Buffer A", 2D) = "black" {}
        _Channel1("Buffer B", 2D) = "gray" {}
        _Channel2("Environment Cubemap", Cube) = "" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "ForwardUnlit"
            Cull Off ZWrite Off ZTest Always
            HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS:POSITION; float2 uv:TEXCOORD0; };
            struct Varyings { float4 positionHCS:SV_POSITION; float2 uv:TEXCOORD0; float2 fragCoord:TEXCOORD1; };

            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            TEXTURE2D(_Channel1); SAMPLER(sampler_Channel1);
            TEXTURECUBE(_Channel2); SAMPLER(sampler_Channel2);
            float4 _STResolution;
            float _STTime;

            #define PI 3.14159
            #define FOUR_PI (4.0 * PI)
            #define IOR 1.333
            #define ETA (1.0 / IOR)
            #define ETA_REVERSE IOR
            #define MAX_STEPS 50
            #define MIN_DIST 0.01
            #define MAX_DIST 5.0
            #define EPSILON 1e-4
            #define DETAIL_EPSILON 2e-3
            #define DETAIL_HEIGHT 0.1
            #define DETAIL_SCALE float3(1.0, 1.0, 1.0)
            #define BLENDING_SHARPNESS float3(4.0, 4.0, 4.0)
            #define SUN_LIGHT_COLOUR float3(3.5, 3.5, 3.5)
            #define WATER_COLOUR (0.85 * float3(0.1, 0.75, 0.9))
            #define CLARITY 0.75
            #define DENSITY 3.5
            #define SUN_LOCATION -2.0
            #define SUN_HEIGHT 0.9
            #define MIN_DOT 1e-3

            float dot_c(float3 a, float3 b) { return max(dot(a, b), MIN_DOT); }
            float3 inv_gamma(float3 col) { return pow(max(col, 0.0), 2.2); }

            float3 RayDirection(float fov, float2 fragCoord)
            {
                float2 xy = fragCoord - _STResolution.xy * 0.5;
                float z = (0.5 * _STResolution.y) / tan(radians(fov) * 0.5);
                return normalize(float3(xy, -z));
            }

            float3x3 LookAt(float3 camera, float3 at, float3 up)
            {
                float3 zaxis = normalize(at - camera);
                float3 xaxis = normalize(cross(zaxis, up));
                float3 yaxis = cross(xaxis, zaxis);
                return transpose(float3x3(xaxis, yaxis, -zaxis));
            }

            float3 GetSkyColour(float3 rayDir)
            {
                float3 col = inv_gamma(SAMPLE_TEXTURECUBE(_Channel2, sampler_Channel2, rayDir).rgb);
                return col + 2.0 * col * col;
            }

            float GetGlow(float dist, float radius, float intensity)
            {
                return pow(radius / max(dist, 1e-6), intensity);
            }

            float2 IntersectAABB(float3 ro, float3 rd, float3 boxMin, float3 boxMax)
            {
                float3 safeDir = sign(rd) * max(abs(rd), 1e-5);
                float3 tMin = (boxMin - ro) / safeDir;
                float3 tMax = (boxMax - ro) / safeDir;
                float3 t1 = min(tMin, tMax);
                float3 t2 = max(tMin, tMax);
                return float2(max(max(t1.x, t1.y), t1.z), min(min(t2.x, t2.y), t2.z));
            }

            bool InsideAABB(float3 p, float3 boxMin, float3 boxMax)
            {
                float eps = 1e-4;
                return all(p > boxMin - eps) && all(p < boxMax + eps);
            }

            bool TestAABB(float3 org, float3 dir, float3 boxMin, float3 boxMax)
            {
                float2 hit = IntersectAABB(org, dir, boxMin, boxMax);
                if (InsideAABB(org, boxMin, boxMax)) hit.x = 1e-4;
                return hit.x > 0.0 && hit.x < hit.y;
            }

            float3 QuatRotate(float3 p, float4 q) { return 2.0 * cross(q.xyz, p * q.w + cross(q.xyz, p)) + p; }
            float3 RotateX(float3 p, float a) { return QuatRotate(p, float4(sin(a * 0.5), 0, 0, cos(a * 0.5))); }
            float3 RotateZ(float3 p, float a) { return QuatRotate(p, float4(0, 0, sin(a), cos(a))); }
            float SphereSDF(float3 p, float radius) { return length(p) - radius; }

            float SdRoundCone(float3 p, float r1, float r2, float h)
            {
                float2 q = float2(length(p.xz), p.y);
                float b = (r1 - r2) / h;
                float aa = sqrt(max(0.0, 1.0 - b * b));
                float k = dot(q, float2(-b, aa));
                if (k < 0.0) return length(q) - r1;
                if (k > aa * h) return length(q - float2(0.0, h)) - r2;
                return dot(q, float2(aa, b)) - r1;
            }

            float OpDisplace(float3 p)
            {
                float3 offset = 0.4 * _STTime * normalize(float3(1.0, -1.0, 0.1));
                p = 10.0 * (p + offset);
                return sin(p.x) * sin(p.y) * sin(p.z);
            }

            float OpSmoothSub(float d1, float d2, float k)
            {
                float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
                return lerp(d2, -d1, h) + k * h * (1.0 - h);
            }

            float SmoothMin(float a, float b, float k)
            {
                float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
                return lerp(b, a, h) - k * h * (1.0 - h);
            }

            float GetSDF(float3 p, float3 dir, float sdfSign)
            {
                p.y -= 0.4;
                float dist = 1e5;
                float3 q = p;

                if (TestAABB(p, dir, float3(-0.65, -1.0, -1.2), float3(0.8, 0.6, 1.2)))
                {
                    dist = SphereSDF(q, 0.5);
                    q.y -= 0.25; q.x -= 0.45; q = RotateZ(q, 0.39);
                    dist = SmoothMin(dist, SdRoundCone(q, 0.25, 0.25, 0.1), 0.25);
                    q = p; q.z = abs(q.z); q.y += 0.1; q.z -= 0.15; q = RotateX(q, -1.45);
                    dist = SmoothMin(dist, SdRoundCone(q, 0.4, 0.35, 0.4), 0.25);
                }

                if (TestAABB(p, dir, float3(-0.65, -1.5, -0.75), float3(0.8, 0.5, 0.75)))
                {
                    q = p; q.y += 0.5; q.x += 0.15; q = RotateZ(q, 1.4);
                    dist = SmoothMin(dist, SdRoundCone(q, 0.35, 0.25, 0.7), 0.5);
                }

                if (TestAABB(p, dir, float3(-1.0, -2.0, -0.75), float3(0.8, -1.0, 0.75)))
                {
                    q = p; q.y += 1.4; q.x -= 0.1; q = RotateZ(q, -1.5);
                    dist = SmoothMin(dist, SdRoundCone(q, 0.24, 2.0, 3.0), 0.25);
                    q = p; q.y += 4.75;
                    dist = OpSmoothSub(SphereSDF(q, 2.8), dist, 0.15);
                }

                if (TestAABB(p, dir, float3(-1.0, -1.25, -1.2), float3(0.8, 0.1, -0.5)) ||
                    TestAABB(p, dir, float3(-1.0, -1.25, 0.5), float3(0.8, 0.1, 1.2)))
                {
                    q = p; q.z = abs(q.z); q.z -= 0.8; q.y += 0.3; q = RotateZ(q, -1.7); q = RotateX(q, -0.2);
                    dist = SmoothMin(dist, SdRoundCone(q, 0.22, 0.2, 0.3), 0.15);
                    q = p; q.z = abs(q.z); q.z -= 0.9; q.y += 0.8; q.x -= 0.15; q = RotateZ(q, -2.0); q = RotateX(q, 0.15);
                    dist = SmoothMin(dist, SdRoundCone(q, 0.18, 0.18, 0.3), 0.1);
                    q = p; q.z = abs(q.z); q.z -= 0.77; q.y += 0.95; q.x -= 0.55; q = RotateZ(q, PI * 0.6);
                    dist = SmoothMin(dist, SdRoundCone(q, 0.1, 0.1, 0.2), 0.15);
                }

                float height = p.y + 0.4;
                float strength = lerp(0.02, 0.1, smoothstep(-0.6, -1.5, height));
                if (height < -1.5) strength = lerp(strength, 0.0, smoothstep(-1.5, -1.62, height));
                return sdfSign * (dist + strength * OpDisplace(p));
            }

            float DistanceToScene(float3 ro, float3 rd, float start, float end, float signValue)
            {
                float depth = start;
                [loop] for (int i = 0; i < MAX_STEPS; i++)
                {
                    float d = GetSDF(ro + depth * rd, rd, signValue);
                    if (d < EPSILON) return depth;
                    depth += d;
                    if (depth >= end) return end;
                }
                return depth;
            }

            float2 GetGradient(float2 uv)
            {
                float delta = 0.1;
                uv *= 0.3;
                float data = SAMPLE_TEXTURE2D(_Channel1, sampler_Channel1, uv).r;
                return float2(data - SAMPLE_TEXTURE2D(_Channel1, sampler_Channel1, uv - float2(delta, 0)).r,
                              data - SAMPLE_TEXTURE2D(_Channel1, sampler_Channel1, uv - float2(0, delta)).r);
            }

            float GetDistortedTexture(float2 uv)
            {
                float timeValue = 0.5 * _STTime + SAMPLE_TEXTURE2D(_Channel1, sampler_Channel1, 0.25 * uv).g;
                float f = frac(timeValue);
                float2 grad = GetGradient(uv);
                float2 distortion = 0.5 * grad + float2(0, -0.3);
                float a = SAMPLE_TEXTURE2D(_Channel1, sampler_Channel1, uv + f * distortion).r;
                float b = SAMPLE_TEXTURE2D(_Channel1, sampler_Channel1, uv + frac(timeValue + 0.5) * distortion).r;
                return (1.0 - length(grad)) * lerp(a, b, abs(1.0 - 2.0 * f));
            }

            float3 GetTriplanar(float3 position, float3 normal)
            {
                float2 xpos = position.zx;
                if (abs(position.z) > 0.65) xpos = lerp(xpos, float2(position.z, -position.x), smoothstep(0.0, -0.2, position.y));
                float3 axes = float3(GetDistortedTexture(position.zy), GetDistortedTexture(xpos), GetDistortedTexture(position.xy));
                float3 blending = pow(normalize(max(abs(normal), 0.00001)), BLENDING_SHARPNESS);
                blending /= max(1e-5, blending.x + blending.y + blending.z);
                float detail = dot(axes, blending);
                return float3(detail, detail, detail);
            }

            float3 GetNormal(float3 p, float3 dir, float signValue)
            {
                float3 n = 0;
                [unroll] for (int i = 0; i < 4; i++)
                {
                    float3 e = 0.5773 * (2.0 * float3(((i + 3) >> 1) & 1, (i >> 1) & 1, i & 1) - 1.0);
                    n += e * GetSDF(p + e * EPSILON, dir, signValue);
                }
                return normalize(n);
            }

            void PixarONB(float3 n, out float3 b1, out float3 b2)
            {
                float s = n.z >= 0.0 ? 1.0 : -1.0;
                float a = -1.0 / (s + n.z);
                float b = n.x * n.y * a;
                b1 = float3(1.0 + s * n.x * n.x * a, s * b, -s * n.x);
                b2 = float3(b, s + n.y * n.y * a, -n.y);
            }

            float3 GetDetailExtrusion(float3 p, float3 normal)
            {
                float detail = DETAIL_HEIGHT * length(GetTriplanar(p, normal));
                return p + (1.0 + smoothstep(0.0, -0.5, p.y)) * detail * normal;
            }

            float3 GetDetailNormal(float3 p, float3 normal)
            {
                float3 t, b;
                PixarONB(normal, t, b);
                t = normalize(t); b = normalize(b);
                float3 dt = 0, db = 0;
                [unroll] for (int i = 0; i < 2; i++)
                {
                    float s = 1.0 - 2.0 * float(i & 1);
                    dt += s * GetDetailExtrusion(p + s * t * DETAIL_EPSILON, normal);
                    db += s * GetDetailExtrusion(p + s * b * DETAIL_EPSILON, normal);
                }
                return normalize(cross(dt, db));
            }

            float Distribution(float3 n, float3 h, float roughness)
            {
                float a2 = roughness * roughness;
                float nh = dot_c(n, h);
                return a2 / (PI * pow(nh * nh * (a2 - 1.0) + 1.0, 2.0));
            }

            float Geometry(float cosTheta, float k) { return cosTheta / (cosTheta * (1.0 - k) + k); }
            float Smiths(float nv, float nl, float roughness)
            {
                float k = pow(roughness + 1.0, 2.0) / 8.0;
                return Geometry(nv, k) * Geometry(nl, k);
            }
            float3 Fresnel(float cosTheta, float3 f0) { return f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0); }

            float3 BRDF(float3 n, float3 viewDir, float3 lightDir, float3 f0, float roughness)
            {
                float3 h = normalize(viewDir + lightDir);
                float nl = dot_c(lightDir, n);
                float nv = dot_c(viewDir, n);
                float D = Distribution(n, h, roughness);
                float3 F = Fresnel(dot_c(h, viewDir), f0);
                float G = Smiths(nv, nl, roughness);
                return D * F * G / max(0.0001, 4.0 * nv * nl);
            }

            float3 GetEnvironment(float3 org, float3 rd, out float3 transmittance, out float3 halfway)
            {
                float distFar = DistanceToScene(org, rd, MIN_DIST, MAX_DIST, -1.0);
                float3 farP = org + rd * distFar;
                halfway = org + rd * distFar * 0.5;
                float3 n = GetNormal(farP, rd, -1.0);
                if (abs(n.z) < 1e-5) n.z = 1e-5;
                float3 refracted = normalize(refract(rd, n, ETA_REVERSE));
                if (dot(-rd, n) <= 0.66125) refracted = normalize(reflect(rd, n));
                float d = DENSITY * length(org - farP);
                transmittance = exp(-d * (1.0 - WATER_COLOUR));
                return GetSkyColour(refracted) * transmittance;
            }

            float HenyeyGreenstein(float g, float costh)
            {
                return (1.0 / FOUR_PI) * ((1.0 - g * g) / pow(1.0 + g * g - 2.0 * g * costh, 1.5));
            }

            float3 ShadingPBR(float3 cameraPos, float3 lightPos, float3 p, float3 n, float3 rd, float3 geoNormal)
            {
                float3 f0 = 0.02;
                float3 lightDir = normalize(lightPos - p);
                float3 result = BRDF(n, -rd, lightDir, f0, 0.1) * SUN_LIGHT_COLOUR * dot_c(n, lightDir);
                float3 transmittance;
                float3 halfway;
                float f = smoothstep(0.0, -0.5, p.y);
                result += (1.0 - f) * CLARITY * GetEnvironment(p + rd * 2.0 * EPSILON, refract(rd, n, ETA), transmittance, halfway);
                float mu = dot(refract(rd, n, ETA), lightDir);
                float phase = lerp(HenyeyGreenstein(-0.3, mu), HenyeyGreenstein(0.85, mu), 0.5);
                result += CLARITY * SUN_LIGHT_COLOUR * transmittance * phase;
                float3 reflectedCol = GetSkyColour(normalize(reflect(rd, n)));
                result = lerp(result, reflectedCol, Fresnel(dot_c(n, -rd), f0));
                float waveHeight = length(GetTriplanar(p, n));
                float e = lerp(2.0, 16.0, 1.0 - smoothstep(0.2, -1.3, p.y));
                return result + f * pow(waveHeight, e);
            }

            float3 ACESFilm(float3 x)
            {
                return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
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
                float3 rayDir = RayDirection(60.0, i.fragCoord);
                float3 cameraPos = SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, (float2(0, 1) + 0.5) / _STResolution.xy).xyz;
                float3x3 viewMatrix = LookAt(cameraPos, -cameraPos, float3(0, 1, 0));
                rayDir = normalize(mul(viewMatrix, rayDir));

                float3 lightPos = 100.0 * normalize(float3(cos(SUN_LOCATION), SUN_HEIGHT, sin(SUN_LOCATION)));
                float3 lightDir = normalize(lightPos);
                float dist = DistanceToScene(cameraPos, rayDir, MIN_DIST, MAX_DIST, 1.0);
                float3 col;

                if (dist < MAX_DIST)
                {
                    float3 position = cameraPos + rayDir * dist;
                    float3 geoNormal = GetNormal(position, rayDir, 1.0);
                    if (abs(geoNormal.z) < 1e-5) geoNormal.z = 1e-5;
                    float3 detailNormal = normalize(GetDetailNormal(position, geoNormal));
                    col = ShadingPBR(cameraPos, lightPos, position, detailNormal, rayDir, geoNormal);
                }
                else
                {
                    col = GetSkyColour(rayDir);
                    col += SUN_LIGHT_COLOUR * GetGlow(1.0 - dot(rayDir, lightDir), 0.0005, 1.0);
                }

                col = ACESFilm(col);
                col = pow(max(col, 0.0), 0.4545);
                return float4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
