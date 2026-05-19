Shader "Shadertoy/McjBzK_PixelScan"
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
        #define MODE 0
        #define LAYERS 5.0
        #define SPEED 1.0
        #define DELAY 0.0
        #define WIDTH 0.05
        static const float kWidth = WIDTH;
        #define MAX_LAYERS 32.0

        float dir = 1.0;

        float4 readTex(float2 uv)
        {
            if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return 0.0;
            return SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, uv);
        }

        float hash(float2 p) { return frac(sin(dot(p, float2(4859.0, 3985.0))) * 3984.0); }

        float3 hsv2rgb(float3 c)
        {
            float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

        float sdBox(float2 p, float r)
        {
            float2 q = abs(p) - r;
            return min(length(q), max(q.y, q.x));
        }

        float toRangeT(float2 p, float scale)
        {
            float d = p.x / (scale * 2.0) + 0.5;
            d = dir > 0.0 ? d : (1.0 - d);
            return d;
        }

        float4 cell(float2 p, float2 pi, float scale, float t, float edge)
        {
            float2 pc = pi + 0.5;
            float2 uvc = pc / scale;
            uvc.y /= (_STResolution.y / _STResolution.x);
            uvc = uvc * 0.5 + 0.5;
            if (uvc.x < 0.0 || uvc.x > 1.0 || uvc.y < 0.0 || uvc.y > 1.0) return 0.0;
            float alpha = smoothstep(0.0, 0.1, SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, uvc).a);
            float4 color = float4(hsv2rgb(float3((pc.x * 13.0 / max(pc.y, 1e-4) * 17.0) * 0.3, 1.0, 1.0)), 1.0);
            float x = toRangeT(pi, scale);
            float n = hash(pi);
            float anim = smoothstep(kWidth * 2.0, 0.0, abs(x + n * kWidth - t));
            color *= anim;
            color *= lerp(1.0, clamp(0.3 / max(abs(sdBox(p - pc, 0.5)), 1e-4), 0.0, 10.0), edge * pow(anim, 10.0));
            return color * alpha;
        }

        float4 cellsColor(float2 p, float scale, float t)
        {
            float2 pi = floor(p);
            float2 d = float2(0.0, 1.0);
            float4 cc = 0.0;
            cc += cell(p, pi, scale, t, 0.2) * 4.0;
            cc += cell(p, pi + d.xy, scale, t, 0.9);
            cc += cell(p, pi - d.xy, scale, t, 0.9);
            cc += cell(p, pi + d.yx, scale, t, 0.9);
            cc += cell(p, pi - d.yx, scale, t, 0.9);
            return cc / 8.0;
        }

        float4 draw(float2 uv, float2 p, float t, float scale)
        {
            float4 c = readTex(uv);
            float2 pi = floor(p * scale);
            float n = hash(pi);
            t = t * (1.0 + kWidth * 4.0) - kWidth * 2.0;
            float x = toRangeT(pi, scale);
            float a1 = smoothstep(t, t - kWidth, x + n * kWidth);
            c *= a1;
            c += cellsColor(p * scale, scale, t) * 1.5;
            return c;
        }

        float4 Frag(Varyings i) : SV_Target
        {
            float2 uv = i.uv;
            float2 p = uv * 2.0 - 1.0;
            p.y *= _STResolution.y / _STResolution.x;

            float transitionDuration = 2.0;
            float t = ModGLSL(_STTime / transitionDuration, 2.0);
            if (t > 1.0)
            {
                t = 2.0 - t;
                dir = -1.0;
            }
            else { dir = 1.0; }
            t = clamp((t - DELAY) * SPEED, 0.0, 1.0);
            t = (frac(t * 0.99999) - 0.5) * dir + 0.5;

            float4 finalColor = 0.0;
            float layerCount = 0.0;
            [loop]
            for (int k = 0; k < 32; k++)
            {
                float fi = (float)k;
                if (fi >= LAYERS) break;
                float s = cos(fi) * 7.3 + 10.0;
                finalColor += draw(uv, p, t, abs(s));
                layerCount += 1.0;
            }
            float4 fragColor = finalColor / max(layerCount, 1e-4);
            fragColor *= smoothstep(0.0, 0.01, t);
            return fragColor;
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
