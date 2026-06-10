Shader "Shadertoy/XdlSDs_TotalNoob"
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

            float3 RenderMain(float2 fragCoord)
            {
                float2 p = (2.0 * fragCoord - _STResolution.xy) / _STResolution.y;
                const float tau = 6.283185307;
                float a = atan2(p.x, p.y);
                float r = length(p) * 0.75;
                float2 uv = float2(a / tau, r);

                float xCol = (uv.x - (_STTime / 3.0)) * 3.0;
                xCol = fmod(xCol, 3.0);
                if (xCol < 0.0) xCol += 3.0;

                float3 horColour = float3(0.25, 0.25, 0.25);
                if (xCol < 1.0)
                {
                    horColour.r += 1.0 - xCol;
                    horColour.g += xCol;
                }
                else if (xCol < 2.0)
                {
                    xCol -= 1.0;
                    horColour.g += 1.0 - xCol;
                    horColour.b += xCol;
                }
                else
                {
                    xCol -= 2.0;
                    horColour.b += 1.0 - xCol;
                    horColour.r += xCol;
                }

                uv = (2.0 * uv) - 1.0;
                float bandCount = clamp(floor(5.0 + 10.0 * cos(_STTime)), 0.0, 10.0);
                float beamWidth = (0.7 + 0.5 * cos(uv.x * 10.0 * tau * 0.15 * bandCount)) * abs(1.0 / (30.0 * uv.y));
                float3 horBeam = beamWidth.xxx;
                return horBeam * horColour;
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
