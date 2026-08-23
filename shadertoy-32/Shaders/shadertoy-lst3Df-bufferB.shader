Shader "Shadertoy/lst3Df_BufferB"
{
    Properties
    {
        _SourceTex ("Source", 2D) = "black" {}
    }

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            Name "BufferB"
            HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            sampler2D _SourceTex;
            CBUFFER_START(UnityPerMaterial)
                float4 _STResolution;
                float _STTime;
                float4 _STMouse;
            CBUFFER_END

            #define BLURDIST_PX 64.0
            #define NUM_SAMPLES 16

            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.vertex.xyz);
                output.uv = input.uv;
                return output;
            }

            float3 SrgbToLin(float3 c) { return c * c; }
            float3 LinToSrgb(float3 c) { return sqrt(max(c, 0.0)); }

            float Hash12(float2 p)
            {
                p = frac(p * float2(5.3987, 5.4421));
                p += dot(p.yx, p.xy + float2(21.5351, 14.3137));
                return frac(p.x * p.y * 95.4307);
            }

            float4 Frag(Varyings input) : SV_Target
            {
                float2 uv = input.uv;
                float2 blurvec = normalize(float2(0.0, 1.0)) / _STResolution.xy;
                float sinblur = 0.55 + 0.45 * sin(5.0 * uv.x + _STTime);
                float blurdist = (_STMouse.z > 0.5) ? (100.0 * _STMouse.x / _STResolution.x) : (BLURDIST_PX * sinblur);

                float2 p0 = uv - 0.5 * blurdist * blurvec;
                float2 p1 = uv + 0.5 * blurdist * blurvec;
                float2 stepvec = (p1 - p0) / (float)NUM_SAMPLES;
                float2 p = p0 + (Hash12(uv + frac(_STTime)) - 0.5) * stepvec;

                float3 sumcol = 0.0;
                [unroll]
                for (int i = 0; i < NUM_SAMPLES; i++)
                {
                    sumcol += SrgbToLin(tex2Dlod(_SourceTex, float4(p, 0.0, -10.0)).rgb);
                    p += stepvec;
                }

                sumcol /= (float)NUM_SAMPLES;
                return float4(LinToSrgb(sumcol), 1.0);
            }
            ENDHLSL
        }
    }
}
