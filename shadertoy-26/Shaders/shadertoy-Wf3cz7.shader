Shader "Shadertoy/Wf3cz7_DistortedGlow"
{
    Properties { _Channel0("Channel0", 2D) = "white" {} }
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
            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            float4 _STResolution;
            float _STTime;

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float s1(float v) { return sin(v) * 0.5 + 0.5; }
            float noise(float2 p) { return SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, p).r; }

            float fbm(float2 p)
            {
                float amp = 1.0;
                float n = 0.0;
                [unroll]
                for (int i = 0; i < 6; i++)
                {
                    n += noise(p) * amp;
                    amp *= 0.5;
                    p *= 2.0;
                }
                return n;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 I = i.uv * _STResolution.xy;
                float2 R = _STResolution.xy;
                float2 uv = (I * 2.0 - R) / R.y;

                float2 disstortionSpeed = float2(0.0, 0.06);
                float disstortionScale = 0.1;
                float n = fbm(uv * disstortionScale + disstortionSpeed * _STTime);
                float2 uv3 = uv + n;
                float disstortionPower = 1.0;
                uv3 = sign(uv3) * pow(abs(uv3), disstortionPower);
                float disstortionAmount = 0.3;
                uv = lerp(uv, uv3, disstortionAmount);

                float d = max(abs(uv.y), 1e-4);
                float glow = pow(0.1 / d, 2.0);
                float3 c = float3(s1(3.0 + abs(uv.x) * 2.0 - _STTime), s1(2.0 + abs(uv.x) * 2.0 - _STTime), s1(1.0 + abs(uv.x) * 2.0 - _STTime));
                float3 col = tanh(c * glow);
                return float4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
