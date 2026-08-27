Shader "Shadertoy/XtGGRt_Auroras"
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
        _Mouse("Mouse", Vector) = (0,0,0,0)
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
        float4 _Mouse;

        #define iTime _STTime
        #define iResolution _STResolution

        float2x2 mm2(float a)
        {
            float c = cos(a), s = sin(a);
            return float2x2(c, s, -s, c);
        }

        static const float2x2 m2 = float2x2(0.95534, 0.29552, -0.29552, 0.95534);

        float tri(float x) { return clamp(abs(frac(x) - 0.5), 0.01, 0.49); }

        float2 tri2(float2 p)
        {
            return float2(tri(p.x) + tri(p.y), tri(p.y + tri(p.x)));
        }

        float triNoise2d(float2 p, float spd)
        {
            float z = 1.8;
            float z2 = 2.5;
            float rz = 0.0;
            p = mul(mm2(p.x * 0.06), p);
            float2 bp = p;

            [unroll(5)]
            for (int k = 0; k < 5; k++)
            {
                float2 dg = tri2(bp * 1.85) * 0.75;
                dg = mul(mm2(iTime * spd), dg);
                p -= dg / z2;

                bp *= 1.3;
                z2 *= 0.45;
                z *= 0.42;
                p *= 1.21 + (rz - 1.0) * 0.02;

                rz += tri(p.x + tri(p.y)) * z;
                p = mul(-m2, p);
            }

            return clamp(1.0 / pow(rz * 29.0, 1.3), 0.0, 0.55);
        }

        float hash21(float2 n)
        {
            return frac(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453);
        }

        float4 aurora(float3 ro, float3 rd, float2 fragCoord)
        {
            float4 col = 0;
            float4 avgCol = 0;

            [loop]
            for (int k = 0; k < 50; k++)
            {
                float i = (float)k;
                float of = 0.006 * hash21(fragCoord.xy) * smoothstep(0.0, 15.0, i);
                float pt = ((0.8 + pow(i, 1.4) * 0.002) - ro.y) / (rd.y * 2.0 + 0.4);
                pt -= of;
                float3 bpos = ro + pt * rd;
                float2 p = bpos.zx;
                float rzt = triNoise2d(p, 0.06);

                float4 col2 = float4(0, 0, 0, rzt);
                col2.rgb = (sin(1.0 - float3(2.15, -0.5, 1.2) + i * 0.043) * 0.5 + 0.5) * rzt;
                avgCol = lerp(avgCol, col2, 0.5);
                col += avgCol * exp2(-i * 0.065 - 2.5) * smoothstep(0.0, 5.0, i);
            }

            col *= clamp(rd.y * 15.0 + 0.4, 0.0, 1.0);
            return col * 1.8;
        }

        float3 nmzHash33(float3 q)
        {
            q = frac(q * float3(0.1031, 0.11369, 0.13787));
            q += dot(q, q.yxz + 19.19);
            return frac((q.xxy + q.yxx) * q.zyx);
        }

        float3 stars(float3 p)
        {
            float3 c = 0;
            float res = iResolution.x;

            [unroll(4)]
            for (int k = 0; k < 4; k++)
            {
                float i = (float)k;
                float3 q = frac(p * (0.15 * res)) - 0.5;
                float3 id = floor(p * (0.15 * res));
                float2 rn = nmzHash33(id).xy;
                float c2 = 1.0 - smoothstep(0.0, 0.6, length(q));
                c2 *= step(rn.x, 0.0005 + i * i * 0.001);
                c += c2 * (lerp(float3(1.0, 0.49, 0.1), float3(0.75, 0.9, 1.0), rn.y) * 0.1 + 0.9);
                p *= 1.3;
            }
            return c * c * 0.8;
        }

        float3 bg(float3 rd)
        {
            float sd = dot(normalize(float3(-0.5, -0.6, 0.9)), rd) * 0.5 + 0.5;
            sd = pow(sd, 5.0);
            float3 col = lerp(float3(0.05, 0.1, 0.2), float3(0.1, 0.05, 0.2), sd);
            return col * 0.63;
        }

        float4 Frag(Varyings i) : SV_Target
        {
            float2 fragCoord = i.uv * iResolution.xy;
            float2 q = fragCoord.xy / iResolution.xy;
            float2 p = q - 0.5;
            p.x *= iResolution.x / iResolution.y;

            float3 ro = float3(0, 0, -6.7);
            float3 rd = normalize(float3(p, 1.3));
            float2 mo = _Mouse.xy / iResolution.xy - 0.5;
            if (all(mo == float2(-0.5, -0.5))) mo = float2(-0.1, 0.1);
            mo.x *= iResolution.x / iResolution.y;

            rd.yz = mul(mm2(mo.y), rd.yz);
            rd.xz = mul(mm2(mo.x + sin(iTime * 0.05) * 0.2), rd.xz);

            float3 col = 0;
            float3 brd = rd;
            float fade = smoothstep(0.0, 0.01, abs(brd.y)) * 0.1 + 0.9;

            col = bg(rd) * fade;

            if (rd.y > 0.0)
            {
                float4 aur = smoothstep(0.0, 1.5, aurora(ro, rd, fragCoord)) * fade;
                col += stars(rd);
                col = col * (1.0 - aur.a) + aur.rgb;
            }
            else
            {
                rd.y = abs(rd.y);
                col = bg(rd) * fade * 0.6;
                float4 aur = smoothstep(0.0, 2.5, aurora(ro, rd, fragCoord));
                col += stars(rd) * 0.1;
                col = col * (1.0 - aur.a) + aur.rgb;
                float3 pos = ro + ((0.5 - ro.y) / rd.y) * rd;
                float nz2 = triNoise2d(pos.xz * float2(0.5, 0.7), 0.0);
                col += lerp(float3(0.2, 0.25, 0.5) * 0.08, float3(0.3, 0.3, 0.5) * 0.7, nz2 * 0.4);
            }

            col = max(col, 0.0);
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