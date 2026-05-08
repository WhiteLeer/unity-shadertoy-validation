Shader "Shadertoy/4d2yRt_BufferB"
{
    Properties { _Channel0("Channel0", 2D) = "black" {} }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "BufferB"
            Cull Off ZWrite Off ZTest Always
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct Attributes { float4 positionOS:POSITION; float2 uv:TEXCOORD0; };
            struct Varyings { float4 positionHCS:SV_POSITION; float2 uv:TEXCOORD0; };
            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            float4 _STResolution;
            Varyings Vert(Attributes i){ Varyings o; o.positionHCS=TransformObjectToHClip(i.positionOS.xyz); o.uv=i.uv; return o; }
            float4 Frag(Varyings i):SV_Target
            {
                float2 p = i.uv;
                float2 d = float2(0.003, 0.003 * (_STResolution.y / _STResolution.x));
                float4 sum = 0.0;
                [loop]
                for (int k = -10; k <= 10; k++)
                {
                    float s = exp(-0.05 * (float)(k * k));
                    float2 uv = p + d * float2((float)k, 0);
                    float3 c = SAMPLE_TEXTURE2D_LOD(_Channel0, sampler_Channel0, uv, 0).xyz;
                    sum += float4(c, 1.0) * s;
                }
                return float4(sum.xyz / max(sum.w, 1e-4), 1.0);
            }
            ENDHLSL
        }
    }
}
