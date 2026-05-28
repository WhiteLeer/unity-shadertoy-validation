Shader "Shadertoy/MtKcDG_Image"
{
    Properties
    {
        _Channel0("Channel0", 2D) = "black" {}
        _Channel2("Channel2", 2D) = "gray" {}
        _PaintSpec("PaintSpec", Float) = 0.22
        _Vignette("Vignette", Float) = 1.25
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        Pass
        {
            Name "Image"
            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            TEXTURE2D(_Channel2); SAMPLER(sampler_Channel2);

            float _PaintSpec;
            float _Vignette;
            float4 _STResolution;

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float getVal(float2 uv)
            {
                float lod = 0.5 + 0.5 * log2(max(1.0, _STResolution.x / 1920.0));
                return length(SAMPLE_TEXTURE2D_LOD(_Channel0, sampler_Channel0, uv, lod).xyz);
            }

            float2 getGrad(float2 uv, float delta)
            {
                float2 d = float2(delta, 0.0);
                return float2(
                    getVal(uv + d.xy) - getVal(uv - d.xy),
                    getVal(uv + d.yx) - getVal(uv - d.yx)
                ) / delta;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.uv * _STResolution.xy;
                float2 uv = i.uv;

                float3 n = normalize(float3(-getGrad(uv, 1.0 / _STResolution.y), 165.0));
                float3 light = normalize(float3(-1.0, 1.0, 1.4));
                float diff = saturate(dot(n, light));
                float spec = saturate(dot(reflect(light, n), float3(0, 0, -1)));
                spec = pow(spec, 12.0) * _PaintSpec;
                float sh = saturate(dot(reflect(light * float3(-1, -1, 1), n), float3(0, 0, -1)));
                sh = pow(sh, 4.0) * 0.1;

                float4 baseCol = SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, uv);
                float4 col = baseCol * lerp(diff, 1.0, 0.86) + spec * float4(0.85, 1.0, 1.15, 1.0) + sh * float4(0.85, 1.0, 1.15, 1.0);
                col.a = 1.0;

                float2 scc = (fragCoord - 0.5 * _STResolution.xy) / _STResolution.x;
                float vign = 1.1 - _Vignette * dot(scc, scc);
                vign *= 1.0 - 0.7 * _Vignette * exp(-sin(fragCoord.x / _STResolution.x * 3.1416) * 40.0);
                vign *= 1.0 - 0.7 * _Vignette * exp(-sin(fragCoord.y / _STResolution.y * 3.1416) * 20.0);
                col.rgb *= vign;
                col.rgb = pow(saturate(col.rgb), float3(1.0, 1.0, 1.0) * 0.96);

                return float4(saturate(col.rgb), 1.0);
            }
            ENDHLSL
        }
    }
}
