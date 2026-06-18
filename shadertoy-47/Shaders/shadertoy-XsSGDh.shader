Shader "Shadertoy/XsSGDh_Marble"
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

        _Channel1 ("Channel 1", 2D) = "white" {}
        _Channel2 ("Channel 2", 2D) = "white" {}
        _Channel3 ("Channel 3", 2D) = "white" {}
        _STResolution("ST Resolution", Vector) = (512,288,0.001953125,0.003472222)
        _STMouse("ST Mouse", Vector) = (0,0,0,0)
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

        #ifndef UNITY_PI
        #define UNITY_PI 3.14159265359
        #endif

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half _Cutoff;
            half _Surface;
            float4 _STResolution;
            float4 _STMouse;
            float _STTime;
            float _STFrame;
        CBUFFER_END

        TEXTURE2D(_Channel1);
        SAMPLER(sampler_Channel1);
        TEXTURE2D(_Channel2);
        SAMPLER(sampler_Channel2);
        TEXTURE2D(_Channel3);
        SAMPLER(sampler_Channel3);

        static const float glassstep = 0.05;
        static const float refrIdx = 1.04;
        static const float3 glasscol = float3(0.06, 0.1, 0.15);

        float3 RotY(float th, float3 p)
        {
            float c = cos(th);
            float s = sin(th);
            return float3(c * p.x - s * p.z, p.y, c * p.z + s * p.x);
        }

        float3 RotX(float th, float3 p)
        {
            float c = cos(th);
            float s = sin(th);
            return float3(p.x, c * p.y - s * p.z, c * p.z + s * p.y);
        }

        float Hash1(float n)
        {
            return frac(sin(n * 0.1346) * 43758.5453123);
        }

        float2 Noise3D(float3 x)
        {
            float3 p = floor(x);
            float3 f = frac(x);
            f = f * f * (3.0 - 2.0 * f);

            float2 uv = (p.xy + float2(37.0, 17.0) * p.z) + f.xy;
            float4 rg = float4(
                Hash1(dot(uv + 0.5, float2(12.9898, 78.233))),
                Hash1(dot(uv + 1.5, float2(93.9898, 67.345))),
                Hash1(dot(uv + 2.5, float2(45.332, 12.345))),
                Hash1(dot(uv + 3.5, float2(28.123, 98.456)))
            );
            return lerp(rg.xz, rg.yw, f.z);
        }

        float3x3 RotMat(float3 v, float angle)
        {
            float c = cos(angle);
            float s = sin(angle);
            return transpose(float3x3(
                c + (1.0 - c) * v.x * v.x,         (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y,
                (1.0 - c) * v.x * v.y + s * v.z,   c + (1.0 - c) * v.y * v.y,       (1.0 - c) * v.y * v.z - s * v.x,
                (1.0 - c) * v.x * v.z - s * v.y,   (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z
            ));
        }

        float4 Warp(float3 p)
        {
            p = mul(RotMat(normalize(float3(1.0, 0.0, 0.0)), p.x * 1.5), p);
            float cyr = sqrt(max(1.0 - p.x * p.x, 0.0)) * 0.6;
            cyr *= 0.6 + 0.4 * sin(7.0 * atan2(p.y, p.z));
            float dd = smoothstep(cyr * 1.1, cyr, length(p.yz));
            return float4(p, dd);
        }

        float3 SampleLatLong(TEXTURE2D_PARAM(tex, samplerTex), float3 dir)
        {
            dir = normalize(dir);
            float2 uv;
            uv.x = atan2(dir.z, dir.x) / (2.0 * UNITY_PI) + 0.5;
            uv.y = acos(clamp(dir.y, -1.0, 1.0)) / UNITY_PI;
            return SAMPLE_TEXTURE2D(tex, samplerTex, uv).rgb;
        }

        float4 Trace(float3 rs, float3 rd, float2 fragCoord)
        {
            float3 p = rs;
            float inside = 1.0;
            float4 col = float4(0.0, 0.0, 0.0, 1.0);

            float A = dot(rd, rd);
            float B = 2.0 * dot(rd, rs);
            float C = dot(rs, rs) - 1.0;
            float q = B * B - 4.0 * A * C;
            float spheret = (-B - sqrt(max(0.0, q))) / (2.0 * A);
            p += rd * spheret;

            [loop]
            for (int i = 0; i < 64; ++i)
            {
                float h = length(p) - 1.0;
                h *= inside;
                if (h <= 0.0)
                {
                    float3 n = normalize(p);
                    float nrd = dot(n, rd) * inside;
                    if (nrd < 0.0)
                    {
                        float3 rr = reflect(rd, n);
                        float rocc = max(0.0, rr.y * inside);
                        float fr = pow(1.0 + nrd, 5.0) * 0.99 + 0.01;

                        col.xyz += col.w * fr * 3.0 * rocc * pow(SampleLatLong(TEXTURE2D_ARGS(_Channel3, sampler_Channel3), rr), 2.2.xxx);
                        if (q > 0.1)
                        {
                            rd = inside * normalize(refract(rd * inside, n, (inside < 0.0) ? refrIdx : (1.0 / refrIdx)));
                        }
                        inside = -inside;
                        if (inside < 0.0)
                        {
                            h = Hash1(fragCoord.x + fragCoord.y * 117.0) * glassstep;
                        }
                        col.w *= 0.95;
                    }
                }

                float stepLen = max(0.01, abs(h) * 0.95);
                if (inside < 0.0)
                {
                    stepLen = min(stepLen, glassstep);
                    float4 warp0 = Warp(p);
                    float warp1 = Warp(p + float3(0.0, 0.02, 0.0)).w;
                    float3 gcol = SAMPLE_TEXTURE2D(_Channel1, sampler_Channel1, warp0.yz * 0.3 + 0.1).xyz;
                    gcol = lerp(gcol, 0.5.xxx, -1.9);
                    gcol *= 0.5 - (warp1 - warp0.w);
                    float dd = warp0.w * 4.0;
                    float k = exp(-stepLen * dd);
                    col.xyz += (1.0 - k) * col.w * gcol;
                    col.w *= k;

                    k = exp(-stepLen * 0.5);
                    col.xyz += (1.0 - k) * col.w * glasscol;
                    col.w *= k;
                }
                else
                {
                    stepLen = min(stepLen, 5.0);
                }
                p += stepLen * rd;
            }

            col.w = 1.0 - col.w;
            col *= smoothstep(0.0, 0.1, q);
            col.w = 1.0 - col.w;

            float flot = (-1.0 - p.y) / rd.y;
            float3 flo = p + flot * rd;
            float3 bg = 1.0.xxx;
            if (dot(rd, flo - rs) > 0.0)
            {
                bg = sqrt(max(1.05 - 1.0 / dot(flo, flo), 0.0)).xxx;
                bg = lerp(bg, 1.0.xxx, smoothstep(0.0, 0.1, q));
            }

            float2 strip;
            float sca = 2.0;
            strip.x = atan2(rd.x, rd.z) * sca * 24.0 / 3.141592;
            strip.y = asin(rd.y) * 10.0 * sca;
            float f = Hash1(floor(strip.x) + floor(strip.y) * 117.0);
            strip = frac(strip);
            if (f < 0.5) strip.x = 1.0 - strip.x;

            float stripe = smoothstep(0.05, 0.08, abs(length(strip) - 0.5));
            stripe *= smoothstep(0.05, 0.08, abs(length(1.0 - strip) - 0.5));
            stripe = 1.0 - stripe;
            stripe *= smoothstep(0.0, 0.9, rd.y);
            bg *= 1.0 - stripe * 0.2;
            col.xyz += col.w * bg;
            return col;
        }

        float4 RenderMarble(float2 fragCoord)
        {
            float2 uv = (fragCoord - _STResolution.xy * 0.5) / _STResolution.yy * 2.0;
            float2 m = _STMouse.xy / max(_STResolution.xy, 1.0.xx);

            float th = (m.y * 0.1 - 0.5) * 1.0;
            float3 rs = RotX(th, float3(0.0, 0.0, -2.0));
            float3 re = RotX(th, float3(uv * 3.0, 2.0));
            th = (m.x - 0.5) * 6.0 + _STTime * 0.071 - 5.1;
            rs = RotY(th, rs);
            re = RotY(th, re);
            float3 rd = normalize(re - rs);

            float4 col = Trace(rs, rd, fragCoord);
            col += (4.0 / 255.0) * Hash1(fragCoord.x + fragCoord.y * 117.0);
            col = lerp(col, smoothstep(0.0, 1.0, col), 0.5);
            col = pow(max(col, 0.0), 0.4.xxxx);
            col *= smoothstep(2.0, 0.0, length(uv * float2(0.25, 0.5)));
            return col;
        }

        float4 RenderCrystal(float2 fragCoord)
        {
            return RenderMarble(fragCoord);
        }
        ENDHLSL

        Pass
        {
            Name "Unlit"
            Tags { "LightMode" = "SRPDefaultUnlit" }
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
            Name "GBuffer"
            Tags { "LightMode" = "UniversalGBuffer" }
            HLSLPROGRAM
            #pragma target 4.5
            #pragma exclude_renderers gles3 glcore
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAMODULATE_ON
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #include "Assets/unity-shadertoy-validation/shadertoy-33/Shaders/CrystalUnlitGBufferPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
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
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormalsOnly"
            Tags { "LightMode" = "DepthNormalsOnly" }
            ZWrite On
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitDepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
}
