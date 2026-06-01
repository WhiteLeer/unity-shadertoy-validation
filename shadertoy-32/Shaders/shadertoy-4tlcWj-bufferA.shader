Shader "Shadertoy/4tlcWj_BufferA"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "BufferA"
            Cull Off ZWrite Off ZTest Always
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS:POSITION; float2 uv:TEXCOORD0; };
            struct Varyings { float4 positionHCS:SV_POSITION; float2 uv:TEXCOORD0; float2 fragCoord:TEXCOORD1; };

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
                float2 p = floor(i.fragCoord);
                float4 col = 0.0;

                if (p.y == 0.0)
                {
                    if (p.x == 0.0) col = float4(1.0, 0.0, 0.0, 1.0);  // SSS enabled
                    if (p.x == 1.0) col = float4(0.5, 0.0, 0.0, 1.0);  // sample count
                    if (p.x == 2.0) col = float4(0.5, 0.0, 0.0, 1.0);  // sample depth
                    if (p.x == 3.0) col = float4(0.5, 0.0, 0.0, 1.0);  // ambient
                    if (p.x == 4.0) col = float4(0.5, 0.0, 0.0, 1.0);  // distortion
                    if (p.x == 5.0) col = float4(1.0, 0.0, 0.0, 1.0);  // power
                    if (p.x == 6.0) col = float4(0.2, 0.0, 0.0, 1.0);  // scale
                }
                else if (p.y == 1.0 && p.x == 7.0)
                {
                    col = float4(0.0, 1.0, 1.0, 1.0); // light color
                }

                return col;
            }
            ENDHLSL
        }
    }
}
