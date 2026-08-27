Shader "Shadertoy/4dXGR4_MainSequenceStar"
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
        _Channel0("Channel0 Texture", 2D) = "white" {}
        _Channel1("Channel1 AudioTex", 2D) = "white" {}
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
        TEXTURE2D(_Channel1);
        SAMPLER(sampler_Channel1);

        float snoise(float3 uv, float res)
        {
            const float3 s = float3(1e0, 1e2, 1e4);
            uv *= res;

            float3 uv0 = floor(ModGLSL(uv, res)) * s;
            float3 uv1 = floor(ModGLSL(uv + float3(1.0, 1.0, 1.0), res)) * s;

            float3 f = frac(uv);
            f = f * f * (3.0 - 2.0 * f);

            float4 v = float4(
                uv0.x + uv0.y + uv0.z,
                uv1.x + uv0.y + uv0.z,
                uv0.x + uv1.y + uv0.z,
                uv1.x + uv1.y + uv0.z
            );

            float4 r = frac(sin(v * 1e-3) * 1e5);
            float r0 = lerp(lerp(r.x, r.y, f.x), lerp(r.z, r.w, f.x), f.y);

            r = frac(sin((v + uv1.z - uv0.z) * 1e-3) * 1e5);
            float r1 = lerp(lerp(r.x, r.y, f.x), lerp(r.z, r.w, f.x), f.y);

            return lerp(r0, r1, f.z) * 2.0 - 1.0;
        }

        float sampleAudio(float2 uv)
        {
            return SAMPLE_TEXTURE2D_LOD(_Channel1, sampler_Channel1, uv, 0).x;
        }

        void mainImage(out float4 fragColor, in float2 fragCoord)
        {
            float freqs0 = sampleAudio(float2(0.01, 0.25));
            float freqs1 = sampleAudio(float2(0.07, 0.25));
            float freqs2 = sampleAudio(float2(0.15, 0.25));
            float freqs3 = sampleAudio(float2(0.30, 0.25));

            float brightness = freqs1 * 0.25 + freqs2 * 0.25;
            float radius = 0.24 + brightness * 0.2;
            float invRadius = 1.0 / max(radius, 1e-4);

            float3 orange = float3(0.8, 0.65, 0.3);
            float3 orangeRed = float3(0.8, 0.35, 0.1);
            float time = iTime * 0.1;
            float aspect = iResolution.x / iResolution.y;
            float2 uv = fragCoord.xy / iResolution.xy;
            float2 p = -0.5 + uv;
            p.x *= aspect;

            float fade = pow(length(2.0 * p), 0.5);
            float fVal1 = 1.0 - fade;
            float fVal2 = 1.0 - fade;

            float angle = AtanGLSL(p.x, p.y) / 6.2832;
            float dist = length(p);
            float3 coord = float3(angle, dist, time * 0.1);

            float newTime1 = abs(snoise(coord + float3(0.0, -time * (0.35 + brightness * 0.001), time * 0.015), 15.0));
            float newTime2 = abs(snoise(coord + float3(0.0, -time * (0.15 + brightness * 0.001), time * 0.015), 45.0));

            [loop]
            for (int i = 1; i <= 7; i++)
            {
                float power = pow(2.0, i + 1.0);
                fVal1 += (0.5 / power) * snoise(coord + float3(0.0, -time, time * 0.2),
                               power * 10.0 * (newTime1 + 1.0));
                fVal2 += (0.5 / power) * snoise(coord + float3(0.0, -time, time * 0.2),
       power * 25.0 * (newTime2 + 1.0));
            }

            float corona = pow(fVal1 * max(1.1 - fade, 0.0), 2.0) * 50.0;
            corona += pow(fVal2 * max(1.1 - fade, 0.0), 2.0) * 50.0;
            corona *= 1.2 - newTime1;

            float3 starSphere = float3(0.0, 0.0, 0.0);

            float2 sp = -1.0 + 2.0 * uv;
            sp.x *= aspect;
            sp *= (2.0 - brightness);
            float r = dot(sp, sp);
            float f = (1.0 - sqrt(abs(1.0 - r))) / max(r, 1e-4) + brightness * 0.5;

            if (dist < radius)
            {
                corona *= pow(dist * invRadius, 24.0);
                float2 newUv;
                newUv.x = sp.x * f;
                newUv.y = sp.y * f;
                newUv += float2(time, 0.0);

                float3 texSample = SAMPLE_TEXTURE2D_LOD(_Channel0, sampler_Channel0, newUv, 0).rgb;
                float uOff = texSample.g * brightness * 4.5 + time;
                float2 starUV = newUv + float2(uOff, 0.0);
                starSphere = SAMPLE_TEXTURE2D_LOD(_Channel0, sampler_Channel0, starUV, 0).rgb;
            }

            float starGlow = saturate(1.0 - dist * (1.0 - brightness));
            fragColor.rgb = float3(f * (0.75 + brightness * 0.3) * orange) + starSphere + corona * orange + starGlow *
                orangeRed;
            fragColor.a = 1.0;
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
    }
}