Shader "Shadertoy/3lyXRt_SSR"
{
    Properties
    {

        [MainTexture] _BaseMap("Texture", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        _Cutoff("AlphaCutout", Range(0.0, 1.0)) = 0.5
        _Surface("__surface", Float) = 0.0
        _Blend("__mode", Float) = 0.0
        _Cull("__cull", Float) = 0.0
        [ToggleUI] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _BlendOp("__blendop", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _SrcBlendAlpha("__srcA", Float) = 1.0
        [HideInInspector] _DstBlendAlpha("__dstA", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 0.0
        [HideInInspector] _AlphaToMask("__alphaToMask", Float) = 0.0
        _QueueOffset("Queue offset", Float) = 0.0
        _STResolution("ST Resolution", Vector) = (512,288,0.001953125,0.003472222)
        _STMouse("ST Mouse", Vector) = (0,0,0,0)
        _STTime("ST Time", Float) = 0
        _STDeltaTime("ST DeltaTime", Float) = 0
        _STFrame("ST Frame", Float) = 0
        _Channel0("Depth", 2D) = "black" {}
        _Channel1("Normal", 2D) = "black" {}
        _Channel2("Color", 2D) = "black" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Assets/unity-shadertoy-validation/Common/Shaders/ShadertoyCompat.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half _Cutoff;
            half _Surface;
            float4 _STResolution;
            float4 _STMouse;
            float _STTime;
            float _STDeltaTime;
            float _STFrame;
        CBUFFER_END

        #ifndef SHADERTOY_GLOBALS_DEFINED
        #define SHADERTOY_GLOBALS_DEFINED
        float3 iResolution;
        float iTime;
        float4 iMouse;
        float iFrame;
        float iTimeDelta;
        #endif

        #ifndef SHADERTOY_SHARED_VARYINGS_DEFINED
        #define SHADERTOY_SHARED_VARYINGS_DEFINED

        struct Attributes
        {
            float4 positionOS : POSITION;
            float2 uv : TEXCOORD0;
            #if defined(DEBUG_DISPLAY)
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #endif
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct Varyings
        {
            float2 uv : TEXCOORD0;
            float fogCoord : TEXCOORD1;
            float4 positionCS : SV_POSITION;
            float2 fragCoord : TEXCOORD5;
            #if defined(DEBUG_DISPLAY)
            float3 positionWS : TEXCOORD2;
            float3 normalWS : TEXCOORD3;
            float3 viewDirWS : TEXCOORD4;
            #endif
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };
        #endif
        struct Ray
        {
            float3 origin;
            float3 dir;
        };

        TEXTURE2D(_Channel0);
        SAMPLER(sampler_Channel0);
        TEXTURE2D(_Channel1);
        SAMPLER(sampler_Channel1);
        TEXTURE2D(_Channel2);
        SAMPLER(sampler_Channel2);
        static const float3 CAMERA_X = float3(1, 0, 0);
        static const float3 CAMERA_Y = float3(0, 1, 0);
        static const float3 CAMERA_Z = float3(0, 0, 1);
        static const float3 EYE_POS = float3(0, 1, -5);
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

        float4 Frag(Varyings i) : SV_Target
        {
            float2 uv = i.fragCoord / _STResolution.xy;
            float4 col = SAMPLE_TEXTURE2D(_Channel2, sampler_Channel2, uv);

            if (col.a > 0.5)
            {
                float3 eye = EYE_POS + float3(3.0 * cos(_STTime), 1.0 * sin(_STTime), 0.0);
                float2 r_uv = 2.0 * i.fragCoord / _STResolution.y - float2(_STResolution.x / _STResolution.y, 1.0);
                float3 r_dir = r_uv.x * CAMERA_X + r_uv.y * CAMERA_Y + NEAR_DISTANCE * CAMERA_Z;
                Ray ray;
                ray.origin = eye;
                ray.dir = normalize(r_dir);

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


        float4 RenderShadertoy(float2 fragCoord)
        {
            Varyings input = (Varyings)0;
            input.uv = fragCoord / _STResolution.xy;
            input.fragCoord = fragCoord;
            return Frag(input);
        }
        ENDHLSL


        Pass
        {
            Name "Unlit"
            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
            }
            AlphaToMask [_AlphaToMask]

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment
            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAMODULATE_ON
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile _ DEBUG_DISPLAY
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #define SHADERTOY_RENDER_FUNCTION RenderShadertoy
            #include "Assets/unity-shadertoy-validation/Common/Shaders/ShadertoyURPForwardPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }
            ZWrite On
            ColorMask R
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #include "Assets/unity-shadertoy-validation/Common/Shaders/ShadertoyDepthOnlyPass.hlsl"
            ENDHLSL
        }
    }
}