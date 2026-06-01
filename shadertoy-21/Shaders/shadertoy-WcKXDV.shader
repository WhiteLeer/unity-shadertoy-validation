Shader "Shadertoy/WcKXDV_Accretion"
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
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/unity-shadertoy-validation/Common/Shaders/ShadertoyCompat.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

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
                float2 I = i.uv * _STResolution.xy;
                float4 O = 0.0;
                float z = 0.0;
                float d = 0.0;

                [loop]
                for (int it = 0; it < 20; it++)
                {
                    float fi = (float)it + 1.0;

                    float3 p = z * normalize(float3(I + I, 0.0) - float3(_STResolution.x, _STResolution.y, _STResolution.x)) + 0.1;
                    p = float3(AtanGLSL(p.y / 0.2, p.x) * 2.0, p.z / 3.0, length(p.xy) - 5.0 - z * 0.2);

                    [loop]
                    for (int jt = 1; jt <= 7; jt++)
                    {
                        float fd = (float)jt;
                        p += sin(p.yzx * fd + _STTime + 0.3 * fi) / fd;
                        d = fd;
                    }

                    z += d = length(float4(0.4 * cos(p) - 0.4, p.z));
                    O += (1.0 + cos(p.x + fi * 0.4 + z + float4(6.0, 1.0, 2.0, 0.0))) / max(d, 1e-4);
                }

                O = tanh(O * O / 400.0);
                O.a = 1.0;
                return O;
            }
            ENDHLSL
        }
    }
}
