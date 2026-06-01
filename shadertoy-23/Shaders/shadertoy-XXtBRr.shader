Shader "Shadertoy/XXtBRr_BalatroSwirl"
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
            #include "Assets/unity-shadertoy-validation/Common/Shaders/ShadertoyCompat.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            float4 _STResolution;
            float _STTime;

            #define SPIN_ROTATION -2.0
            #define SPIN_SPEED 7.0
            #define OFFSET float2(0.0, 0.0)
            #define COLOUR_1 float4(0.871, 0.267, 0.231, 1.0)
            #define COLOUR_2 float4(0.0, 0.42, 0.706, 1.0)
            #define COLOUR_3 float4(0.086, 0.137, 0.145, 1.0)
            #define CONTRAST 3.5
            #define LIGTHING 0.4
            #define SPIN_AMOUNT 0.25
            #define PIXEL_FILTER 745.0
            #define SPIN_EASE 1.0
            #define PI 3.14159265359

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float4 Effect(float2 screenSize, float2 screen_coords)
            {
                float pixel_size = length(screenSize.xy) / PIXEL_FILTER;
                float2 uv = (floor(screen_coords.xy * (1.0 / pixel_size)) * pixel_size - 0.5 * screenSize.xy) / length(screenSize.xy) - OFFSET;
                float uv_len = length(uv);

                float speed = (SPIN_ROTATION * SPIN_EASE * 0.2);
                speed += 302.2;
                float new_pixel_angle = AtanGLSL(uv.y, uv.x) + speed - SPIN_EASE * 20.0 * (1.0 * SPIN_AMOUNT * uv_len + (1.0 - 1.0 * SPIN_AMOUNT));
                float2 mid = (screenSize.xy / length(screenSize.xy)) / 2.0;
                uv = float2((uv_len * cos(new_pixel_angle) + mid.x), (uv_len * sin(new_pixel_angle) + mid.y)) - mid;

                uv *= 30.0;
                speed = _STTime * SPIN_SPEED;
                float2 uv2 = float2(uv.x + uv.y, uv.x + uv.y);

                [unroll]
                for (int i = 0; i < 5; i++)
                {
                    uv2 += sin(max(uv.x, uv.y)) + uv;
                    uv += 0.5 * float2(cos(5.1123314 + 0.353 * uv2.y + speed * 0.131121), sin(uv2.x - 0.113 * speed));
                    uv -= 1.0 * cos(uv.x + uv.y) - 1.0 * sin(uv.x * 0.711 - uv.y);
                }

                float contrast_mod = (0.25 * CONTRAST + 0.5 * SPIN_AMOUNT + 1.2);
                float paint_res = min(2.0, max(0.0, length(uv) * 0.035 * contrast_mod));
                float c1p = max(0.0, 1.0 - contrast_mod * abs(1.0 - paint_res));
                float c2p = max(0.0, 1.0 - contrast_mod * abs(paint_res));
                float c3p = 1.0 - min(1.0, c1p + c2p);
                float light = (LIGTHING - 0.2) * max(c1p * 5.0 - 4.0, 0.0) + LIGTHING * max(c2p * 5.0 - 4.0, 0.0);
                return (0.3 / CONTRAST) * COLOUR_1 + (1.0 - 0.3 / CONTRAST) * (COLOUR_1 * c1p + COLOUR_2 * c2p + float4(c3p * COLOUR_3.rgb, c3p * COLOUR_1.a)) + light;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.uv * _STResolution.xy;
                return Effect(_STResolution.xy, fragCoord);
            }
            ENDHLSL
        }
    }
}
