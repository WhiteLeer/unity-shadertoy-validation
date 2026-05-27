Shader "Shadertoy/4tc3DX_GloriousLine"
{
    Properties
    {
        _Unused("Unused", Float) = 0
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

            #define vec2 float2
            #define vec3 float3
            #define vec4 float4
            #define mix lerp
            #define fract frac
            #define dFdy ddy
            #define dFdx ddx

            float3 iResolution;
            float iTime;

            float repeatf(float x) { return abs(fract(x * 0.5 + 0.5) - 0.5) * 2.0; }

            float LineDistField(vec2 uv, vec2 pA, vec2 pB, vec2 thick, float rounded, float dashOn)
            {
                rounded = min(thick.y, rounded);
                vec2 mid = (pB + pA) * 0.5;
                vec2 delta = pB - pA;
                float lenD = length(delta);
                vec2 unit = delta / lenD;
                if (lenD < 0.0001) unit = vec2(1.0, 0.0);
                vec2 perp = unit.yx * vec2(-1.0, 1.0);
                float dpx = dot(unit, uv - mid);
                float dpy = dot(perp, uv - mid);
                float disty = abs(dpy) - thick.y + rounded;
                float distx = abs(dpx) - lenD * 0.5 - thick.x + rounded;

                float dist = length(vec2(max(0.0, distx), max(0.0, disty))) - rounded;
                dist = min(dist, max(distx, disty));

                float dashScale = 2.0 * thick.y;
                float dash = (repeatf(dpx / dashScale + iTime) - 0.5) * dashScale;
                dist = max(dist, dash - (1.0 - dashOn * 1.0) * 10000.0);

                return dist;
            }

            float FillLinePix(vec2 uv, vec2 pA, vec2 pB, vec2 thick, float rounded)
            {
                float scale = abs(dFdy(uv).y);
                thick = (thick * 0.5 - 0.5) * scale;
                float df = LineDistField(uv, pA, pB, thick, rounded, 0.0);
                return saturate(df / scale);
            }

            float DrawOutlinePix(vec2 uv, vec2 pA, vec2 pB, vec2 thick, float rounded, float outlineThick)
            {
                float scale = abs(dFdy(uv).y);
                thick = (thick * 0.5 - 0.5) * scale;
                rounded = (rounded * 0.5 - 0.5) * scale;
                outlineThick = (outlineThick * 0.5 - 0.5) * scale;
                float df = LineDistField(uv, pA, pB, thick, rounded, 0.0);
                return saturate((abs(df + outlineThick) - outlineThick) / scale);
            }

            float FillLine(vec2 uv, vec2 pA, vec2 pB, vec2 thick, float rounded)
            {
                float df = LineDistField(uv, pA, pB, thick, rounded, 0.0);
                return saturate(df / abs(dFdy(uv).y));
            }

            float FillLineDash(vec2 uv, vec2 pA, vec2 pB, vec2 thick, float rounded)
            {
                float df = LineDistField(uv, pA, pB, thick, rounded, 1.0);
                return saturate(df / abs(dFdy(uv).y));
            }

            float DrawOutline(vec2 uv, vec2 pA, vec2 pB, vec2 thick, float rounded, float outlineThick)
            {
                float df = LineDistField(uv, pA, pB, thick, rounded, 0.0);
                return saturate((abs(df + outlineThick) - outlineThick) / abs(dFdy(uv).y));
            }

            void DrawPoint(vec2 uv, vec2 p, inout vec3 col)
            {
                col = mix(col, vec3(1.0, 0.25, 0.25), saturate(abs(dFdy(uv).y) * 8.0 / distance(uv, p) - 4.0));
            }

            void mainImage(out vec4 fragColor, in vec2 fragCoord)
            {
                vec2 uv = fragCoord.xy / iResolution.xy;
                uv -= 0.5;
                uv.x *= iResolution.x / iResolution.y;
                uv *= 16.0;

                vec2 rotA = vec2(cos(iTime * 0.82), sin(iTime * 0.82));
                vec2 rotB = vec2(sin(iTime * 0.82), -cos(iTime * 0.82));
                vec2 pA = vec2(-4.0, 0.0) - rotA;
                vec2 pB = vec2(4.0, 0.0) + rotA;
                vec2 pC = pA + vec2(0.0, 4.0);
                vec2 pD = pB + vec2(0.0, 4.0);

                vec3 finalColor = vec3(1.0, 1.0, 1.0);

                finalColor *= FillLinePix(uv, pA, pB, vec2(1.0, 1.0), 0.0);
                finalColor *= DrawOutlinePix(uv, pA, pB, vec2(32.0, 32.0), 16.0, 1.0);
                finalColor *= DrawOutlinePix(uv, pA, pB, vec2(64.0, 64.0), 0.0, 1.0);
                finalColor *= DrawOutlinePix(uv, pA, pB, vec2(128.0, 128.0), 128.0, 8.0);
                finalColor *= FillLineDash(uv, pC, pD, vec2(0.0, 0.5), 0.0);
                finalColor *= FillLineDash(uv, pC + vec2(0.0, 2.0), pD + vec2(0.0, 2.0), vec2(0.125, 0.125), 1.0);

                finalColor *= DrawOutline(uv, (pA + pB) * 0.5 + vec2(0.0, -4.5), (pA + pB) * 0.5 + vec2(0.0, -4.5), vec2(2.0, 2.0), 2.0, 0.8);
                finalColor *= FillLine(uv, pA - vec2(4.0, 0.0), pC - vec2(4.0, 0.0) + rotA, vec2(0.125, 0.125), 1.0);
                finalColor *= FillLine(uv, pB + vec2(4.0, 0.0), pD + vec2(4.0, 0.0) - rotA, vec2(0.125, 0.125), 1.0);

                DrawPoint(uv, pA, finalColor);
                DrawPoint(uv, pB, finalColor);
                DrawPoint(uv, pC, finalColor);
                DrawPoint(uv, pD, finalColor);

                finalColor -= vec3(1.0, 1.0, 0.2) * saturate(repeatf(uv.x * 2.0) - 0.92) * 4.0;
                finalColor -= vec3(1.0, 1.0, 0.2) * saturate(repeatf(uv.y * 2.0) - 0.92) * 4.0;
                fragColor = vec4(sqrt(saturate(finalColor)), 1.0);
            }

            float4 Frag(Varyings input) : SV_Target
            {
                iResolution = float3(_ScreenParams.xy, 1.0);
                iTime = _Time.y;

                float4 col = 0;
                mainImage(col, input.uv * iResolution.xy);
                return col;
            }

            ENDHLSL
        }
    }
}
