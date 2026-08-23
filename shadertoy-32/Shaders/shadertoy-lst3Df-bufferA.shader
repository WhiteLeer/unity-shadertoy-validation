Shader "Shadertoy/lst3Df_BufferA"
{
    Properties
    {
        _Tex0 ("Texture 0", 2D) = "white" {}
        _Tex1 ("Texture 1", 2D) = "white" {}
        _Tex2 ("Texture 2", 2D) = "white" {}
    }

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            Name "BufferA"
            HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            sampler2D _Tex0;
            sampler2D _Tex1;
            sampler2D _Tex2;

            CBUFFER_START(UnityPerMaterial)
                float4 _STResolution;
                float _STTime;
                float4 _STMouse;
            CBUFFER_END

            #define BLURDIST_PX 64.0
            #define NUM_SAMPLES 16
            #define THRESHOLD 0.1
            #define MULT 4.0

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

            float4 Pattern(float2 p)
            {
                float p0 = step(abs(p.x - 0.125), 0.01) * step(abs(p.y - 0.27), 0.01);
                float p1 = step(length(p - float2(0.125, 0.45)), 0.025);

                float p20 = step(length(p - float2(0.08, 0.14)), 0.0125);
                float p21 = step(length(p - float2(0.16, 0.125)), 0.0125);
                float p22 = step(length(p - float2(0.1, 0.07)), 0.0125);
                float p2 = max(p20, max(p21, p22));

                return float4(max(p0, max(p1, p2)).xxx, 1.0);
            }

            float3 SampleTex(float2 uv)
            {
                float t = frac(0.1 * _STTime);
                if (t < (1.0 / 3.0))
                {
                    return SrgbToLin(tex2Dlod(_Tex0, float4(uv, 0.0, -10.0)).rgb);
                }
                if (t < (2.0 / 3.0))
                {
                    return SrgbToLin(tex2Dlod(_Tex1, float4(uv, 0.0, -10.0)).rgb);
                }
                return SrgbToLin(tex2Dlod(_Tex2, float4(uv, 0.0, -10.0)).rgb);
            }

            float4 Frag(Varyings input) : SV_Target
            {
                float2 fragCoord = input.uv * _STResolution.xy;
                float2 blurvec = normalize(float2(1.0, 0.0)) / _STResolution.xx;

                fragCoord += 25.0 * float2(cos(_STTime), sin(_STTime));
                float2 suv = fragCoord / _STResolution.xy;
                float2 uv = fragCoord / _STResolution.xx;
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
                    if (suv.x < 0.25)
                    {
                        sumcol += Pattern(p).rgb;
                    }
                    else
                    {
                        float3 smp = (SampleTex(p) - THRESHOLD) / (1.0 - THRESHOLD);
                        sumcol += smp * smp;
                    }
                    p += stepvec;
                }

                sumcol /= (float)NUM_SAMPLES;
                sumcol = max(sumcol, 0.0);
                return float4(LinToSrgb(sumcol * MULT), 1.0);
            }
            ENDHLSL
        }
    }
}
