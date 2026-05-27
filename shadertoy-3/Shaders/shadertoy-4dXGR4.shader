Shader "Shadertoy/4dXGR4_MainSequenceStar"
{
    Properties
    {
        _Channel0("Channel0 Texture", 2D) = "white" {}
        _Channel1("Channel1 AudioTex", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode" = "UniversalForward" }

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_Channel0);
            SAMPLER(sampler_Channel0);
            TEXTURE2D(_Channel1);
            SAMPLER(sampler_Channel1);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                return output;
            }

            float3 iResolution;
            float iTime;

            float snoise(float3 uv, float res)
            {
                const float3 s = float3(1e0, 1e2, 1e4);
                uv *= res;

                float3 uv0 = floor(fmod(uv, res)) * s;
                float3 uv1 = floor(fmod(uv + float3(1.0, 1.0, 1.0), res)) * s;

                float3 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);

                float4 v = float4(
                    uv0.x + uv0.y + uv0.z,
                    uv1.x + uv0.y + uv0.z,
                    uv0.x + uv1.y + uv0.z,
                    uv1.x + uv1.y + uv0.z
                );

                float4 r = frac(sin(v * 1e-3) * 1e5);
                float r0 = lerp(lerp(r.x, r.y, f.x), lerp(r.z, r.w, f.x), f.y);

                r = frac(sin((v + uv1.z - uv0.z) * 1e-3) * 1e5);
                float r1 = lerp(lerp(r.x, r.y, f.x), lerp(r.z, r.w, f.x), f.y);

                return lerp(r0, r1, f.z) * 2.0 - 1.0;
            }

            float sampleAudio(float2 uv)
            {
                return SAMPLE_TEXTURE2D_LOD(_Channel1, sampler_Channel1, uv, 0).x;
            }

            void mainImage(out float4 fragColor, in float2 fragCoord)
            {
                float freqs0 = sampleAudio(float2(0.01, 0.25));
                float freqs1 = sampleAudio(float2(0.07, 0.25));
                float freqs2 = sampleAudio(float2(0.15, 0.25));
                float freqs3 = sampleAudio(float2(0.30, 0.25));

                float brightness = freqs1 * 0.25 + freqs2 * 0.25;
                float radius = 0.24 + brightness * 0.2;
                float invRadius = 1.0 / max(radius, 1e-4);

                float3 orange = float3(0.8, 0.65, 0.3);
                float3 orangeRed = float3(0.8, 0.35, 0.1);
                float time = iTime * 0.1;
                float aspect = iResolution.x / iResolution.y;
                float2 uv = fragCoord.xy / iResolution.xy;
                float2 p = -0.5 + uv;
                p.x *= aspect;

                float fade = pow(length(2.0 * p), 0.5);
                float fVal1 = 1.0 - fade;
                float fVal2 = 1.0 - fade;

                float angle = atan2(p.x, p.y) / 6.2832;
                float dist = length(p);
                float3 coord = float3(angle, dist, time * 0.1);

                float newTime1 = abs(snoise(coord + float3(0.0, -time * (0.35 + brightness * 0.001), time * 0.015), 15.0));
                float newTime2 = abs(snoise(coord + float3(0.0, -time * (0.15 + brightness * 0.001), time * 0.015), 45.0));

                [loop]
                for (int i = 1; i <= 7; i++)
                {
                    float power = pow(2.0, i + 1.0);
                    fVal1 += (0.5 / power) * snoise(coord + float3(0.0, -time, time * 0.2), power * 10.0 * (newTime1 + 1.0));
                    fVal2 += (0.5 / power) * snoise(coord + float3(0.0, -time, time * 0.2), power * 25.0 * (newTime2 + 1.0));
                }

                float corona = pow(fVal1 * max(1.1 - fade, 0.0), 2.0) * 50.0;
                corona += pow(fVal2 * max(1.1 - fade, 0.0), 2.0) * 50.0;
                corona *= 1.2 - newTime1;

                float3 starSphere = float3(0.0, 0.0, 0.0);

                float2 sp = -1.0 + 2.0 * uv;
                sp.x *= aspect;
                sp *= (2.0 - brightness);
                float r = dot(sp, sp);
                float f = (1.0 - sqrt(abs(1.0 - r))) / max(r, 1e-4) + brightness * 0.5;

                if (dist < radius)
                {
                    corona *= pow(dist * invRadius, 24.0);
                    float2 newUv;
                    newUv.x = sp.x * f;
                    newUv.y = sp.y * f;
                    newUv += float2(time, 0.0);

                    float3 texSample = SAMPLE_TEXTURE2D_LOD(_Channel0, sampler_Channel0, newUv, 0).rgb;
                    float uOff = texSample.g * brightness * 4.5 + time;
                    float2 starUV = newUv + float2(uOff, 0.0);
                    starSphere = SAMPLE_TEXTURE2D_LOD(_Channel0, sampler_Channel0, starUV, 0).rgb;
                }

                float starGlow = saturate(1.0 - dist * (1.0 - brightness));
                fragColor.rgb = float3(f * (0.75 + brightness * 0.3) * orange) + starSphere + corona * orange + starGlow * orangeRed;
                fragColor.a = 1.0;
            }

            float4 Frag(Varyings input) : SV_Target
            {
                iResolution = float3(_ScreenParams.xy, 1.0);
                iTime = _Time.y;

                float4 col = 0;
                mainImage(col, input.uv * iResolution.xy);
                return col;
            }

            ENDHLSL
        }
    }
}
