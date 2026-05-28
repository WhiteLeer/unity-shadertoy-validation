Shader "Shadertoy/7sscW4_MoreFractalRopes"
{
    Properties
    {
        _Channel0("Channel0 Cubemap", Cube) = "" {}
        _Mouse("Mouse", Vector) = (0,0,0,0)
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
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURECUBE(_Channel0);
            SAMPLER(sampler_Channel0);

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            Varyings Vert(Attributes input)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                o.uv = input.uv;
                return o;
            }

            #define vec2 float2
            #define vec3 float3
            #define vec4 float4
            #define mat2 float2x2
            #define S smoothstep
            #define T iTime
            #define texture(tex,uv) SAMPLE_TEXTURECUBE(_Channel0, sampler_Channel0, uv)

            float3 iResolution;
            float iTime;
            float4 iMouse;
            float4 _Mouse;

            #define MAX_STEPS 400
            #define MAX_DIST 10.
            #define SURF_DIST .001

            #define pi 3.14159

            float thc(float a, float b) {
                return tanh(a * cos(b)) / tanh(a);
            }

            float ths(float a, float b) {
                return tanh(a * sin(b)) / tanh(a);
            }

            vec2 thc2(float a, vec2 b) {
                return tanh(a * cos(b)) / tanh(a);
            }

            vec2 ths2(float a, vec2 b) {
                return tanh(a * sin(b)) / tanh(a);
            }

            vec3 pal(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d)
            {
                return a + b * cos(6.28318 * (c * t + d));
            }

            float h21(vec2 a) {
                return frac(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
            }

            float mlength(vec2 uv) {
                return max(abs(uv.x), abs(uv.y));
            }

            mat2 Rot(float a) {
                float s = sin(a), c = cos(a);
                return mat2(c, -s, s, c);
            }

            float GetDist(vec3 p) {
                vec2 uv = p.xz;

                uv.x = abs(uv.x);
                float time = 12. + iTime;
                vec2 q = vec2(1, 0);

                float th = 0.4 * p.y - 0.6 * time;
                float n = 9.;
                float m = -0.0 * length(uv) + 1.8;
                for (float i = 0.; i < n; i++) {
                    uv -= m * q;
                    th += 0.5 * p.y + 0.05 * time;
                    uv = mul(Rot(th), uv);
                    uv.x = abs(uv.x);
                    m *= 0.05 * cos(8. * length(uv)) + 0.55;
                }

                float d = length(uv) - 2. * m;
                return 0.5 * d;
            }

            float RayMarch(vec3 ro, vec3 rd) {
                float dO = 0.;

                [loop]
                for (int i = 0; i < MAX_STEPS; i++) {
                    vec3 p = ro + rd * dO;
                    float dS = GetDist(p);
                    dO += dS;
                    if (dO > MAX_DIST || abs(dS) < SURF_DIST) break;
                }

                return dO;
            }

            vec3 GetNormal(vec3 p) {
                float d = GetDist(p);
                vec2 e = vec2(.001, 0);

                vec3 n = d - vec3(
                    GetDist(p - e.xyy),
                    GetDist(p - e.yxy),
                    GetDist(p - e.yyx));

                return normalize(n);
            }

            vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
                vec3 f = normalize(l - p),
                    r = normalize(cross(vec3(0, 1, 0), f)),
                    u = cross(f, r),
                    c = f * z,
                    i = c + uv.x * r + uv.y * u,
                    d = normalize(i);
                return d;
            }

            void mainImage(out vec4 fragColor, in vec2 fragCoord)
            {
                vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
                vec2 m = iMouse.xy / iResolution.xy;

                float rr = 5.5;
                float time = 0. * iTime;
                vec3 ro = vec3(rr * cos(time), 0.1 * iTime, rr * sin(time));

                vec3 rd = GetRayDir(uv, ro, vec3(0, 0.1 * iTime, 0), 2.);
                vec3 col = vec3(0, 0, 0);

                float d = RayMarch(ro, rd);

                if (d < MAX_DIST) {
                    vec3 p = ro + rd * d;
                    vec3 n = GetNormal(p);
                    vec3 r = reflect(rd, n);

                    float ambient = .3;
                    float difPower = .4;
                    float dif = max(dot(n, normalize(vec3(1, 2, 3))), 0.);
                    col = vec3(dif * difPower + ambient, dif * difPower + ambient, dif * difPower + ambient);

                    col *= texture(iChannel0, r).rgb;
                    col *= 1. + r.y;
                    col = clamp(col, 0., 1.);

                    vec3 e = vec3(1., 1., 1.);
                    col *= pal(r.y, e, e, e, 0.35 * vec3(0., 0.33, 0.66));
                }

                col = pow(col, vec3(.4545, .4545, .4545));

                fragColor = vec4(col, 1.0);
            }

            float4 Frag(Varyings input) : SV_Target
            {
                iResolution = float3(_ScreenParams.xy, 1.0);
                iTime = _Time.y;
                iMouse = _Mouse;

                float4 col = 0;
                mainImage(col, input.uv * iResolution.xy);
                return col;
            }

            ENDHLSL
        }
    }
}
