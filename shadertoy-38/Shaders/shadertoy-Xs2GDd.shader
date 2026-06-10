Shader "Shadertoy/Xs2GDd_Cellular"
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

            #define PI 3.14159265359

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; float2 fragCoord : TEXCOORD1; };

            float Disk(float2 r, float2 center, float radius)
            {
                return 1.0 - smoothstep(radius - 0.008, radius + 0.008, length(r - center));
            }

            float3 RenderMain(float2 fragCoord)
            {
                float3 col1 = float3(0.216, 0.471, 0.698);
                float3 col2 = float3(1.0, 0.329, 0.298);
                float3 col3 = float3(0.867, 0.910, 0.247);

                float t = _STTime * 2.0;
                float2 r = (2.0 * fragCoord - _STResolution.xy) / _STResolution.y;
                r *= 1.0 + 0.05 * sin(r.x * 5.0 + _STTime) + 0.05 * sin(r.y * 3.0 + _STTime);
                r *= 1.0 + 0.2 * length(r);

                float side = 0.5;
                float2 r2 = fmod(r, side.xx);
                if (r2.x < 0.0) r2.x += side;
                if (r2.y < 0.0) r2.y += side;
                float2 r3 = r2 - side * 0.5;
                float i = floor(r.x / side) + 2.0;
                float j = floor(r.y / side) + 4.0;
                float ii = r.x / side + 2.0;
                float jj = r.y / side + 4.0;

                float3 pix = 1.0.xxx;
                float rad;
                float disks;

                rad = 0.15 + 0.05 * sin(t + ii * jj);
                disks = Disk(r3, 0.0.xx, rad);
                pix = lerp(pix, col2, disks);

                float speed = 2.0;
                float tt = _STTime * speed + 0.1 * i + 0.08 * j;
                float stopEveryAngle = PI / 2.0;
                float stopRatio = 0.7;
                float t1 = (floor(tt) + smoothstep(0.0, 1.0 - stopRatio, frac(tt))) * stopEveryAngle;

                float x = -0.07 * cos(t1 + i);
                float y = 0.055 * (sin(t1 + j) + cos(t1 + i));
                rad = 0.1 + 0.05 * sin(t + i + j);
                disks = Disk(r3, float2(x, y), rad);
                pix = lerp(pix, col1, disks);

                rad = 0.2 + 0.05 * sin(t * (1.0 + 0.01 * i));
                disks = Disk(r3, 0.0.xx, rad);
                pix += 0.2 * col3 * disks * sin(t + i * j + i);

                pix -= smoothstep(0.3, 5.5, length(r));
                return pix;
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
