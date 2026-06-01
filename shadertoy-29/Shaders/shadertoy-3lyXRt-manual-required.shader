Shader "Shadertoy/3lyXRt_ManualPortRequired"
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
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 p = i.uv;
                float grid = step(0.98, frac(p.x * 16.0)) + step(0.98, frac(p.y * 10.0));
                float3 baseCol = lerp(float3(0.08, 0.02, 0.12), float3(0.35, 0.05, 0.45), p.y);
                float3 warnCol = float3(1.0, 0.1, 0.9);
                float3 col = lerp(baseCol, warnCol, saturate(grid));
                return float4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
