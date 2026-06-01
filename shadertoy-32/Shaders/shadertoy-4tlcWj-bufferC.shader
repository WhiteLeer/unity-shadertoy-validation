Shader "Shadertoy/4tlcWj_BufferC"
{
    Properties
    {
        _Channel0("GBuffer", 2D) = "black" {}
        _Channel1("UI Buffer", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "BufferC"
            Cull Off ZWrite Off ZTest Always
            HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS:POSITION; float2 uv:TEXCOORD0; };
            struct Varyings { float4 positionHCS:SV_POSITION; float2 uv:TEXCOORD0; float2 fragCoord:TEXCOORD1; };
            struct Ray { float3 o; float3 d; };

            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            TEXTURE2D(_Channel1); SAMPLER(sampler_Channel1);
            float4 _STResolution;
            float _STTime;

            float UISlider(int id)
            {
                return SAMPLE_TEXTURE2D(_Channel1, sampler_Channel1, (float2(id, 0) + 0.5) / _STResolution.xy).r;
            }

            float3 UIColor(int id)
            {
                return SAMPLE_TEXTURE2D(_Channel1, sampler_Channel1, (float2(id, 1) + 0.5) / _STResolution.xy).rgb;
            }

            float3 UnpackNormal(uint data, uint sh)
            {
                uint mu = (1u << sh) - 1u;
                uint2 d = uint2(data, data >> sh) & mu;
                float2 v = float2(d) / float(mu);
                v = -1.0 + 2.0 * v;
                float3 nor;
                nor.z = 1.0 - abs(v.x) - abs(v.y);
                nor.xy = (nor.z >= 0.0) ? v.xy : (1.0 - abs(v.yx)) * sign(v.xy);
                return normalize(nor);
            }

            Ray RayLookAt(float2 uv, float3 o, float3 d)
            {
                float3 forward = normalize(d - o);
                float3 right = normalize(cross(forward, float3(0, 1, 0)));
                float3 up = normalize(cross(right, forward));
                uv = uv * 2.0 - 1.0;
                uv.x *= _STResolution.x / _STResolution.y;
                Ray ray;
                ray.o = o;
                ray.d = normalize(uv.x * right + uv.y * up + forward * 2.0);
                return ray;
            }

            float3 CameraPos()
            {
                return float3(6.5 * cos(_STTime * 0.25), 0.0, 6.5 * sin(_STTime * 0.25));
            }

            float Attenuation(float3 toLight)
            {
                float d = length(toLight);
                return 1.0 / (1.0 + d + d * d);
            }

            float3 Render(Ray ray, float3 norm, float depth, float surfID, float thickness)
            {
                float3 color = 0.047;
                float3 lightPos = float3(0.0, sin(_STTime) * 3.0, 0.0);
                float3 lightCol = UIColor(7);
                float sssAmbient = max(0.01, UISlider(3));
                float sssDistortion = max(0.01, UISlider(4)) * 2.0;
                float sssPower = max(0.01, UISlider(5)) * 2.0;
                float sssScale = max(0.01, UISlider(6)) * 5.0;

                if (depth < 1.0)
                {
                    if (surfID > 1.5) return lightCol + 0.9;

                    float3 position = ray.o + ray.d * depth * 10.0;
                    float3 toLight = lightPos - position;
                    float attenuation = Attenuation(toLight);

                    if (UISlider(0) < 0.5)
                    {
                        color = attenuation * lightCol * max(0.0, dot(norm, normalize(toLight)));
                    }
                    else
                    {
                        float3 toEye = -ray.d;
                        float3 sssLight = normalize(lightPos - position) + norm * sssDistortion;
                        float sssDot = pow(clamp(dot(toEye, -sssLight), 0.0, 1.0), sssPower) * sssScale;
                        float sss = (sssDot + sssAmbient) * thickness * attenuation;
                        color = lightCol * sss;
                    }
                }
                return color;
            }

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
                float2 uv = i.fragCoord / _STResolution.xy;
                float4 g = SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, uv);
                Ray ray = RayLookAt(uv, CameraPos(), float3(0.0, -0.25, 0.0));
                float3 normal = UnpackNormal(uint(round(g.a)), 14u);
                return float4(Render(ray, normal, g.r, g.b, g.g), 1.0);
            }
            ENDHLSL
        }
    }
}
