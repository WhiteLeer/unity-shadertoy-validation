Shader "Shadertoy/4tdyRj_ProceduralPlant"
{
    Properties
    {
        _Unused("Unused", Float) = 0
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
            #pragma target 4.0
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/unity-shadertoy-validation/Common/Shaders/ShadertoyCompat.hlsl"
            CBUFFER_START(UnityPerMaterial)
                float _Unused;
            CBUFFER_END

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            static const float ST_PI = 3.14159;
            static const float EPS = 0.00001;
            static const float EPSN = 0.001;
            static const float EPSOUT = 0.004;
            static const int STEPS = 100;

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float hash31(float3 p)
            {
                return frac(123456.789 * sin(dot(p, float3(12.34, 56.78, 91.01))));
            }

            float2x2 rot(float a)
            {
                float c = cos(a), s = sin(a);
                // Match GLSL mat2(c,-s,s,c) * vec behavior under HLSL mul(mat, vec).
                return float2x2(c, s, -s, c);
            }

            float smoothminf(float a, float b, float k)
            {
                float f = saturate(0.5 + 0.5 * (a - b) / k);
                return lerp(a, b, f) - k * f * (1.0 - f);
            }

            float smoothmaxf(float a, float b, float k) { return -smoothminf(-a, -b, k); }
            float smoothabsf(float p, float k) { return sqrt(p * p + k * k) - k; }

            float noise3(float3 p)
            {
                float3 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                float3 c = floor(p);

                float n000 = hash31(c);
                float n100 = hash31(c + float3(1,0,0));
                float n010 = hash31(c + float3(0,1,0));
                float n110 = hash31(c + float3(1,1,0));
                float n001 = hash31(c + float3(0,0,1));
                float n101 = hash31(c + float3(1,0,1));
                float n011 = hash31(c + float3(0,1,1));
                float n111 = hash31(c + float3(1,1,1));

                float x00 = lerp(n000, n100, f.x);
                float x10 = lerp(n010, n110, f.x);
                float x01 = lerp(n001, n101, f.x);
                float x11 = lerp(n011, n111, f.x);
                float y0 = lerp(x00, x10, f.y);
                float y1 = lerp(x01, x11, f.y);
                return lerp(y0, y1, f.z);
            }

            float fbm(float3 p)
            {
                float3 pos = 10.0 * p;
                float c = 0.5;
                float res = 0.0;
                [unroll(4)]
                for (int it = 0; it < 4; it++)
                {
                    pos.xy = mul(rot(2.0), pos.xy);
                    pos = pos * 2.0 + 2.0;
                    res += c * noise3(pos);
                    c *= 0.5;
                }
                return res;
            }

            float2 repeatPolar(float2 pos, float t)
            {
                float div = 2.0 * ST_PI / t;
                float a = ModGLSL(AtanGLSL(pos.x, pos.y) + div * 1000.0, div) - 0.5 * div;
                float r = length(pos);
                return r * float2(cos(a), sin(a));
            }

            float distScene(float3 pos, out int objectId, out float colorVariation)
            {
                pos.yz = mul(rot(0.5 + 0.25 * (0.5 + 0.5 * sin(0.25 * _Time.y - 0.5 * ST_PI))), pos.yz);
                pos.xz = mul(rot(0.25 * _Time.y), pos.xz);
                pos.y += 0.22;

                float f = noise3(100.0 * pos);
                float sf = smoothstep(0.4, 0.5, f);

                float dist = pos.y;
                objectId = 0;
                colorVariation = 0.0;

                float3 p = pos;
                p.y -= 0.155;
                float distPot = length(p) - 0.2;
                distPot = smoothmaxf(distPot, p.y - 0.097, 0.01);
                distPot = smoothmaxf(distPot, -(length(p) - 0.18), 0.01);
                distPot = max(distPot, -(p.y + 0.15));
                if (distPot < dist)
                {
                    dist = distPot;
                    objectId = 1;
                    float anglev = acos(clamp(p.y / 0.2, -1.0, 1.0));
                    colorVariation = 0.9 * smoothstep(0.1, 0.2, 0.5 * sin(5.0 * sin(10.0 * anglev)) + 0.3 * (f - 0.5)) + 0.1 * sf;
                }

                float distGround = max(p.y - 0.06 + 0.01 * (noise3(150.0 * p) - 0.5), length(p) - 0.18);
                if (distGround < dist)
                {
                    dist = distGround;
                    objectId = 2;
                    colorVariation = 0.0;
                }

                pos.y *= 1.0 + 0.0075 * sin(5.0 * _Time.y);
                f = noise3(100.0 * pos);
                sf = smoothstep(0.4, 0.5, f);

                p = pos;
                p.y -= 0.31;
                float radout = 0.1;
                float radin = 0.03;
                float distPlant = length(float2(length(p.xz) - radin, p.y)) - radout;

                float angleh = AtanGLSL(p.x, p.z);
                float rh = length(p.xz);
                float t = 14.0;
                float div = 2.0 * ST_PI / t;
                float qh = floor(angleh / div);
                angleh += 0.15 * p.y / radout;
                angleh = ModGLSL(angleh + div * 1000.0, div) - 0.5 * div;

                p.x = rh * cos(angleh);
                p.z = rh * sin(angleh);
                distPlant -= 0.01 * (0.5 + 0.5 * cos(t * angleh));

                float3 pr = p - float3(radin, 0.0, 0.0);
                float anglev2 = AtanGLSL(pr.x, pr.y);
                float att = abs(anglev2);
                float rv = length(pr.xy);
                float qv = floor(anglev2 / (0.5 * div));
                anglev2 = ModGLSL(anglev2 + div * 1000.0, 0.5 * div) - 0.25 * div;
                p.x = rv * cos(anglev2);
                p.y = rv * sin(anglev2);

                p -= float3(radout + 0.01, 0.0, 0.0);
                float bumpRad = max(0.001, 0.005 - 0.0025 * att * att);
                distPlant = smoothminf(distPlant, length(p) - bumpRad, 0.008);

                float3 pSpike = p - float3(bumpRad, 0.0, 0.0);
                pSpike.yz = mul(rot(1.5 * hash31(10.0 * float3(qv, qh, t))), pSpike.yz);
                pSpike = abs(pSpike);
                float spikeRad = 0.0;
                float distSpike = length(pSpike.yz) - spikeRad;
                pSpike.xz = mul(rot(0.4 + 0.075 * sin(5.0 * _Time.y)), pSpike.xz);
                pSpike.xy = mul(rot(0.4 + 0.075 * sin(5.0 * _Time.y)), pSpike.xy);
                distSpike = min(distSpike, length(pSpike.yz) - spikeRad);
                distSpike = 1.75 * smoothmaxf(distSpike, length(pSpike) - 0.0375 + 0.01 * att * att, 0.025);
                distPlant = min(distPlant, distSpike);

                if (distPlant < dist)
                {
                    dist = distPlant;
                    objectId = 3;
                    colorVariation = cos(t * angleh) * cos(t * anglev2) + 0.9 * (f - 0.5);
                    colorVariation = 0.5 + 0.5 * (smoothstep(0.5, 0.9, colorVariation) - smoothstep(0.55, 0.95, -colorVariation));
                    colorVariation = 0.8 * colorVariation + 0.2 * sf;
                }

                p = pos;
                p.y -= 0.31 + radout + 0.005;

                float3 pLayer = p;
                float radius = 0.075;
                float np = 7.0;
                pLayer.xz = repeatPolar(pLayer.xz, np);
                pLayer.xy = mul(rot(0.99 - 0.01 * sin(5.0 * _Time.y)), pLayer.xy);
                pLayer.y = abs(pLayer.y);
                pLayer.z = smoothabsf(pLayer.z, 0.01);
                float distFlower = length(pLayer - float3(0.4 * radius, -0.68 * radius, -0.67 * radius)) - radius;

                pLayer = p;
                pLayer.xz = mul(rot(ST_PI / np), pLayer.xz);
                pLayer.xz = repeatPolar(pLayer.xz, np);
                pLayer.xy = mul(rot(0.7 - 0.01 * sin(5.0 * _Time.y)), pLayer.xy);
                pLayer.y = abs(pLayer.y);
                pLayer.z = smoothabsf(pLayer.z, 0.01);
                radius = 0.09;
                distFlower = 1.3 * min(distFlower, length(pLayer - float3(0.4 * radius, -0.68 * radius, -0.67 * radius)) - radius);

                if (distFlower < dist)
                {
                    dist = distFlower;
                    objectId = 4;
                    colorVariation = smoothstep(0.0, 0.75, length(pLayer / radius));
                }

                return 0.5 * dist;
            }

            float3 getNormal(float3 p)
            {
                int o; float c;
                float nx = distScene(p + float3(EPSN,0,0), o, c) - distScene(p - float3(EPSN,0,0), o, c);
                float ny = distScene(p + float3(0,EPSN,0), o, c) - distScene(p - float3(0,EPSN,0), o, c);
                float nz = distScene(p + float3(0,0,EPSN), o, c) - distScene(p - float3(0,0,EPSN), o, c);
                return normalize(float3(nx, ny, nz));
            }

            float3 render(float2 uv)
            {
                float3 inkColor = float3(0.15, 0.25, 0.4);
                float3 col = inkColor;

                float3 eye = float3(0.0, 0.0, 5.0);
                float3 ray = normalize(float3(uv, 1.0) - eye);
                int o;
                float dist, stepv, c, prevDist;
                bool hit = false;
                float3 pos = eye;
                dist = distScene(pos, o, c);
                float outline = 1.0;

                [loop]
                for (int st = 0; st < STEPS; st++)
                {
                    stepv = (float)st;
                    prevDist = dist;
                    dist = distScene(pos, o, c);
                    if (dist > prevDist + EPS && dist < EPSOUT)
                    {
                        outline = min(outline, dist);
                    }
                    if (abs(dist) < 0.0005)
                    {
                        hit = true;
                        break;
                    }
                    pos += dist * ray;
                }
                outline /= EPSOUT;

                float3 normal = getNormal(pos);
                float f = fbm(pos);

                if (hit)
                {
                    float3 light = float3(10,5,5);
                    light.yz = mul(rot(0.5), light.yz);
                    float shine = 30.0;

                    if (o == 0) col = 1.0 - 0.025 * smoothstep(0.6, 0.2, fbm(float3(uv * 6.0, 1.0)));
                    if (o == 1) col = lerp(float3(0.63,0.63,0.85), float3(1,1,1), 0.8 * c);
                    if (o == 2) col = float3(0.6,0.6,0.6);
                    if (o == 3) { col = lerp(float3(0.3,0.7,0.6), float3(0.85,0.95,0.7), c); shine = 5.0; }
                    if (o == 4) { col = lerp(float3(0.85,0.95,0.7), float3(0.96,0.6,0.85), c); shine = 5.0; }

                    float3 l = normalize(light - pos);
                    float diff = dot(normalize(normal + 0.2 * float3(f - 0.5, f - 0.5, f - 0.5)), l);
                    diff = smoothstep(0.4, 0.5, diff + 0.3 * f);
                    if (o != 0) col = lerp(col, float3(0.1, 0.3, 0.75), 0.3 * (1.0 - diff));

                    float3 refl = reflect(-l, normal);
                    float spec = pow(saturate(dot(normalize(eye - pos), refl)), shine);
                    spec = smoothstep(0.5, 0.6, spec + 0.5 * f);
                    col += 0.01 * shine * spec;

                    outline = smoothstep(0.75, 0.95, outline + 0.9 * f);
                    col = lerp(inkColor, col, outline);
                }

                return col;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.uv * _ScreenParams.xy;
                float2 uv = (fragCoord - 0.5 * _ScreenParams.xy) / _ScreenParams.x;
                uv *= 0.8;
                float3 col = render(uv);
                return float4(saturate(col), 1.0);
            }
            ENDHLSL
        }
    }
}

