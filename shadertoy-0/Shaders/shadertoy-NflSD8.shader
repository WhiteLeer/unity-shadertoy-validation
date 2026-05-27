Shader "Shadertoy/NflSD8_Unimagined"
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

            float3 iResolution;
            float iTime;

            float3 mod3(float3 x, float y)
            {
                return x - y * floor(x / y);
            }

            void mainImage(out float4 O, float2 I)
            {
                float t = 0.0;
                O = float4(0.0, 0.0, 0.0, 0.0);

                [loop]
                for (int i = 0; i < 50; i++)
                {
                    float3 p = t * normalize(float3(I + I, 1.0) - float3(iResolution.x, iResolution.y, iResolution.y));
                    float4 c = cos(t * 0.15 + float4(0.0, 11.0, 33.0, 0.0));
                    float2x2 r = float2x2(c.x, c.y, c.z, c.w);
                    p.xy = mul(p.xy, r);
                    p.z -= iTime;
                    p = mod3(p, 4.0) - 2.0;

                    float v = lerp(abs(length(p) - 1.0), length(p.xz), 0.5 - 0.5 * cos(t)) + 0.01;
                    t += v * 0.3;
                    O += exp(sin(t + float4(0.0, 2.0, 4.0, 0.0))) / v;
                }

                O = tanh(O / 2e2);
            }

            float4 Frag(Varyings input) : SV_Target
            {
                iResolution = float3(_ScreenParams.xy, 1.0);
                iTime = _Time.y;

                float4 col;
                mainImage(col, input.uv * iResolution.xy);
                col.a = 1.0;
                return col;
            }

            ENDHLSL
        }
    }
}
