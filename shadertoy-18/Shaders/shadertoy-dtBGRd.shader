Shader "Shadertoy/dtBGRd_KuwaharaMinimal"
{
    Properties
    {
        _Channel0("Channel0", 2D) = "white" {}
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
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            TEXTURE2D(_Channel0);
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

            float Gray(float3 c)
            {
                return dot(c, float3(0.299, 0.587, 0.114));
            }

            float3 SamplePix(float2 fragCoord, int ix, int iy)
            {
                float2 uv = (fragCoord + float2((float)ix, (float)iy)) / _STResolution.xy;
                return SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, uv).rgb;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.uv * _STResolution.xy;
                const int K = 3;
                float sectorSz = (float)(K * K + 2 * K + 1);

                float3 u0 = 0.0;
                float3 u1 = 0.0;
                float3 u2 = 0.0;
                float3 u3 = 0.0;

                [loop]
                for (int ix = 0; ix <= K; ix++)
                {
                    [loop]
                    for (int iy = 0; iy <= K; iy++)
                    {
                        u0 += SamplePix(fragCoord, ix - K, iy - K);
                        u1 += SamplePix(fragCoord, ix,     iy - K);
                        u2 += SamplePix(fragCoord, ix - K, iy);
                        u3 += SamplePix(fragCoord, ix,     iy);
                    }
                }

                u0 /= sectorSz;
                u1 /= sectorSz;
                u2 /= sectorSz;
                u3 /= sectorSz;

                float4 u = float4(Gray(u0), Gray(u1), Gray(u2), Gray(u3));

                float4 var = 0.0;
                [loop]
                for (int ix = 0; ix <= K; ix++)
                {
                    [loop]
                    for (int iy = 0; iy <= K; iy++)
                    {
                        float4 v = float4(
                            Gray(SamplePix(fragCoord, ix - K, iy - K)),
                            Gray(SamplePix(fragCoord, ix,     iy - K)),
                            Gray(SamplePix(fragCoord, ix - K, iy)),
                            Gray(SamplePix(fragCoord, ix,     iy))
                        ) - u;
                        var += v * v;
                    }
                }

                float m = min(var.x, min(var.y, min(var.z, var.w)));
                float3 col =
                    (m == var.x) ? u0 :
                    (m == var.y) ? u1 :
                    (m == var.z) ? u2 :
                    (m == var.w) ? u3 :
                    (u0 + u1 + u2 + u3) * 0.25;

                return float4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
