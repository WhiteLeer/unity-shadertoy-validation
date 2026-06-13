Shader "Shadertoy/Wdl3W4_SimpleRosePetal"
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
        _STResolution("ST Resolution", Vector) = (512,288,0.001953125,0.003472222)
        _STMouse("ST Mouse", Vector) = (0,0,0,0)
        _STTime("ST Time", Float) = 0
        _STDeltaTime("ST DeltaTime", Float) = 0
        _STFrame("ST Frame", Float) = 0
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
        float2 RotGLSL(float2 p, float a)
        {
            float c = cos(a);
            float s = sin(a);
            return float2(c * p.x - s * p.y, s * p.x + c * p.y);
        }

        float SdEllipsoid(float3 p, float3 r)
        {
            float k0 = length(p / r);
            float k1 = length(p / (r * r));
            return k0 * (k0 - 1.0) / k1;
        }

        float2 Map(float3 sight)
        {
            float3 position = sight;
            float3 radius = float3(1.5, 0.1, 1.0);

            float bend = 0.2;
            float3 q = float3(RotGLSL(position.xy, position.z * bend), position.z);

            bend = -0.1;
            q = float3(RotGLSL(q.xy, q.x * bend), q.z);

            float sdf = SdEllipsoid(q, radius);
            return float2(sdf, 0.0);
        }

        float2 CastRay(float3 ro, float3 rd)
        {
            float tmin = 1.0;
            float tmax = 50.0;
            float t = tmin;
            float m = -1.0;

            [loop] for (int i = 0; i < 128; i++)
            {
                float precis = 0.0004 * t;
                float2 res = Map(ro + rd * t);
                if (res.x < precis || t > tmax) break;
                t += res.x;
                m = res.y;
            }

            if (t > tmax) m = -1.0;
            return float2(t, m);
        }

        float3 Render(float3 ro, float3 rd)
        {
            float3 col = float3(0.85, 0.85, 0.85);
            float2 res = CastRay(ro, rd);
            float t = res.x;
            float m = res.y;

            if (m >= 0.0)
            {
                float tn = 1.0 - t / 24.5;
                float3 white = float3(1.0, 1.0, 0.75);
                float3 red = float3(1.0, 0.0, 0.15);
                col = lerp(red, white, pow(tn, 2.0));
            }

            return clamp(col, 0.0, 1.0);
        }

        void SetCamera(float3 ro, float3 ta, float cr, out float3 cu, out float3 cv, out float3 cw)
        {
            cw = normalize(ta - ro);
            float3 cp = float3(sin(cr), cos(cr), 0.0);
            cu = normalize(cross(cw, cp));
            cv = normalize(cross(cu, cw));
        }

        float4 RenderMain(float2 fragCoord)
        {
            float2 p = (-_STResolution.xy + 2.0 * fragCoord) / _STResolution.y;
            float time = _STTime;

            float3 ro = float3(10.0 * cos(time), 10.0 * sin(time * 2.0), 10.0 * sin(time));
            float3 ta = float3(0.0, 0.0, 0.0);
            float3 cu, cv, cw;
            SetCamera(ro, ta, 0.0, cu, cv, cw);
            float3 rd = normalize(cu * p.x + cv * p.y + cw * 8.0);

            float3 col = Render(ro, rd);
            return float4(col, 1.0);
        }

        half4 Frag(Varyings IN) : SV_Target
        {
            return RenderMain(IN.fragCoord);
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