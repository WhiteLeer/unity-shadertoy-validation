Shader "Shadertoy/ttXSzl_Image"
{
    Properties
    {
        _Channel0("Channel0", 2D) = "black" {}
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
            #include "Assets/unity-shadertoy-validation/Common/Shaders/ShadertoyCompat.hlsl"

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

            float4 ReadBuf(float2 uv)
            {
                return SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, uv);
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 uv = i.uv;
                float2 px = 1.0 / _STResolution.xy;

                float4 id00 = ReadBuf(uv + float2(0, 0) * px);
                float4 id01 = ReadBuf(uv + float2(0, 1) * px);
                float4 id10 = ReadBuf(uv + float2(1, 0) * px);
                float4 id11 = ReadBuf(uv + float2(1, 1) * px);

                bool noLine =
                    ((int)floor(id00.a) == (int)floor(id01.a)) &&
                    ((int)floor(id10.a) == (int)floor(id11.a)) &&
                    ((int)floor(id00.a) == (int)floor(id10.a)) &&
                    (0.1 < dot(id00.xyz, id10.xyz)) &&
                    (0.1 < dot(id10.xyz, id11.xyz));

                float4 tmp = ReadBuf(uv);
                int id = (int)floor(tmp.a);
                float diffuse = frac(tmp.a);

                float3 baseColor = 0.5 * (float3((id >> 2) & 1, (id >> 1) & 1, id & 1) + 1.0);
                if (id == 0)
                {
                    diffuse = 1.0;
                    baseColor = float3(0.5, 0.7, 1.0);
                }

                int m = ((int)floor(0.5 * _STTime)) % 6;
                float3 col;
                if (m == 0)
                {
                    col = max(0.3, diffuse) * baseColor;
                }
                else if (m == 1)
                {
                    col = noLine ? float3(0.7, 0.7, 0.7) : float3(0, 0, 0);
                }
                else if (m == 2)
                {
                    col = noLine ? float3(0.7, 0.7, 0.7) + 0.3 * baseColor : float3(0, 0, 0);
                }
                else if (m == 3)
                {
                    col = noLine ? float3((diffuse < 0.2 ? 0.5 : 0.7), (diffuse < 0.2 ? 0.5 : 0.7), (diffuse < 0.2 ? 0.5 : 0.7)) + 0.3 * baseColor : float3(0, 0, 0);
                }
                else if (m == 4)
                {
                    noLine = noLine &&
                        abs(frac(id00.a) - frac(id10.a)) < 0.1 &&
                        abs(frac(id00.a) - frac(id01.a)) < 0.1 &&
                        abs(frac(id10.a) - frac(id11.a)) < 0.1 &&
                        abs(frac(id01.a) - frac(id11.a)) < 0.1;
                    float v = (diffuse < 0.2 ? 0.5 : 0.7);
                    col = noLine ? float3(v, v, v) + 0.3 * baseColor : float3(0, 0, 0);
                }
                else
                {
                    float2 fragCoord = uv * _STResolution.xy;
                    const float rasterSize = 8.0;
                    float raster = 0.2 + 0.6 * length(ModGLSL(fragCoord.xy, float2(rasterSize, rasterSize)) / rasterSize - 0.5);
                    float v = (diffuse < raster ? 0.5 : 0.7);
                    col = noLine ? float3(v, v, v) + 0.3 * baseColor : float3(0, 0, 0);
                }

                return float4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
