Shader "Shadertoy/4tlcWj_SubsurfaceScattering"
{
    Properties
    {
        _Channel0("Shaded Scene", 2D) = "black" {}
        _Channel1("UI Buffer", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "ForwardUnlit"
            Cull Off ZWrite Off ZTest Always
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS:POSITION; float2 uv:TEXCOORD0; };
            struct Varyings { float4 positionHCS:SV_POSITION; float2 uv:TEXCOORD0; float2 fragCoord:TEXCOORD1; };

            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            TEXTURE2D(_Channel1); SAMPLER(sampler_Channel1);
            float4 _STResolution;

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                o.fragCoord = i.uv * _STResolution.xy;
                return o;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 uv = i.fragCoord / _STResolution.xy;
                float4 col = SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, uv);
                float4 ui = SAMPLE_TEXTURE2D(_Channel1, sampler_Channel1, uv);
                col.rgb = pow(max(col.rgb, 0.0), 1.0 / 2.2);
                col.rgb *= 0.4 + 0.6 * pow(32.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.2);
                col.rgb = lerp(col.rgb, ui.rgb, ui.a);
                return float4(col.rgb, 1.0);
            }
            ENDHLSL
        }
    }
}
