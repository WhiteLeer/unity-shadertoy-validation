Shader "Shadertoy/lllBDM_BufferB"
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
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS:POSITION; float2 uv:TEXCOORD0; };
            struct Varyings { float4 positionHCS:SV_POSITION; float2 uv:TEXCOORD0; float2 fragCoord:TEXCOORD1; };

            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            float4 _STResolution;

            Varyings Vert(Attributes i){ Varyings o; o.positionHCS=TransformObjectToHClip(i.positionOS.xyz); o.uv=i.uv; o.fragCoord=i.uv*_STResolution.xy; return o; }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.fragCoord;
                float2 pp = 1.0 / _STResolution.xy;
                float4 color = SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, fragCoord * pp);
                float3 luma = float3(0.299, 0.587, 0.114);

                float lumaNW = dot(SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, (fragCoord + float2(-1.0, -1.0)) * pp).xyz, luma);
                float lumaNE = dot(SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, (fragCoord + float2( 1.0, -1.0)) * pp).xyz, luma);
                float lumaSW = dot(SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, (fragCoord + float2(-1.0,  1.0)) * pp).xyz, luma);
                float lumaSE = dot(SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, (fragCoord + float2( 1.0,  1.0)) * pp).xyz, luma);
                float lumaM  = dot(color.xyz, luma);

                float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
                float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

                float2 dir = float2(-((lumaNW + lumaNE) - (lumaSW + lumaSE)), ((lumaNW + lumaSW) - (lumaNE + lumaSE)));
                float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * (1.0/8.0)), (1.0/128.0));
                float rcpDirMin = 2.5 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
                dir = min(float2(8.0,8.0), max(float2(-8.0,-8.0), dir * rcpDirMin)) * pp;

                float3 rgbA = 0.5 * (
                    SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, fragCoord * pp + dir * (1.0/3.0 - 0.5)).xyz +
                    SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, fragCoord * pp + dir * (2.0/3.0 - 0.5)).xyz);

                float3 rgbB = rgbA * 0.5 + 0.25 * (
                    SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, fragCoord * pp + dir * -0.5).xyz +
                    SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, fragCoord * pp + dir *  0.5).xyz);

                float lumaB = dot(rgbB, luma);
                return (lumaB < lumaMin || lumaB > lumaMax) ? float4(rgbA, color.w) : float4(rgbB, color.w);
            }
            ENDHLSL
        }
    }
}
