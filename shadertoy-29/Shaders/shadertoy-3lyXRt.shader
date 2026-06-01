Shader "Shadertoy/3lyXRt_SSR"
{
    Properties
    {
        _Channel0("Depth", 2D) = "black" {}
        _Channel1("Normal", 2D) = "black" {}
        _Channel2("Color", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "ForwardUnlit"
            Cull Off ZWrite Off ZTest Always
            HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; float2 fragCoord : TEXCOORD1; };
            struct Ray { float3 origin; float3 dir; };

            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            TEXTURE2D(_Channel1); SAMPLER(sampler_Channel1);
            TEXTURE2D(_Channel2); SAMPLER(sampler_Channel2);

            float4 _STResolution;
            float _STTime;

            static const float3 CAMERA_X = float3(1,0,0);
            static const float3 CAMERA_Y = float3(0,1,0);
            static const float3 CAMERA_Z = float3(0,0,1);
            static const float3 EYE_POS = float3(0,1,-5);
            static const float NEAR_DISTANCE = 2.0;
            static const float FAR_DISTANCE = 50.0;
            static const float3 LIGHT_DIRECTION = normalize(float3(0.5, -1.0, 1.0));

            static const float MAX_DISTANCE = 15.0;
            static const float STEP_SIZE = 0.05;
            static const float THICKNESS = 0.0006;

            float MapRange(float value, float min1, float max1, float min2, float max2)
            {
                return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
            }

            float2 ProjectOnScreen(float3 eye, float3 posWs)
            {
                float3 toPoint = posWs - eye;
                posWs = posWs - toPoint * (1.0 - NEAR_DISTANCE / dot(toPoint, CAMERA_Z));
                posWs -= eye + NEAR_DISTANCE * CAMERA_Z;
                return posWs.xy;
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
                float4 col = SAMPLE_TEXTURE2D(_Channel2, sampler_Channel2, uv);

                if (col.a > 0.5)
                {
                    float3 eye = EYE_POS + float3(3.0 * cos(_STTime), 1.0 * sin(_STTime), 0.0);
                    float2 r_uv = 2.0 * i.fragCoord / _STResolution.y - float2(_STResolution.x / _STResolution.y, 1.0);
                    float3 r_dir = r_uv.x * CAMERA_X + r_uv.y * CAMERA_Y + NEAR_DISTANCE * CAMERA_Z;
                    Ray ray; ray.origin = eye; ray.dir = normalize(r_dir);

                    float aspect = _STResolution.x / _STResolution.y;
                    float depth = SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, uv).x;
                    float3 normal = SAMPLE_TEXTURE2D(_Channel1, sampler_Channel1, uv).xyz;

                    float3 view = ray.dir * length(r_dir) * depth * FAR_DISTANCE / NEAR_DISTANCE;
                    float3 position = ray.origin + view;
                    float3 reflected = reflect(normalize(view), normal);

                    float2 reflectionUV = uv;
                    float atten = 0.0;
                    float3 marchReflection = 0;
                    float currentDepth = depth;

                    [loop]
                    for (float d = STEP_SIZE; d < MAX_DISTANCE; d += STEP_SIZE)
                    {
                        marchReflection = d * reflected;
                        float targetDepth = dot(view + marchReflection, CAMERA_Z) / FAR_DISTANCE;
                        float2 target = ProjectOnScreen(eye, position + marchReflection);
                        target.x = MapRange(target.x, -aspect, aspect, 0.0, 1.0);
                        target.y = MapRange(target.y, -1.0, 1.0, 0.0, 1.0);
                        float sampledDepth = SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, target).x;
                        float depthDiff = sampledDepth - currentDepth;
                        if (depthDiff > 0.0 && depthDiff < targetDepth - currentDepth + THICKNESS)
                        {
                            reflectionUV = target;
                            atten = 1.0 - d / MAX_DISTANCE;
                            break;
                        }
                        currentDepth = targetDepth;
                        if (currentDepth > 1.0)
                        {
                            break;
                        }
                    }

                    col = float4(SAMPLE_TEXTURE2D(_Channel2, sampler_Channel2, reflectionUV).rgb * atten + col.rgb, 1.0);
                }
                else
                {
                    col = float4(col.rgb, 1.0);
                }

                col.rgb = pow(col.rgb, 1.0 / 1.6);
                return col;
            }
            ENDHLSL
        }
    }
}
