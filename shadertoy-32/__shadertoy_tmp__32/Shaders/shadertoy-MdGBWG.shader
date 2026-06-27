Shader "Shadertoy/MdGBWG_GlobalWindCirculation"
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
        _LandTex("Land", 2D) = "black" {}
        _BufferBTex("BufferB", 2D) = "black" {}
        _BufferCTex("BufferC", 2D) = "black" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "UniversalMaterialType" = "Unlit"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        Blend [_SrcBlend][_DstBlend], [_SrcBlendAlpha][_DstBlendAlpha]
        ZWrite [_ZWrite]
        Cull [_Cull]

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
            float3 normalOS : NORMAL;
            #if defined(DEBUG_DISPLAY)
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
            float3 normalWS : TEXCOORD3;
            #if defined(DEBUG_DISPLAY)
            float3 positionWS : TEXCOORD2;
            float3 viewDirWS : TEXCOORD4;
            #endif
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };
        #endif
        sampler2D _LandTex;
        sampler2D _BufferBTex;
        sampler2D _BufferCTex;

        #define MAPRES float2(144.0,72.0)
        #define PASS3 float2(0.5,0.0)
        #define PASS4 float2(0.5,0.5)
        #define PAPER
        #define LOW_PRESSURE float3(0.0,0.5,1.0)
        #define HIGH_PRESSURE float3(1.0,0.5,0.0)

        float3 RenderMain(float2 fragCoord)
        {
            float2 p = fragCoord * MAPRES / _STResolution.xy;
            if (p.x < 1.0) p.x = 1.0;
            float2 uv = p / _STResolution.xy;
            float land = tex2D(_LandTex, uv).x;
            float3 rgb = float3(0.0, 0.0, 0.0);
            if (0.25 < land && land < 0.75) rgb = float3(0.5, 0.5, 0.5);

            float mbar = tex2D(_BufferBTex, uv + PASS3).x;
            if (_STMouse.z > 0.0)
            {
                float3 r = LOW_PRESSURE;
                r = lerp(r, float3(0.0, 0.0, 0.0), smoothstep(1000.0, 1012.0, floor(mbar)));
                r = lerp(r, HIGH_PRESSURE, smoothstep(1012.0, 1024.0, floor(mbar)));
                rgb += 0.5 * r;
            }
            else
            {
                float2 v = tex2D(_BufferBTex, uv + PASS4).xy;
                float flow = tex2D(_BufferCTex, fragCoord / _STResolution.xy).z;
                float3 hue = float3(1.0, 0.75, 0.5);
                float alpha = clamp(length(v), 0.0, 1.0) * flow;
                rgb = lerp(rgb, hue, alpha);
            }

            rgb = 0.9 - 0.8 * rgb;
            float gx = fmod(fragCoord.x, floor(_STResolution.x / 36.0));
            float gy = fmod(fragCoord.y, floor(_STResolution.y / 18.0));
            if (gx < 1.0 || gy < 1.0)
                rgb = lerp(rgb, float3(0.0, 0.5, 1.0), 0.2);
            return rgb;
        }

        half4 Frag(Varyings IN) : SV_Target
        {
            return float4(RenderMain(IN.fragCoord), 1.0);
        }


        float4 RenderShadertoy(float2 fragCoord)
        {
            return float4(RenderMain(fragCoord), 1.0);
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
