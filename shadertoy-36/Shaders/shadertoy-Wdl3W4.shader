Shader "Shadertoy/Wdl3W4_SimpleRosePetal"
{
    Properties
    {
        _STResolution("ST Resolution", Vector) = (512,288,0.001953125,0.003472222)
        _STMouse("ST Mouse", Vector) = (0,0,0,0)
        _STTime("ST Time", Float) = 0
        _STDeltaTime("ST DeltaTime", Float) = 0
        _STFrame("ST Frame", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode"="UniversalForward" }
            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _STResolution;
                float4 _STMouse;
                float _STTime;
                float _STDeltaTime;
                float _STFrame;
            CBUFFER_END

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; float2 fragCoord : TEXCOORD1; };

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
                float3 col = 0.85.xxx;
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
                float3 ta = 0.0.xxx;
                float3 cu, cv, cw;
                SetCamera(ro, ta, 0.0, cu, cv, cw);
                float3 rd = normalize(cu * p.x + cv * p.y + cw * 8.0);

                float3 col = Render(ro, rd);
                return float4(col, 1.0);
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
                return RenderMain(IN.fragCoord);
            }
            ENDHLSL
        }
    }
}
