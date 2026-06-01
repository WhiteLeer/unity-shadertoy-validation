Shader "Shadertoy/lllBDM_Goo"
{
    Properties { _Channel0("Channel0", 2D) = "black" {} }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "ForwardUnlit"
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
            float _STTime;

            static const float W = 1.2;
            static const float T2 = 7.5;
            static const int N = 8;

            float hash1(float c){ return frac(sin(c*12.9898)*43758.5453); }
            float filmic_reinhard_curve(float x){ float q = (T2*T2 + 1.0)*x*x; return q/(q+x+T2*T2); }
            float3 filmic_reinhard(float3 x){ float w = filmic_reinhard_curve(W); return float3(filmic_reinhard_curve(x.r),filmic_reinhard_curve(x.g),filmic_reinhard_curve(x.b))/w; }

            float3 ca(float2 UV)
            {
                float2 uv = 1.0 - 2.0*UV;
                float3 c = 0;
                float rf = 1.0, gf = 1.0, bf = 1.0;
                float f = 1.0/float(N);
                [unroll] for(int i=0;i<N;i++)
                {
                    c.r += f*SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, 0.5 - 0.5*(uv*rf)).r;
                    c.g += f*SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, 0.5 - 0.5*(uv*gf)).g;
                    c.b += f*SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, 0.5 - 0.5*(uv*bf)).b;
                    rf *= 0.9972;
                    gf *= 0.998;
                    bf /= 0.9988;
                    c = clamp(c, 0.0, 1.0);
                }
                return c;
            }

            Varyings Vert(Attributes i){ Varyings o; o.positionHCS=TransformObjectToHClip(i.positionOS.xyz); o.uv=i.uv; o.fragCoord=i.uv*_STResolution.xy; return o; }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.fragCoord;
                float2 pp = fragCoord / _STResolution.xy;
                float2 p = 1.0 - 2.0*fragCoord / _STResolution.xy;
                p.y *= _STResolution.y / _STResolution.x;

                float3 color = ca(pp);
                float vignette = 1.25 / (1.1 + 1.1*dot(p,p));
                vignette *= vignette;
                vignette = lerp(1.0, smoothstep(0.1, 1.1, vignette), 0.25);
                float noise = 0.012 * hash1(length(p)*_STTime);
                color = color*vignette + noise;
                color = filmic_reinhard(color);
                color = smoothstep(-0.025, 1.0, color);
                color = pow(color, 1.0/2.2);
                return float4(color,1);
            }
            ENDHLSL
        }
    }
}
