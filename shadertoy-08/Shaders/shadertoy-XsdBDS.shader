Shader "Shadertoy/XsdBDS_ToonyFire"
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
        TEXTURE2D(_Channel0);
        SAMPLER(sampler_Channel0);
        static const int NUM_OCTAVES = 4;
        static const float NUM_STEPS = 4.0;
        static const float FLAME_SIZE = 5.7;

        float NoiseTexel(int2 ip)
        {
            int2 p = int2(ip.x & 255, ip.y & 255);
            return _Channel0.Load(int3(p, 0)).x;
        }

        float Noise2D(float2 x)
        {
            int2 p = (int2)floor(x);
            float2 f = frac(x);
            f = f * f * (3.0 - 2.0 * f);

            float rgA = NoiseTexel(p + int2(0, 0));
            float rgB = NoiseTexel(p + int2(1, 0));
            float rgC = NoiseTexel(p + int2(0, 1));
            float rgD = NoiseTexel(p + int2(1, 1));

            return lerp(lerp(rgA, rgB, f.x), lerp(rgC, rgD, f.x), f.y);
        }

        float ComputeFBM(float2 pos)
        {
            float amplitude = 1.0;
            float sum = 0.0;
            float maxAmp = 0.0;
            [loop]
            for (int i = 0; i < NUM_OCTAVES; ++i)
            {
                sum += Noise2D(pos) * amplitude;
                maxAmp += amplitude;
                amplitude *= 0.5;
                pos *= 2.0;
            }
            return sum / maxAmp;
        }

        float3 firePaletteCheap(float i)
        {
            return pow(float3(1.65, 1.2, 1.0) * i, float3(1.0, 2.5, 12.0));
        }

        float4 Frag(Varyings i) : SV_Target
        {
            float2 fragCoord = i.uv * _STResolution.xy;
            float2 ndc = (2.0 * fragCoord - _STResolution.xy) / _STResolution.y;
            float uvy = (ndc.y + 1.0) * 0.5;

            float noise = ComputeFBM(ndc * float2(2.0, 1.0) * 3.5 + float2(0.0, -_STTime * 7.0));
            float noise2 = ComputeFBM(ndc + float2(-_STTime * sin(_STTime * 0.005) * 0.3 - 50.0, 121.0));
            noise *= pow(max(noise2, 1e-4), 0.55);

            float2 mouseEffect = float2(1.4, 0.85);
            noise *= (FLAME_SIZE - pow(uvy * 21.0 * mouseEffect.y + abs(ndc.x) * 14.0, 0.57) * mouseEffect.x);

            noise = saturate(noise);
            noise = floor(noise * NUM_STEPS) / NUM_STEPS;
            float3 fireColor = firePaletteCheap(noise);
            return float4(fireColor, 1.0);
        }


        float4 RenderShadertoy(float2 fragCoord)
        {
            Varyings input = (Varyings)0;
            input.uv = fragCoord / _STResolution.xy;
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
