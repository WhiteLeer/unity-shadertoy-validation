Shader "Shadertoy/7tlyzl_ElectricBeam"
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

            #define SPEED 15.0
            #define FREQ 8.0
            #define MAX_HEIGHT 0.3
            #define THICKNESS 0.005
            #define BLOOM 0.65
            #define WOBBLE 0.1

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float Beam(float2 uv, float max_height, float offset, float speed, float freq, float thickness)
            {
                uv.y -= 0.5;
                float height = max_height * (WOBBLE + min(1.0 - uv.x, 1.0));
                float ramp = smoothstep(0.0, 2.0 / freq, uv.x);
                height *= ramp;
                uv.y += sin(uv.x * freq - _STTime * speed + offset) * height;
                float f = thickness / max(abs(uv.y), 1e-4);
                f = pow(f, BLOOM);
                return f;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 uv = i.uv;
                float f = Beam(uv, MAX_HEIGHT, 0.0, SPEED, FREQ * 1.5, THICKNESS * 0.5)
                        + Beam(uv, MAX_HEIGHT, _STTime, SPEED, FREQ, THICKNESS)
                        + Beam(uv, MAX_HEIGHT, _STTime + 0.5, SPEED + 0.2, FREQ * 0.9, THICKNESS * 0.5)
                        + Beam(uv, 0.0, 0.0, SPEED, FREQ, THICKNESS * 3.0);
                return float4(f * float3(0.5, 0.05, 0.15), 1.0);
            }
            ENDHLSL
        }
    }
}
