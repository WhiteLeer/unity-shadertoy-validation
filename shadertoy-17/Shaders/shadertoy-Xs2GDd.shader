Shader "Shadertoy/Xs2GDd_Cellular"
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
        static const float kPi = 3.14159265359;

        float Disk(float2 r, float2 center, float radius)
        {
            return 1.0 - smoothstep(radius - 0.008, radius + 0.008, length(r - center));
        }

        float3 RenderMain(float2 fragCoord)
        {
            float3 col1 = float3(0.216, 0.471, 0.698);
            float3 col2 = float3(1.0, 0.329, 0.298);
            float3 col3 = float3(0.867, 0.910, 0.247);

            float t = _STTime * 2.0;
            float2 r = (2.0 * fragCoord - _STResolution.xy) / _STResolution.y;
            r *= 1.0 + 0.05 * sin(r.x * 5.0 + _STTime) + 0.05 * sin(r.y * 3.0 + _STTime);
            r *= 1.0 + 0.2 * length(r);

            float side = 0.5;
            float2 r2 = fmod(r, side.xx);
            if (r2.x < 0.0) r2.x += side;
            if (r2.y < 0.0) r2.y += side;
            float2 r3 = r2 - side * 0.5;
            float i = floor(r.x / side) + 2.0;
            float j = floor(r.y / side) + 4.0;
            float ii = r.x / side + 2.0;
            float jj = r.y / side + 4.0;

            float3 pix = float3(1.0, 1.0, 1.0);
            float rad;
            float disks;

            rad = 0.15 + 0.05 * sin(t + ii * jj);
            disks = Disk(r3, float2(0.0, 0.0), rad);
            pix = lerp(pix, col2, disks);

            float speed = 2.0;
            float tt = _STTime * speed + 0.1 * i + 0.08 * j;
            float stopEveryAngle = PI / 2.0;
            float stopRatio = 0.7;
            float t1 = (floor(tt) + smoothstep(0.0, 1.0 - stopRatio, frac(tt))) * stopEveryAngle;

            float x = -0.07 * cos(t1 + i);
            float y = 0.055 * (sin(t1 + j) + cos(t1 + i));
            rad = 0.1 + 0.05 * sin(t + i + j);
            disks = Disk(r3, float2(x, y), rad);
            pix = lerp(pix, col1, disks);

            rad = 0.2 + 0.05 * sin(t * (1.0 + 0.01 * i));
            disks = Disk(r3, float2(0.0, 0.0), rad);
            pix += 0.2 * col3 * disks * sin(t + i * j + i);

            pix -= smoothstep(0.3, 5.5, length(r));
            return pix;
        }

        half4 Frag(Varyings IN) : SV_Target
        {
            return float4(RenderMain(IN.fragCoord), 1.0);
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