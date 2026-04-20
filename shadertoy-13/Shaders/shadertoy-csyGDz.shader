Shader "Shadertoy/csyGDz_ToonFlame"
{
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
        uint FK(float x)
        {
            return asuint(cos(x)) ^ asuint(x);
        }

        float hash12(float2 p)
        {
            uint x = FK(p.x);
            uint y = FK(p.y);
            uint a = x * x - y;
            uint b = y * y + x;
            int r = asint(a * b - x);
            return (float)r / 2.14e9;
        }

        float2 hash22(float2 p)
        {
            return float2(hash12(p), hash12(p * 13.321 - 114.411));
        }

        float2x2 rot(float a)
        {
            float s = sin(a), c = cos(a);
            return float2x2(c, -s, s, c);
        }

        float ball(float2 p)
        {
            float2 ii = floor(p);
            float minDist = 10000.0;
            [loop]
            for (int xi = -2; xi <= 2; xi++)
            {
                [loop]
                for (int yi = -2; yi <= 2; yi++)
                {
                    float2 c = ii + float2((float)xi, (float)yi);
                    float2 h = hash22(c);
                    float r = frac(h.x + 0.6541) * 0.5 + 0.3;
                    h = mul(h, rot(_STTime * (frac(r + 0.134) * 8.0 - 4.0)));
                    minDist = min(minDist, length(p - (c + h)) - r);
                }
            }
            return minDist;
        }

        float flame(float2 p)
        {
            float t = _STTime * 3.1415 * 0.25;
            float2 o = float2(0.0, -0.25);
            float d = 10000.0;
            [loop]
            for (int k = 0; k < 8; k++)
            {
                float i = (float)k / 8.0;
                float lt = frac(t + i);
                float r = sqrt(max(0.0, 1.0 - lt)) * 0.2 * min(lt * 2.0, 1.0);
                float2 center = float2(sin(t - lt) * (0.3 / (lt + 1.0) + 0.2), lt * lt * 0.6) - o;
                d = min(d, (length(p - center) - r) * 10.0 * pow(2.0 - lt, 4.0));
            }
            return d;
        }

        float4 Frag(Varyings i) : SV_Target
        {
            float2 fragCoord = i.uv * _STResolution.xy;
            float2 uv = (fragCoord - _STResolution.xy * 0.5) / _STResolution.y;

            float d = ball(uv * 40.0 - float2(0.0, _STTime * 10.0));
            float d2 = 1.0 - ball(uv * 10.0 - float2(0.0, _STTime * 7.0));
            float fw = max(fwidth(d), 1e-4);
            float flm = d - d2 - flame(uv);
            float3 col = lerp(float3(0.05, 0.15, 0.2), float3(1.0, 0.6, 0.05), smoothstep(-fw, fw, flm));
            col = lerp(col, float3(1.0, 0.9, 0.4), smoothstep(-fw, fw, flm - 3.0));
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