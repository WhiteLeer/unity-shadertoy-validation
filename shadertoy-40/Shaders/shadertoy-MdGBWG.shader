Shader "Shadertoy/MdGBWG_GlobalWindCirculation"
{
    Properties
    {
        _STResolution("ST Resolution", Vector) = (512,288,0.001953125,0.003472222)
        _STMouse("ST Mouse", Vector) = (0,0,0,0)
        _STTime("ST Time", Float) = 0
        _LandTex("Land", 2D) = "black" {}
        _BufferBTex("BufferB", 2D) = "black" {}
        _BufferCTex("BufferC", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode"="UniversalForward" }
            Cull Off ZWrite Off ZTest Always
            HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _STResolution;
                float4 _STMouse;
                float _STTime;
            CBUFFER_END

            sampler2D _LandTex;
            sampler2D _BufferBTex;
            sampler2D _BufferCTex;

            #define MAPRES float2(144.0,72.0)
            #define PASS3 float2(0.5,0.0)
            #define PASS4 float2(0.5,0.5)
            #define PAPER
            #define LOW_PRESSURE float3(0.0,0.5,1.0)
            #define HIGH_PRESSURE float3(1.0,0.5,0.0)

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; float2 fragCoord : TEXCOORD1; };

            float3 RenderMain(float2 fragCoord)
            {
                float2 p = fragCoord * MAPRES / _STResolution.xy;
                if (p.x < 1.0) p.x = 1.0;
                float2 uv = p / _STResolution.xy;
                float land = tex2D(_LandTex, uv).x;
                float3 rgb = 0.0.xxx;
                if (0.25 < land && land < 0.75) rgb = 0.5.xxx;

                float mbar = tex2D(_BufferBTex, uv + PASS3).x;
                if (_STMouse.z > 0.0)
                {
                    float3 r = LOW_PRESSURE;
                    r = lerp(r, 0.0.xxx, smoothstep(1000.0, 1012.0, floor(mbar)));
                    r = lerp(r, HIGH_PRESSURE, smoothstep(1012.0, 1024.0, floor(mbar)));
                    rgb += 0.5 * r;
                }
                else
                {
                    float2 v = tex2D(_BufferBTex, uv + PASS4).xy;
                    float flow = tex2D(_BufferCTex, fragCoord / _STResolution.xy).z;
                    float3 hue = float3(1.0, 0.75, 0.5);
                    float alpha = clamp(length(v), 0.0, 1.0) * flow;
                    rgb = lerp(rgb, hue, alpha);
                }

                rgb = 0.9 - 0.8 * rgb;
                float gx = fmod(fragCoord.x, floor(_STResolution.x / 36.0));
                float gy = fmod(fragCoord.y, floor(_STResolution.y / 18.0));
                if (gx < 1.0 || gy < 1.0)
                    rgb = lerp(rgb, float3(0.0, 0.5, 1.0), 0.2);
                return rgb;
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
                return float4(RenderMain(IN.fragCoord), 1.0);
            }
            ENDHLSL
        }
    }
}
