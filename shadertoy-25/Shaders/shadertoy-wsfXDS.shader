Shader "Shadertoy/wsfXDS_SousLOcean"
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

        _STResolution("ST Resolution", Vector) = (512,288,0.001953125,0.003472222)
        _STTime("ST Time", Float) = 0
    }

    SubShader
    {
        Blend [_SrcBlend][_DstBlend], [_SrcBlendAlpha][_DstBlendAlpha]
        ZWrite [_ZWrite]
        Cull [_Cull]

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half _Cutoff;
            half _Surface;
            float4 _STResolution;
            float _STTime;
        CBUFFER_END

        #define ST_PI 3.141592

        void Moda(inout float2 uv, float rep)
        {
            float per = 2.0 * ST_PI / rep;
            float a = atan2(uv.y, uv.x);
            float l = length(uv);
            a = fmod(a - per * 0.5, per) - per * 0.5;
            uv = float2(cos(a), sin(a)) * l;
        }

        float2x2 Rot(float a)
        {
            float s = sin(a);
            float c = cos(a);
            return float2x2(c, s, -s, c);
        }

        float2 Rand(float2 x)
        {
            return frac(sin(float2(dot(x, float2(1.2, 5.5)), dot(x, float2(4.54, 2.41)))) * 4.45);
        }

        float3 Voro(float2 uv)
        {
            float2 uv_id = floor(uv);
            float2 uv_st = frac(uv);

            float2 m_diff = float2(0.0, 0.0);
            float2 m_point = float2(0.0, 0.0);
            float2 m_neighbor = float2(0.0, 0.0);
            float m_dist = 10.0;

            [unroll]
            for (int j = -1; j <= 1; j++)
            {
                [unroll]
                for (int i = -1; i <= 1; i++)
                {
                    float2 neighbor = float2((float)i, (float)j);
                    float2 cellPoint = Rand(uv_id + neighbor);
                    cellPoint = 0.5 + 0.5 * sin(2.0 * ST_PI * cellPoint + _STTime);
                    float2 diff = neighbor + cellPoint - uv_st;

                    float dist = length(diff);
                    if (dist < m_dist)
                    {
                        m_dist = dist;
                        m_point = cellPoint;
                        m_diff = diff;
                        m_neighbor = neighbor;
                    }
                }
            }

            m_dist = 10.0;
            [unroll]
            for (int j = -2; j <= 2; j++)
            {
                [unroll]
                for (int i = -2; i <= 2; i++)
                {
                    if (i == 0 && j == 0) continue;
                    float2 neighbor = m_neighbor + float2((float)i, (float)j);
                    float2 cellPoint = Rand(uv_id + neighbor);
                    cellPoint = 0.5 + 0.5 * sin(cellPoint * 2.0 * ST_PI + _STTime);
                    float2 diff = neighbor + cellPoint - uv_st;
                    float dist = dot(0.5 * (m_diff + diff), normalize(diff - m_diff));
                    m_point = cellPoint;
                    m_dist = min(m_dist, dist);
                }
            }

            return float3(m_point, m_dist);
        }

        float3 BlueGrid(float2 uv, float detail)
        {
            uv *= detail;
            float3 v = Voro(uv);
            return saturate(float3(v.x * 0.8, v.y, 1.0) * smoothstep(0.05, 0.07, v.z));
        }

        float3 GreenGrid(float2 uv, float detail)
        {
            uv *= detail;
            float3 v = Voro(uv);
            return saturate(float3(v.x, 1.0, v.y) * smoothstep(0.05, 0.07, v.z));
        }

        float3 RedGrid(float2 uv, float detail)
        {
            uv *= detail;
            float3 v = Voro(uv);
            return saturate(float3(1.0, v.x, v.y) * smoothstep(0.05, 0.07, v.z));
        }

        float3 MagentaGrid(float2 uv, float detail)
        {
            uv *= detail;
            float3 v = Voro(uv);
            return saturate(float3(1.0, v.y * 0.8, v.x * 4.0) * smoothstep(0.05, 0.07, v.z));
        }

        float GroundMask1(float2 uv, float offset)
        {
            uv.y += 0.2;
            uv.y += sin(uv.x * 3.0) * 0.08;
            return step(uv.y, 0.0 - offset);
        }

        float GroundMask2(float2 uv, float offset)
        {
            uv.y += 0.37;
            uv.y -= sin(uv.x * 3.0) * 0.08;
            return step(uv.y, 0.0 - offset);
        }

        float SeaweedMask(float2 uv, float offset)
        {
            float2 uu = uv;
            uv.x = abs(uv.x);
            uv.x -= 0.7;
            uv.y += 0.8;
            uv.x += sin(uv.y * 8.0 + _STTime) * 0.05;
            float lineA = step(abs(uv.x), (0.1 - uv.y * 0.1) - offset);

            uv = uu;
            uv.x = abs(uv.x);
            uv.x -= 0.4;
            uv.y += 1.1;
            uv.x += sin(uv.y * 4.0 - _STTime) * 0.05;
            float lineB = step(abs(uv.x), (0.1 - uv.y * 0.1) - offset);

            uv = uu;
            uv.y += 1.8;
            uv.x += sin(uv.y * 4.0 - _STTime) * 0.05;
            float lineC = step(abs(uv.x), (0.2 - uv.y * 0.1) - offset);
            return lineA + lineB + lineC;
        }

        float SunMask(float2 uv, float offset)
        {
            uv -= float2(0.4, 0.2);
            uv = mul(Rot(_STTime * 0.15), uv);
            float s = step(length(uv), 0.18 - offset);

            Moda(uv, 5.0);
            float l = step(abs(uv.y), (0.02 + uv.x * 0.1) - offset);
            return s + l;
        }

        float3 Ground(float2 uv)
        {
            float m1 = saturate(GroundMask1(uv, 0.01) - GroundMask2(uv, 0.0) - SeaweedMask(uv, 0.0));
            float m2 = saturate(GroundMask2(uv, 0.01) - SeaweedMask(uv, 0.0));
            return RedGrid(uv, 28.0) * m2 + MagentaGrid(uv, 20.0) * m1;
        }

        float3 Seaweed(float2 uv)
        {
            return GreenGrid(uv, 35.0) * SeaweedMask(uv, 0.01);
        }

        float3 Sun(float2 uv)
        {
            float m1 = saturate(
                SunMask(uv, 0.01) - (GroundMask1(uv, 0.0) + GroundMask2(uv, 0.0) + SeaweedMask(uv, 0.0)));
            return RedGrid(mul(Rot(_STTime * 0.15), (uv - float2(0.4, 0.2))), 18.0) * m1;
        }

        float3 Sky(float2 uv)
        {
            float m1 = saturate(
                1.0 - (GroundMask1(uv, 0.0) + GroundMask2(uv, 0.0) + SeaweedMask(uv, 0.0) + SunMask(uv, 0.0)));
            return BlueGrid(uv, 13.0) * m1;
        }

        float3 Framed(float2 uv)
        {
            return Ground(uv) + Seaweed(uv) + Sky(uv) + Sun(uv);
        }

        float4 RenderOcean(float2 fragCoord)
        {
            float2 uv = fragCoord / _STResolution.xy;
            uv -= 0.5;
            uv /= float2(_STResolution.y / _STResolution.x, 1.0);
            return float4(Framed(uv), 1.0);
        }

        float4 RenderCrystal(float2 fragCoord)
        {
            return RenderOcean(fragCoord);
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
            #include "../../Common/Shaders/CrystalUnlitForwardPass.hlsl"
            ENDHLSL
        }
    }
}
