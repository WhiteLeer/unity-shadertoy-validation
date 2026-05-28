Shader "Shadertoy/wsXBWS_ComicBlobs"
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

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            int FK(float k)
            {
                return asint(cos(k)) ^ asint(k);
            }

            float hash21(float2 k)
            {
                int x = FK(k.x);
                int y = FK(k.y);
                int v = (x * x - y) * (y * y + x) - x;
                return (float)v / 2.14e9;
            }

            float hash31(float3 k)
            {
                float h1 = hash21(k.xy);
                return hash21(float2(h1, k.z));
            }

            float3 hash33(float3 k)
            {
                float h1 = hash31(k);
                float h2 = hash31(k * h1);
                float h3 = hash31(k * h2);
                return float3(h1, h2, h3);
            }

            float sminf(float a, float b, float k)
            {
                float h = max(k - abs(a - b), 0.0) / k;
                return min(a, b) - h * h * h * k * (1.0 / 6.0);
            }

            float3 sphercoord(float2 p)
            {
                float l1 = acos(clamp(p.x, -1.0, 1.0));
                float l2 = acos(-1.0) * p.y;
                return float3(cos(l1), sin(l1) * sin(l2), sin(l1) * cos(l2));
            }

            float3 erot(float3 p, float3 ax, float ro)
            {
                return lerp(dot(p, ax) * ax, p, cos(ro)) + sin(ro) * cross(p, ax);
            }

            float comp(float3 p, float3 ro, float t)
            {
                float3 ax = sphercoord(ro.xy);
                p.z -= t;
                p = erot(p, ax, ro.z * acos(-1.0));
                float scale = 4.0 + hash21(ro.xz) * 0.5 + 0.5;
                p = (frac(p / scale) - 0.5) * scale;
                return length(p) - 0.8;
            }

            float scene(float3 p)
            {
                float rad = 3.0 + p.z + sin(p.y / 2.0 + _Time.y) + cos(p.x / 3.0 + _Time.y * 0.9);
                float dist = 10000.0;
                [unroll]
                for (int i = 0; i < 4; i++)
                {
                    float fi = (float)(i + 1);
                    float3 rot = hash33(float3(fi, cos((float)i), sin((float)i)));
                    float d = comp(p, rot, _Time.y / 2.0 * fi);
                    dist = sminf(dist, d, 1.0);
                }
                return lerp(dist, rad, lerp(0.3, 0.8 + sin(_Time.y) * 0.2, 0.1));
            }

            float3 norm(float3 p)
            {
                float e = 0.1;
                float3 ex = float3(e, 0, 0);
                float3 ey = float3(0, e, 0);
                float3 ez = float3(0, 0, e);
                return normalize(scene(p) - float3(scene(p - ex), scene(p - ey), scene(p - ez)));
            }

            float bayer8(int2 uv)
            {
                int2 q = int2((uv.x % 8 + 8) % 8, (uv.y % 8 + 8) % 8);
                // Shadertoy sampler for this texture is vflip=true.
                q.y = 7 - q.y;
                return _Channel0.Load(int3(q, 0)).x;
            }

            float marchAO(float3 p, float3 bias, float seed)
            {
                [loop]
                for (int i = 0; i < 10; i++)
                {
                    float3 rnd = tan(hash33(float3((float)i, seed, 2.0)));
                    p += normalize(bias + rnd) * scene(p);
                }
                return sqrt(smoothstep(0.0, 2.0, scene(p)));
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.uv * _ScreenParams.xy;
                float2 uv = float2(fragCoord.x / _ScreenParams.x, fragCoord.y / _ScreenParams.y);
                uv -= 0.5;
                uv /= float2(_ScreenParams.y / _ScreenParams.x, 1.0);

                float3 cam = normalize(float3(4.0, uv));
                float3 init = float3(-50.0, 0.0, sin(_Time.y * 0.37) * 1.4);
                cam = erot(cam, float3(0, 1, 0), -0.5);
                init = erot(init, float3(0, 1, 0), -0.5);

                float3 p = init;
                bool hit = false;
                bool trig = false;
                bool outline = false;

                [loop]
                for (int k = 0; k < 500 && !hit; k++)
                {
                    float dist = scene(p);
                    if (dist < 0.08) trig = true;
                    if (trig)
                    {
                        float odist = 0.09 - dist;
                        outline = odist < dist;
                        dist = min(dist, odist);
                    }
                    hit = dist * dist < 1e-6;
                    p += dist * cam;
                }

                float3 n = norm(p);
                float3 r = reflect(cam, n);
                float2 ao = float2(0, 0);

                [loop]
                for (int a = 0; a < 8; a++)
                {
                    int2 id = (((int2)(fragCoord / 16.0 + float2(_Time.y * 10.0, _Time.y * 20.0))) % 2) * 2 - 1;
                    // GLSL: bayer(ivec2(fragCoord)+i+ivec2(i/4,0))
                    // "+ i" adds to both components in GLSL vector-scalar arithmetic.
                    float seed = bayer8((int2)fragCoord + int2(a, a) + int2(a / 4, 0));
                    ao += float2(marchAO(p + n * 0.1, r, seed), 1.0);
                }
                ao.x /= max(ao.y, 1e-5);

                float3 col = (hit && !outline) ? float3(ao.x, ao.x, ao.x) : float3(0, 0, 0);
                col = pow(smoothstep(float3(0, 0, 0), float3(1, 1, 1), sqrt(saturate(col))), float3(1.7, 1.6, 1.5));
                return float4(saturate(col), 1.0);
            }
            ENDHLSL
        }
    }
}
