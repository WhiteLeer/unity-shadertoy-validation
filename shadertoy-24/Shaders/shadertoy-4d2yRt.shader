Shader "Shadertoy/4d2yRt_SynTech001"
{
    Properties
    {
        _Channel0("Channel0", 2D) = "black" {}
        _Channel1("Channel1", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "ForwardUnlit"
            Cull Off ZWrite Off ZTest Always
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct Attributes { float4 positionOS:POSITION; float2 uv:TEXCOORD0; };
            struct Varyings { float4 positionHCS:SV_POSITION; float2 uv:TEXCOORD0; };
            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            TEXTURE2D(_Channel1); SAMPLER(sampler_Channel1);
            float4 _STResolution;
            Varyings Vert(Attributes i){ Varyings o; o.positionHCS=TransformObjectToHClip(i.positionOS.xyz); o.uv=i.uv; return o; }
            float4 Frag(Varyings i):SV_Target
            {
                float2 p = i.uv;
                float2 d = float2(0.02, 0.02 * (_STResolution.y / _STResolution.x));
                float3 col = SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, p).xyz;
                float3 sum = 0.0;
                [loop]
                for (int k = -20; k <= 20; k++)
                {
                    float s = 1.0 / (1.0 + (float)(k * k));
                    float2 fk = (float)k.xx;
                    sum += SAMPLE_TEXTURE2D_LOD(_Channel1, sampler_Channel1, p + d * float2((float)k, (float)k), 0).xyz * s;
                    sum += SAMPLE_TEXTURE2D_LOD(_Channel1, sampler_Channel1, p + d * float2((float)k, -(float)k), 0).xyz * s;
                    sum += SAMPLE_TEXTURE2D_LOD(_Channel1, sampler_Channel1, p + d * float2((float)k, 0), 0).xyz * s;
                    sum += SAMPLE_TEXTURE2D_LOD(_Channel1, sampler_Channel1, p + d * float2(0, (float)k), 0).xyz * s;
                }
                col += sum / 2.5;
                col = col / (1.0 + col);
                col = sqrt(saturate(col));
                col = smoothstep(0.0, 1.0, col);
                return float4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
