Shader "Shadertoy/ltGyz1_Image"
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

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            TEXTURE2D(_Channel0);
            SAMPLER(sampler_Channel0);
            float4 _STResolution;

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float4 loadPix(int2 p)
            {
                int2 clamped = clamp(p, int2(0, 0), int2((int)_STResolution.x - 1, (int)_STResolution.y - 1));
                return _Channel0.Load(int3(clamped, 0));
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.uv * _STResolution.xy;
                int2 fc = (int2)fragCoord;
                float4 fragColour = loadPix(fc);

                float weights = 0.0;
                float3 bloom = float3(0, 0, 0);
                const int kernel = 10;
                [loop]
                for (int j = -kernel; j <= kernel; j++)
                {
                    [loop]
                    for (int x = -kernel; x <= kernel; x++)
                    {
                        float w = pow(smoothstep((float)(kernel + 1), 0.0, length(float2((float)x, (float)j))), 1.0);
                        bloom += loadPix(fc + int2(x, j)).rgb * w;
                        weights += w;
                    }
                }

                fragColour.rgb += bloom * 0.3 / max(weights, 1e-5);
                fragColour.rgb = pow(fragColour.rgb, float3(1.0 / 2.2, 1.0 / 2.2, 1.0 / 2.2));
                fragColour.a = 1.0;
                return fragColour;
            }
            ENDHLSL
        }
    }
}
