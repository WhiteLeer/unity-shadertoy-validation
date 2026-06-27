Shader "Shadertoy/MdGBWG_BufferC"
{
    Properties
    {
        _STResolution("ST Resolution", Vector) = (512,288,0.001953125,0.003472222)
        _SimFrame("Sim Frame", Float) = 0
        _PrevCTex("PrevC", 2D) = "black" {}
        _BufferBTex("BufferB", 2D) = "black" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
        }
        Pass
        {
            Name "BufferC"
            Cull Off ZWrite Off ZTest Always
            HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _STResolution;
                float _SimFrame;
            CBUFFER_END

            sampler2D _PrevCTex;
            sampler2D _BufferBTex;

            #define MAPRES float2(144.0,72.0)
            #define HASHSCALE1 0.1031
            #define HASHSCALE3 float3(0.1031, 0.1030, 0.0973)

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 fragCoord : TEXCOORD1;
            };

            float Hash13(float3 p3)
            {
                p3 = frac(p3 * HASHSCALE1);
                p3 += dot(p3, p3.yzx + 19.19);
                return frac((p3.x + p3.y) * p3.z);
            }

            float2 Hash21(float p)
            {
                float3 p3 = frac(float3(p, p, p) * HASHSCALE3);
                p3 += dot(p3, p3.yzx + 19.19);
                return frac((p3.xx + p3.yz) * p3.zy);
            }

            float2 GetVelocity(float2 uv)
            {
                float2 p = uv * MAPRES;
                if (p.x < 1.0) p.x = 1.0;
                float2 v = tex2D(_BufferBTex, p / _STResolution.xy + float2(0.5, 0.5)).xy;
                if (length(v) > 1.0) v = normalize(v);
                return v;
            }

            float2 GetPosition(float2 fragCoord)
            {
                [loop] for (int i = -1; i <= 1; i++)
                {
                    [loop] for (int j = -1; j <= 1; j++)
                    {
                        float2 uv = (fragCoord + float2((float)i, (float)j)) / _STResolution.xy;
                        float2 p = tex2D(_PrevCTex, frac(uv)).xy;
                        if (all(abs(p) < 1e-6))
                        {
                            if (Hash13(float3(fragCoord + float2((float)i, (float)j), _SimFrame)) > 1e-4) continue;
                            p = fragCoord + float2((float)i, (float)j) + Hash21(_SimFrame) - 0.5;
                        }
                        else if (Hash13(float3(fragCoord + float2((float)i, (float)j), _SimFrame)) < 8e-3)
                        {
                            continue;
                        }

                        float2 v = GetVelocity(uv);
                        p = p + v;
                        p.x = fmod(p.x, _STResolution.x);
                        if (p.x < 0.0) p.x += _STResolution.x;
                        if (abs(p.x - fragCoord.x) < 0.5 && abs(p.y - fragCoord.y) < 0.5)
                            return p;
                    }
                }
                return float2(0.0, 0.0);
            }

            Varyings Vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                OUT.fragCoord = IN.uv * _STResolution.xy;
                return OUT;
            }

            half4 Frag(Varyings IN) : SV_Target
            {
                float4 outCol = float4(0.0, 0.0, 0.0, 0.0);
                outCol.xy = GetPosition(IN.fragCoord);
                outCol.z = 0.9 * tex2D(_PrevCTex, IN.fragCoord / _STResolution.xy).z;
                if (outCol.x > 0.0) outCol.z = 1.0;
                return outCol;
            }
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