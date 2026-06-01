Shader "Shadertoy/McjBzK_PixelScan"
{
    Properties { _Channel0("Channel0", 2D) = "white" {} }
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
            #include "Assets/unity-shadertoy-validation/Common/Shaders/ShadertoyCompat.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            float4 _STResolution;
            float _STTime;

            #define MODE 0
            #define LAYERS 5.0
            #define SPEED 1.0
            #define DELAY 0.0
            #define WIDTH 0.05
            #define W WIDTH
            #define MAX_LAYERS 32.0

            float dir = 1.0;

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float4 readTex(float2 uv)
            {
                if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return 0.0;
                return SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, uv);
            }

            float hash(float2 p) { return frac(sin(dot(p, float2(4859.0, 3985.0))) * 3984.0); }

            float3 hsv2rgb(float3 c)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }

            float sdBox(float2 p, float r)
            {
                float2 q = abs(p) - r;
                return min(length(q), max(q.y, q.x));
            }

            float toRangeT(float2 p, float scale)
            {
                float d = p.x / (scale * 2.0) + 0.5;
                d = dir > 0.0 ? d : (1.0 - d);
                return d;
            }

            float4 cell(float2 p, float2 pi, float scale, float t, float edge)
            {
                float2 pc = pi + 0.5;
                float2 uvc = pc / scale;
                uvc.y /= (_STResolution.y / _STResolution.x);
                uvc = uvc * 0.5 + 0.5;
                if (uvc.x < 0.0 || uvc.x > 1.0 || uvc.y < 0.0 || uvc.y > 1.0) return 0.0;
                float alpha = smoothstep(0.0, 0.1, SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, uvc).a);
                float4 color = float4(hsv2rgb(float3((pc.x * 13.0 / max(pc.y, 1e-4) * 17.0) * 0.3, 1.0, 1.0)), 1.0);
                float x = toRangeT(pi, scale);
                float n = hash(pi);
                float anim = smoothstep(W * 2.0, 0.0, abs(x + n * W - t));
                color *= anim;
                color *= lerp(1.0, clamp(0.3 / max(abs(sdBox(p - pc, 0.5)), 1e-4), 0.0, 10.0), edge * pow(anim, 10.0));
                return color * alpha;
            }

            float4 cellsColor(float2 p, float scale, float t)
            {
                float2 pi = floor(p);
                float2 d = float2(0.0, 1.0);
                float4 cc = 0.0;
                cc += cell(p, pi, scale, t, 0.2) * 4.0;
                cc += cell(p, pi + d.xy, scale, t, 0.9);
                cc += cell(p, pi - d.xy, scale, t, 0.9);
                cc += cell(p, pi + d.yx, scale, t, 0.9);
                cc += cell(p, pi - d.yx, scale, t, 0.9);
                return cc / 8.0;
            }

            float4 draw(float2 uv, float2 p, float t, float scale)
            {
                float4 c = readTex(uv);
                float2 pi = floor(p * scale);
                float n = hash(pi);
                t = t * (1.0 + W * 4.0) - W * 2.0;
                float x = toRangeT(pi, scale);
                float a1 = smoothstep(t, t - W, x + n * W);
                c *= a1;
                c += cellsColor(p * scale, scale, t) * 1.5;
                return c;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 uv = i.uv;
                float2 p = uv * 2.0 - 1.0;
                p.y *= _STResolution.y / _STResolution.x;

                float transitionDuration = 2.0;
                float t = ModGLSL(_STTime / transitionDuration, 2.0);
                if (t > 1.0) { t = 2.0 - t; dir = -1.0; }
                else { dir = 1.0; }
                t = clamp((t - DELAY) * SPEED, 0.0, 1.0);
                t = (frac(t * 0.99999) - 0.5) * dir + 0.5;

                float4 finalColor = 0.0;
                float layerCount = 0.0;
                [loop]
                for (int k = 0; k < 32; k++)
                {
                    float fi = (float)k;
                    if (fi >= LAYERS) break;
                    float s = cos(fi) * 7.3 + 10.0;
                    finalColor += draw(uv, p, t, abs(s));
                    layerCount += 1.0;
                }
                float4 fragColor = finalColor / max(layerCount, 1e-4);
                fragColor *= smoothstep(0.0, 0.01, t);
                return fragColor;
            }
            ENDHLSL
        }
    }
}
