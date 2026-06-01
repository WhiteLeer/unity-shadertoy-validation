Shader "Shadertoy/dlScDt_WaterToonTorrent"
{
    Properties
    {
        _Unused("Unused", Float) = 0
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
            #include "Assets/unity-shadertoy-validation/Common/Shaders/ShadertoyCompat.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float gyroid(float3 seed)
            {
                return dot(sin(seed), cos(seed.yzx));
            }

            float fbm(float3 seed)
            {
                float result = 0.0;
                float a = 0.5;
                [loop]
                for (int it = 0; it < 6; ++it)
                {
                    seed.x += _Time.y * 0.01 / a;
                    seed.z += result * 0.5;
                    result += gyroid(seed / a) * a;
                    a *= 0.5;
                }
                return result;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 R = _ScreenParams.xy;
                float2 fragCoord = i.uv * R;
                float2 p = (2.0 * fragCoord - R) / R.y;

                float count = 2.0;
                float shades = 3.0;
                float shape = abs(fbm(float3(p * 0.5, 0.0))) - _Time.y * 0.1 - p.x * 0.1;
                float gradient = frac(shape * count + p.x);

                float3 blue = float3(0.459, 0.765, 1.0);
                float3 tint = lerp(blue * lerp(0.6, 0.8, gradient), float3(1.0, 1.0, 1.0), round(pow(gradient, 4.0) * shades) / shades);
                float3 color = lerp(tint, blue * 0.2, ModGLSL(floor(shape * count), 2.0));
                return float4(color, 1.0);
            }
            ENDHLSL
        }
    }
}
