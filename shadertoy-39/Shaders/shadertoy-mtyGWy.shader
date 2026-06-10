Shader "Shadertoy/mtyGWy_ShaderArtCodingIntroduction"
{
    Properties
    {
        _STResolution("ST Resolution", Vector) = (512,288,0.001953125,0.003472222)
        _STMouse("ST Mouse", Vector) = (0,0,0,0)
        _STTime("ST Time", Float) = 0
        _STDeltaTime("ST DeltaTime", Float) = 0
        _STFrame("ST Frame", Float) = 0
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

            CBUFFER_START(UnityPerMaterial)
                float4 _STResolution;
                float4 _STMouse;
                float _STTime;
                float _STDeltaTime;
                float _STFrame;
            CBUFFER_END

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; float2 fragCoord : TEXCOORD1; };

            float3 Palette(float t)
            {
                float3 a = float3(0.5, 0.5, 0.5);
                float3 b = float3(0.5, 0.5, 0.5);
                float3 c = float3(1.0, 1.0, 1.0);
                float3 d = float3(0.263, 0.416, 0.557);
                return a + b * cos(6.28318 * (c * t + d));
            }

            float3 RenderMain(float2 fragCoord)
            {
                float2 uv = (fragCoord * 2.0 - _STResolution.xy) / _STResolution.y;
                float2 uv0 = uv;
                float3 finalColor = 0.0.xxx;

                [unroll]
                for (int k = 0; k < 4; k++)
                {
                    float i = (float)k;
                    uv = frac(uv * 1.5) - 0.5;
                    float d = length(uv) * exp(-length(uv0));
                    float3 col = Palette(length(uv0) + i * 0.4 + _STTime * 0.4);
                    d = sin(d * 8.0 + _STTime) / 8.0;
                    d = abs(d);
                    d = pow(0.01 / d, 1.2);
                    finalColor += col * d;
                }

                return finalColor;
            }

            Varyings Vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                OUT.fragCoord = IN.uv * _STResolution.xy;
                return OUT;
            }

            half4 Frag(Varyings IN) : SV_Target
            {
                return float4(RenderMain(IN.fragCoord), 1.0);
            }
            ENDHLSL
        }
    }
}
