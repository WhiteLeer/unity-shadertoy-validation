Shader "Shadertoy/4tc3DX_GloriousLine"
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
        _Unused("Unused", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
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
            #if defined(DEBUG_DISPLAY)
            float3 positionWS : TEXCOORD2;
            float3 normalWS : TEXCOORD3;
            float3 viewDirWS : TEXCOORD4;
            #endif
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };
        #endif
        #define vec2 float2
        #define vec3 float3
        #define vec4 float4
        #define mix lerp
        #define fract frac
        #define dFdy ddy
        #define dFdx ddx
        float repeatf(float x) { return abs(fract(x * 0.5 + 0.5) - 0.5) * 2.0; }

        float LineDistField(vec2 uv, vec2 pA, vec2 pB, vec2 thick, float rounded, float dashOn)
        {
            rounded = min(thick.y, rounded);
            vec2 mid = (pB + pA) * 0.5;
            vec2 delta = pB - pA;
            float lenD = length(delta);
            vec2 unit = delta / lenD;
            if (lenD < 0.0001) unit = vec2(1.0, 0.0);
            vec2 perp = unit.yx * vec2(-1.0, 1.0);
            float dpx = dot(unit, uv - mid);
            float dpy = dot(perp, uv - mid);
            float disty = abs(dpy) - thick.y + rounded;
            float distx = abs(dpx) - lenD * 0.5 - thick.x + rounded;

            float dist = length(vec2(max(0.0, distx), max(0.0, disty))) - rounded;
            dist = min(dist, max(distx, disty));

            float dashScale = 2.0 * thick.y;
            float dash = (repeatf(dpx / dashScale + iTime) - 0.5) * dashScale;
            dist = max(dist, dash - (1.0 - dashOn * 1.0) * 10000.0);

            return dist;
        }

        float FillLinePix(vec2 uv, vec2 pA, vec2 pB, vec2 thick, float rounded)
        {
            float scale = abs(dFdy(uv).y);
            thick = (thick * 0.5 - 0.5) * scale;
            float df = LineDistField(uv, pA, pB, thick, rounded, 0.0);
            return saturate(df / scale);
        }

        float DrawOutlinePix(vec2 uv, vec2 pA, vec2 pB, vec2 thick, float rounded, float outlineThick)
        {
            float scale = abs(dFdy(uv).y);
            thick = (thick * 0.5 - 0.5) * scale;
            rounded = (rounded * 0.5 - 0.5) * scale;
            outlineThick = (outlineThick * 0.5 - 0.5) * scale;
            float df = LineDistField(uv, pA, pB, thick, rounded, 0.0);
            return saturate((abs(df + outlineThick) - outlineThick) / scale);
        }

        float FillLine(vec2 uv, vec2 pA, vec2 pB, vec2 thick, float rounded)
        {
            float df = LineDistField(uv, pA, pB, thick, rounded, 0.0);
            return saturate(df / abs(dFdy(uv).y));
        }

        float FillLineDash(vec2 uv, vec2 pA, vec2 pB, vec2 thick, float rounded)
        {
            float df = LineDistField(uv, pA, pB, thick, rounded, 1.0);
            return saturate(df / abs(dFdy(uv).y));
        }

        float DrawOutline(vec2 uv, vec2 pA, vec2 pB, vec2 thick, float rounded, float outlineThick)
        {
            float df = LineDistField(uv, pA, pB, thick, rounded, 0.0);
            return saturate((abs(df + outlineThick) - outlineThick) / abs(dFdy(uv).y));
        }

        void DrawPoint(vec2 uv, vec2 p, inout vec3 col)
        {
            col = mix(col, vec3(1.0, 0.25, 0.25), saturate(abs(dFdy(uv).y) * 8.0 / distance(uv, p) - 4.0));
        }

        void mainImage(out vec4 fragColor, in vec2 fragCoord)
        {
            vec2 uv = fragCoord.xy / iResolution.xy;
            uv -= 0.5;
            uv.x *= iResolution.x / iResolution.y;
            uv *= 16.0;

            vec2 rotA = vec2(cos(iTime * 0.82), sin(iTime * 0.82));
            vec2 rotB = vec2(sin(iTime * 0.82), -cos(iTime * 0.82));
            vec2 pA = vec2(-4.0, 0.0) - rotA;
            vec2 pB = vec2(4.0, 0.0) + rotA;
            vec2 pC = pA + vec2(0.0, 4.0);
            vec2 pD = pB + vec2(0.0, 4.0);

            vec3 finalColor = vec3(1.0, 1.0, 1.0);

            finalColor *= FillLinePix(uv, pA, pB, vec2(1.0, 1.0), 0.0);
            finalColor *= DrawOutlinePix(uv, pA, pB, vec2(32.0, 32.0), 16.0, 1.0);
            finalColor *= DrawOutlinePix(uv, pA, pB, vec2(64.0, 64.0), 0.0, 1.0);
            finalColor *= DrawOutlinePix(uv, pA, pB, vec2(128.0, 128.0), 128.0, 8.0);
            finalColor *= FillLineDash(uv, pC, pD, vec2(0.0, 0.5), 0.0);
            finalColor *= FillLineDash(uv, pC + vec2(0.0, 2.0), pD + vec2(0.0, 2.0), vec2(0.125, 0.125), 1.0);

            finalColor *= DrawOutline(uv, (pA + pB) * 0.5 + vec2(0.0, -4.5), (pA + pB) * 0.5 + vec2(0.0, -4.5),
                                                                  vec2(2.0, 2.0), 2.0, 0.8);
            finalColor *= FillLine(uv, pA - vec2(4.0, 0.0), pC - vec2(4.0, 0.0) + rotA, vec2(0.125, 0.125), 1.0);
            finalColor *= FillLine(uv, pB + vec2(4.0, 0.0), pD + vec2(4.0, 0.0) - rotA, vec2(0.125, 0.125), 1.0);

            DrawPoint(uv, pA, finalColor);
            DrawPoint(uv, pB, finalColor);
            DrawPoint(uv, pC, finalColor);
            DrawPoint(uv, pD, finalColor);

            finalColor -= vec3(1.0, 1.0, 0.2) * saturate(repeatf(uv.x * 2.0) - 0.92) * 4.0;
            finalColor -= vec3(1.0, 1.0, 0.2) * saturate(repeatf(uv.y * 2.0) - 0.92) * 4.0;
            fragColor = vec4(sqrt(saturate(finalColor)), 1.0);
        }


        float4 RenderCrystal(float2 fragCoord)
        {
            iResolution = _STResolution.xyz;
            iTime = _STTime;
            iMouse = _STMouse;
            iFrame = _STFrame;
            iTimeDelta = _STDeltaTime;
            float4 fragColor = 0.0;
            mainImage(fragColor, fragCoord);
            return fragColor;
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