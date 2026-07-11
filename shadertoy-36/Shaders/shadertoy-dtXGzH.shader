Shader "Shadertoy/dtXGzH_VolumetricFurBalls"
{
    Properties
    {
        [MainTexture] _BaseMap("Texture", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        _Cutoff("AlphaCutout", Range(0.0, 1.0)) = 0.5
        _Surface("__surface", Float) = 0.0
        _Blend("__mode", Float) = 0.0
        _Cull("__cull", Float) = 2.0
        [ToggleUI] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _BlendOp("__blendop", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _SrcBlendAlpha("__srcA", Float) = 1.0
        [HideInInspector] _DstBlendAlpha("__dstA", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _AlphaToMask("__alphaToMask", Float) = 0.0
        _QueueOffset("Queue offset", Float) = 0.0

        _Channel0 ("Channel 0", 2D) = "white" {}
        _STResolution("ST Resolution", Vector) = (512,288,0.001953125,0.003472222)
        _STTime("ST Time", Float) = 0
        _STFrame("ST Frame", Float) = 0
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

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half _Cutoff;
            half _Surface;
            float4 _STResolution;
            float _STTime;
            float _STFrame;
        CBUFFER_END

        TEXTURE2D(_Channel0);
        SAMPLER(sampler_Channel0);

        float Density(float3 p)
        {
            float noise = SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, p.xy).r;
            return max(0.0, 1.1 - length(p) - 0.1 * noise - 0.04 * sin(sin(4.0 * p.x) + 15.0 * p.y + 6.0 * _STTime));
        }

        float4 RenderFurBalls(float2 fragCoord)
        {
            float2 p = fragCoord;
            float3 r = _STResolution.xyz;
            float3 d = float3(frac((p - 0.5 * r.xy) / r.y * 2.2) - 0.5, 1.0);
            float3 o = d * 2.3 - float3(0.0, 0.0, 3.0);
            float3 a = 5.0;

            float4 c = 0.0;

            [unroll]
            for (int i = 0; i < 32; i++)
            {
                o += d * 0.05;

                float qx = step(p.x, 0.5 * r.x);
                float qy = step(p.x, r.x / 4.0);
                float qz = step(p.x, r.x * 0.75);

                float3 colAB = lerp(float3(1.0, 0.9, 0.8), float3(0.8, 0.9, 1.0), qx);
                float3 colCD = lerp(colAB, float3(1.0, 0.8, 0.9), qy);
                float3 baseCol = lerp(float3(0.9, 1.0, 0.8), colCD, qz);

                float fo = Density(o);
                float fo2 = Density(o + 0.07);
                a *= baseCol - fo / 3.0;
                c.rgb += a * max(0.0, fo - fo2);
            }

            c = sqrt(c / (1.0 + c));
            c.a = 1.0;
            return c;
        }

        float4 RenderCrystal(float2 fragCoord)
        {
            return RenderFurBalls(fragCoord);
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
            #include "Assets/unity-shadertoy-validation/shadertoy-33/Shaders/CrystalUnlitForwardPass.hlsl"
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