Shader "Shadertoy/4tlcWj_BufferB"
{
    Properties { _Channel0("UI Buffer", 2D) = "black" {} }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "BufferB"
            Cull Off ZWrite Off ZTest Always
            HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #define EPSILON 0.001
            #define NEAR_CLIP EPSILON
            #define FAR_CLIP 10.0
            #define MAX_STEPS 100
            #define PI 3.14159265359

            struct Attributes { float4 positionOS:POSITION; float2 uv:TEXCOORD0; };
            struct Varyings { float4 positionHCS:SV_POSITION; float2 uv:TEXCOORD0; float2 fragCoord:TEXCOORD1; };
            struct Ray { float3 o; float3 d; };

            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            float4 _STResolution;
            float _STTime;

            float UISlider(int id)
            {
                return SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, (float2(id, 0) + 0.5) / _STResolution.xy).r;
            }

            uint PackNormal(float3 nor, uint sh)
            {
                nor /= (abs(nor.x) + abs(nor.y) + abs(nor.z));
                nor.xy = (nor.z >= 0.0) ? nor.xy : (1.0 - abs(nor.yx)) * sign(nor.xy);
                float2 v = 0.5 + 0.5 * nor.xy;
                uint mu = (1u << sh) - 1u;
                uint2 d = uint2(floor(v * float(mu) + 0.5));
                return (d.y << sh) | d.x;
            }

            float3 MirrorVector(float3 v, float3 n)
            {
                return v + 2.0 * n * max(0.0, -dot(n, v));
            }

            float Hash11(float p)
            {
                float3 p3 = frac(float3(p, p, p) * 443.897);
                p3 += dot(p3, p3.yzx + 19.19);
                return frac((p3.x + p3.y) * p3.z);
            }

            float3 Hash33(float3 p3)
            {
                p3 = frac(p3 * float3(443.897, 441.423, 437.195));
                p3 += dot(p3, p3.yxz + 19.19);
                return frac((p3.xxy + p3.yxx) * p3.zyx);
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

            float3 OrbitAround(float3 origin, float radius, float rate)
            {
                return float3(origin.x + radius * cos(_STTime * rate), origin.y, origin.z + radius * sin(_STTime * rate));
            }

            float3 CameraPos()
            {
                return OrbitAround(float3(0.0, 0.0, 0.0), 6.5, 0.25);
            }

            float2 U(float2 d1, float2 d2) { return d1.x < d2.x ? d1 : d2; }

            float2 Shape(float3 p)
            {
                p.xz *= 0.8;
                p.xyz += 1.000 * sin(2.0 * p.yzx);
                p.xyz -= 0.500 * sin(4.0 * p.yzx);
                return float2((length(p.xyz) - 1.5) * 0.25, 1.0);
            }

            float2 Scene(float3 p)
            {
                float2 shape = Shape(p);
                float2 light = float2(length(p - float3(0.0, sin(_STTime), 0.0) * 3.0) - 0.1, 2.0);
                return U(shape, light);
            }

            float2 March(Ray ray)
            {
                float depth = NEAR_CLIP;
                float id = 0.0;
                [loop] for (int i = 0; i < MAX_STEPS; ++i)
                {
                    float2 sdf = Scene(ray.o + ray.d * depth);
                    if (sdf.x < EPSILON) { id = sdf.y; break; }
                    if (sdf.x >= FAR_CLIP) break;
                    depth += sdf.x;
                }
                return float2(clamp(depth, NEAR_CLIP, FAR_CLIP), id);
            }

            float3 SceneNormal(float3 pos)
            {
                float2 e = float2(0.001, 0.0);
                return normalize(float3(
                    Scene(pos + e.xyy).x - Scene(pos - e.xyy).x,
                    Scene(pos + e.yxy).x - Scene(pos - e.yxy).x,
                    Scene(pos + e.yyx).x - Scene(pos - e.yyx).x));
            }

            float3 GenerateSampleVector(float3 norm, float i)
            {
                return MirrorVector(normalize(Hash33(norm + i)), norm);
            }

            float CalculateThickness(float3 pos, float3 norm)
            {
                float sampleCount = max(1.0, 64.0 * UISlider(1));
                float invCount = 1.0 / sampleCount;
                float sampleDepth = max(0.1, 2.0 * UISlider(2));
                float thickness = 0.0;
                [loop] for (float i = 0.0; i < 64.0; i += 1.0)
                {
                    if (i >= sampleCount) break;
                    float sampleLength = Hash11(i) * sampleDepth;
                    float3 sampleDir = GenerateSampleVector(-norm, i);
                    thickness += sampleLength + Scene(pos + sampleDir * sampleLength).x;
                }
                return clamp(thickness * invCount, 0.0, 1.0);
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
                Ray ray = RayLookAt(uv, CameraPos(), float3(0.0, -0.25, 0.0));
                float2 march = March(ray);
                float depth = march.x;
                float surfID = march.y;
                float3 normal = float3(0.0, 1.0, 0.0);
                float thickness = 1.0;

                if (depth < FAR_CLIP)
                {
                    float3 pos = ray.o + ray.d * depth;
                    normal = SceneNormal(pos);
                    thickness = CalculateThickness(pos, normal);
                }

                return float4(clamp(depth / FAR_CLIP, EPSILON, 1.0), thickness, surfID, float(PackNormal(normal, 14u)));
            }
            ENDHLSL
        }
    }
}
