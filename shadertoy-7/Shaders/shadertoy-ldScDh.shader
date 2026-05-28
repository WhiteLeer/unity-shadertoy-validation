Shader "Shadertoy/ldScDh_GreekTemple"
{
    Properties
    {
        _Channel0("Channel0", 2D) = "black" {}
        _Channel1("Channel1", 2D) = "black" {}
        _Channel2("Channel2", 2D) = "black" {}
        _Channel3("Channel3", 2D) = "black" {}
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

            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            TEXTURE2D(_Channel1); SAMPLER(sampler_Channel1);
            TEXTURE2D(_Channel2); SAMPLER(sampler_Channel2);
            TEXTURE2D(_Channel3); SAMPLER(sampler_Channel3);

            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                return output;
            }

            float4 Frag(Varyings input) : SV_Target
            {
                float2 uv = input.uv;
                float3 col = SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, uv).rgb;
                float v = 16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
                col *= 0.8 + 0.2 * pow(saturate(v), 0.2);
                return float4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
