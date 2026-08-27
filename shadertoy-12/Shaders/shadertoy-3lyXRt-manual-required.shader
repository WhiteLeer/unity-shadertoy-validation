Shader "Shadertoy/3lyXRt_ManualPortRequired"
{
    SubShader
    {

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
            #if defined(DEBUG_DISPLAY)
            float3 positionWS : TEXCOORD2;
            float3 normalWS : TEXCOORD3;
            float3 viewDirWS : TEXCOORD4;
            #endif
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };
        #endif
            float4 Frag(Varyings i) : SV_Target
                        {
                            float2 p = i.uv;
                            float grid = step(0.98, frac(p.x * 16.0)) + step(0.98, frac(p.y * 10.0));
                            float3 baseCol = lerp(float3(0.08, 0.02, 0.12), float3(0.35, 0.05, 0.45), p.y);
                            float3 warnCol = float3(1.0, 0.1, 0.9);
                            float3 col = lerp(baseCol, warnCol, saturate(grid));
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
    }
}