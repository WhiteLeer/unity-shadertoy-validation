Shader "Shadertoy/dtBGRd_KuwaharaMinimal"
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
        _Channel0("Channel0", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry"
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
        TEXTURE2D(_Channel0);
        SAMPLER(sampler_Channel0);

        float Gray(float3 c)
        {
            return dot(c, float3(0.299, 0.587, 0.114));
        }

        float3 SamplePix(float2 fragCoord, int ix, int iy)
        {
            float2 uv = (fragCoord + float2((float)ix, (float)iy)) / _STResolution.xy;
            return SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, uv).rgb;
        }

        float4 Frag(Varyings i) : SV_Target
        {
            float2 fragCoord = i.uv * _STResolution.xy;
            const int K = 3;
            float sectorSz = (float)(K * K + 2 * K + 1);

            float3 u0 = 0.0;
            float3 u1 = 0.0;
            float3 u2 = 0.0;
            float3 u3 = 0.0;

            [loop]
            for (int ix = 0; ix <= K; ix++)
            {
                [loop]
                for (int iy = 0; iy <= K; iy++)
                {
                    u0 += SamplePix(fragCoord, ix - K, iy - K);
                    u1 += SamplePix(fragCoord, ix, iy - K);
                    u2 += SamplePix(fragCoord, ix - K, iy);
                    u3 += SamplePix(fragCoord, ix, iy);
                }
            }

            u0 /= sectorSz;
            u1 /= sectorSz;
            u2 /= sectorSz;
            u3 /= sectorSz;

            float4 u = float4(Gray(u0), Gray(u1), Gray(u2), Gray(u3));

            float4 var = 0.0;
            [loop]
            for (int ix = 0; ix <= K; ix++)
            {
                [loop]
                for (int iy = 0; iy <= K; iy++)
                {
                    float4 v = float4(
                        Gray(SamplePix(fragCoord, ix - K, iy - K)),
                        Gray(SamplePix(fragCoord, ix, iy - K)),
                        Gray(SamplePix(fragCoord, ix - K, iy)),
                        Gray(SamplePix(fragCoord, ix, iy))
                    ) - u;
                    var += v * v;
                }
            }

            float m = min(var.x, min(var.y, min(var.z, var.w)));
            float3 col =
                (m == var.x)
                    ? u0
                    : (m == var.y)
                    ? u1
                    : (m == var.z)
                    ? u2
                    : (m == var.w)
                    ? u3
                    : (u0 + u1 + u2 + u3) * 0.25;

            return float4(col, 1.0);
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