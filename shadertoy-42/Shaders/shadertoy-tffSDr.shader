Shader "Shadertoy/tffSDr_IridescentFibers"
{
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

            #define ST_PI 3.14159265

            CBUFFER_START(UnityPerMaterial)
                float4 _STResolution;
                float _STTime;
            CBUFFER_END

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

            float3 Palette(float t)
            {
                float3 a = float3(0.5, 0.5, 0.5);
                float3 b = float3(0.5, 0.5, 0.5);
                float3 c = float3(1.0, 1.0, 1.0);
                float3 d = float3(0.1, 0.4, 0.5);
                return a + b * cos(2.0 * ST_PI * (c * t + d));
            }

            float4 Wave(float2 uv, float amp, float freq, float phase, float thick, float3 hue)
            {
                float x = uv.x - phase;
                float y = uv.y + amp * sin(freq * x);
                float bright = smoothstep(0.0, 1.0, 1.0 - abs(y) / thick);
                return float4(bright.xxx * hue, 1.0);
            }

            float4 Frag(Varyings input) : SV_Target
            {
                float2 coord = input.uv * _STResolution.xy;
                float2 uv = (2.0 * coord - _STResolution.xy) / _STResolution.y;

                float4 color = float4(0.0, 0.0, 0.0, 1.0);
                [unroll]
                for (int i = 0; i < 10; i++)
                {
                    float layer = i * 0.1;
                    float amp = 0.25 + 0.25 * sin(_STTime + layer) * (1.0 - layer);
                    float freq = 2.0;
                    float phase = _STTime * (1.0 - layer);
                    float thick = 0.01 + 0.001 * pow(abs(uv.x), 8.0);
                    float3 hue = Palette(0.5 * uv.x + layer - 0.5 * _STTime);
                    color += Wave(uv, amp, freq, phase, thick, hue);
                }

                return saturate(color);
            }
            ENDHLSL
        }
    }
}
