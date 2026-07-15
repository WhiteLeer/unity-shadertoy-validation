Shader "Shadertoy/tXXBW8_Cilia"
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

        #define ST_PI 3.14159

        float Hash31(float3 p3)
        {
            p3 = frac(p3 * float3(0.1031, 0.1030, 0.0973));
            p3 += dot(p3, p3.yxz + 33.33);
            return frac((p3.x + p3.y) * p3.z);
        }

        float RadiusAt(float2 uv, float idx, out float fiber)
        {
            float l = length(uv);
            float n = frac(((atan2(uv.y, uv.x) + ST_PI) / 6.28318) + 0.801 * idx);

            n += 0.0125 * sin(0.5 * _STTime);
            n += smoothstep(0.17, 0.1, l) * 0.004 * sin(0.5 * idx + 3.0 * _STTime + 100.0 * l);

            float cs = 250.0 + fmod(idx, 3.0) * 75.0;
            float c = fmod(floor(cs * n), cs);
            if (step(1.0, fmod(c, 2.0)) > 0.0)
            {
                fiber = 0.0;
                return 1.0;
            }

            float v = frac(cs * n) - 0.5;
            fiber = sqrt(max(1.0 - v * v, 0.0));

            return lerp(0.18, 0.19, 0.5 + 0.5 * sin(0.5 * idx))
                - 0.05 * Hash31(float3(11.0 * c, 5.0142 * idx, 0.125 + 17.0 * c))
                - 0.012 * fiber;
        }

        float TraceCilia(float3 o, float3 r, out float fiber)
        {
            float stepLen = 0.0066;
            float layers = 180.0;
            float best = 1e5;
            fiber = 0.0;

            [loop]
            for (int it = 0; it < 180; it++)
            {
                float idx = (float)it + min(_STFrame, 0.0);
                float q = fmod(stepLen * idx - 0.1 * _STTime, layers * stepLen);
                float d = -(o.z + q) / r.z;
                float2 uv = (o + r * d).xy;
                float ff = 0.0;
                if (length(uv) > RadiusAt(uv, idx, ff))
                {
                    if (d < best)
                    {
                        best = d;
                        fiber = ff;
                    }
                }
            }

            return best;
        }

        float NoiseBands(float3 p, float f)
        {
            return clamp(abs(dot(sin(p * 0.5), cos(p.zxy * 1.23) * f)) - 0.1, 0.0, 3.0) / 3.0;
        }

        float Fbm(float3 p)
        {
            p.z -= 1.6 * _STTime;

            const int octaves = 4;
            float scale = 1.95;
            float n = ST_PI / (float)octaves;
            float w = 0.0;
            float amp = 1.0;
            float freq = 1.0;
            float result = 0.0;

            float s = sin(n);
            float c = cos(n);
            float3x3 m = transpose(float3x3(
                scale * c, scale * s, 0.0,
                scale * -s, scale * c, 0.0,
                0.0, 0.0, scale
            ));

            [unroll]
            for (int i = 0; i < octaves; i++)
            {
                result += amp * NoiseBands(p, freq);
                p = mul(m, p);
                w += amp;
                amp *= 0.7;
                freq *= 0.78;
            }

            return clamp(result / max(w, 1e-5), 0.0, 1.0);
        }

        float InvPow(float d, float r, float intensity)
        {
            return max(0.0, pow(r / max(d, 1e-5), intensity));
        }

        float4 RenderCilia(float2 fragCoord)
        {
            float3 k;
            float3 z;
            float3 x;
            float3 r;
            float3 p;
            float3 c;

            float2 fg = fragCoord;
            float t = 0.05 * _STTime + 20.0;
            k = float3(0.075 * cos(t), -0.075 * sin(t), 0.05);
            z = normalize(float3(0.0, 0.0, -1.0) - k);
            x = normalize(cross(z, float3(0.0, 1.0, 0.0)));

            float3x3 cam = transpose(float3x3(
                x.x, x.y, x.z,
                cross(x, z).x, cross(x, z).y, cross(x, z).z,
                -z.x, -z.y, -z.z
            ));
            r = normalize(mul(cam, float3(fg - _STResolution.xy * 0.5, -(0.5 * _STResolution.y) / 0.36397040)));

            float fiber = 0.0;
            float d = TraceCilia(k, r, fiber);
            p = k + r * d;

            c = 0.25 * smoothstep(0.2, 0.0, length(p.xy)).xxx * float3(0.3, 0.7, 0.9) * 0.25 * InvPow(
                Fbm(16.0 * p), 0.5, 1.5);
            c += 0.5 * float3(0.74, 0.65, 0.65) * InvPow(1.0 - smoothstep(0.15, 0.1155, length(p.xy)), 0.1, 3.0);
            c *= (fiber * fiber * fiber).xxx * smoothstep(-1.2, 0.0, p.z);
            c = 1.0 - exp(-c);
            c = pow(c, float3(0.4545, 0.4545, 0.4545));

            float2 u = fg / _STResolution.xy;
            c *= 0.5 + 0.5 * pow(16.0 * u.x * u.y * (1.0 - u.x) * (1.0 - u.y), 0.5);

            return float4(c, 1.0);
        }

        float4 RenderCrystal(float2 fragCoord)
        {
            return RenderCilia(fragCoord);
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