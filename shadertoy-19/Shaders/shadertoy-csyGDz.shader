Shader "Shadertoy/csyGDz_ToonFlame"
{
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

            float4 _STResolution;
            float _STTime;

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            uint FK(float x)
            {
                return asuint(cos(x)) ^ asuint(x);
            }

            float hash12(float2 p)
            {
                uint x = FK(p.x);
                uint y = FK(p.y);
                uint a = x * x - y;
                uint b = y * y + x;
                int r = asint(a * b - x);
                return (float)r / 2.14e9;
            }

            float2 hash22(float2 p)
            {
                return float2(hash12(p), hash12(p * 13.321 - 114.411));
            }

            float2x2 rot(float a)
            {
                float s = sin(a), c = cos(a);
                return float2x2(c, -s, s, c);
            }

            float ball(float2 p)
            {
                float2 ii = floor(p);
                float minDist = 10000.0;
                [loop]
                for (int xi = -2; xi <= 2; xi++)
                {
                    [loop]
                    for (int yi = -2; yi <= 2; yi++)
                    {
                        float2 c = ii + float2((float)xi, (float)yi);
                        float2 h = hash22(c);
                        float r = frac(h.x + 0.6541) * 0.5 + 0.3;
                        h = mul(h, rot(_STTime * (frac(r + 0.134) * 8.0 - 4.0)));
                        minDist = min(minDist, length(p - (c + h)) - r);
                    }
                }
                return minDist;
            }

            float flame(float2 p)
            {
                float t = _STTime * 3.1415 * 0.25;
                float2 o = float2(0.0, -0.25);
                float d = 10000.0;
                [loop]
                for (int k = 0; k < 8; k++)
                {
                    float i = (float)k / 8.0;
                    float lt = frac(t + i);
                    float r = sqrt(max(0.0, 1.0 - lt)) * 0.2 * min(lt * 2.0, 1.0);
                    float2 center = float2(sin(t - lt) * (0.3 / (lt + 1.0) + 0.2), lt * lt * 0.6) - o;
                    d = min(d, (length(p - center) - r) * 10.0 * pow(2.0 - lt, 4.0));
                }
                return d;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.uv * _STResolution.xy;
                float2 uv = (fragCoord - _STResolution.xy * 0.5) / _STResolution.y;

                float d = ball(uv * 40.0 - float2(0.0, _STTime * 10.0));
                float d2 = 1.0 - ball(uv * 10.0 - float2(0.0, _STTime * 7.0));
                float fw = max(fwidth(d), 1e-4);
                float flm = d - d2 - flame(uv);
                float3 col = lerp(float3(0.05, 0.15, 0.2), float3(1.0, 0.6, 0.05), smoothstep(-fw, fw, flm));
                col = lerp(col, float3(1.0, 0.9, 0.4), smoothstep(-fw, fw, flm - 3.0));
                return float4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
