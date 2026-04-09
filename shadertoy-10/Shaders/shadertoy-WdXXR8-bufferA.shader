Shader "Shadertoy/WdXXR8_BufferA"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        Pass
        {
            Name "BufferA"
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

            TEXTURE3D(_Channel0);
            SAMPLER(sampler_Channel0);

            float4 _STResolution;
            float _STTime;

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.uv * _STResolution.xy;
                float3 p = float3(fragCoord / _STResolution.xy, 0.0);
                p *= 1.68;

                p.z += SAMPLE_TEXTURE3D(_Channel0, sampler_Channel0, (p + _STTime * 0.1) * 0.3).r;

                float3 col = SAMPLE_TEXTURE3D(_Channel0, sampler_Channel0, p).rrr;
                col += SAMPLE_TEXTURE3D(_Channel0, sampler_Channel0, p * 2.0).rrr;
                col += SAMPLE_TEXTURE3D(_Channel0, sampler_Channel0, p * 4.0).rrr;
                col += SAMPLE_TEXTURE3D(_Channel0, sampler_Channel0, p * 8.0).rrr;
                col *= 0.25;

                return float4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
