Shader "Shadertoy/w32XzG_GlobulesBubbles"
{
    Properties
    {
        [MainTexture] _BaseMap("Texture", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        _Cutoff("AlphaCutout", Range(0.0, 1.0)) = 0.5
        _Surface("__surface", Float) = 0.0
        _STResolution("ST Resolution", Vector) = (960, 540, 0.001041667, 0.001851852)
        _STMouse("ST Mouse", Vector) = (0, 0, 0, 0)
        _STTime("ST Time", Float) = 0
        _STFrame("ST Frame", Float) = 0
    }

    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half _Cutoff;
            float _Surface;
            float4 _STResolution;
            float4 _STMouse;
            float _STTime;
            float _STFrame;
        CBUFFER_END

#define ST_R _STResolution.xy
#define ST_H(v) frac(1e4 * sin(1e4 * (i)))

float4 ST_Hue(float v)
{
    return 0.6 + 0.6 * cos(6.3 * v + float4(0, 23, 21, 0));
}

float PushHole(float2 U, out float depth)
{
    float pushDistance = 0.15;
    float slope = 2.0;
    float2 mouse = _STMouse.xy;

    if (length(mouse) > 10.0)
    {
        mouse /= ST_R;
        pushDistance = mouse.y;
        slope = 1.0 / (0.01 + mouse.x);
    }

    depth = pushDistance / length(U);
    return depth > 1.0 ? 0.0 : pow(1.0 - pow(depth, slope), 1.0 / slope);
}

float4 RenderGlobulesBubbles(float2 fragCoord)
{
    float2 R = _STResolution.xy;
    float2 U = (2.0 * fragCoord - R) / R.y;
    float4 O = float4(0, 0, 0, 0);
    float2 V;
    float2 P;
    float v;
    float i = 1.0;
    float d = 1.0;

    [loop]
    for (int iter = 0; iter < 200; ++iter)
    {
        P = (
            float2(cos(_STTime / 4.0 + i * 17.0), sin(_STTime / 4.0 * 1.3 - i * 3.0))
            + float2(sin(-_STTime / 4.0 * 1.5 + i * 13.0), cos(_STTime / 4.0 * 2.1 - i * 7.0))
        ) / 2.0 * R / R.y;

        V = U - P;

        float localDepth;
        v = PushHole(V, localDepth);
        d = min(d, abs(localDepth - 1.0) / min(1.0, fwidth(localDepth)));

        if (v == 0.0 && all(O == (O - O)))
        {
            O = 0.3 + 0.8 * ST_Hue(i / 100.0);
        }

        U = P + v * V;
        i += 1.0;
    }

    O *= smoothstep(0.0, 1.5, d);
    return O;
}


        ENDHLSL

        Pass
        {
            Name "ForwardUnlit"
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #define SHADERTOY_RENDER_FUNCTION RenderGlobulesBubbles
            #include "../../Common/Shaders/ShadertoyURPForwardPass.hlsl"
            ENDHLSL
        }
    }
}