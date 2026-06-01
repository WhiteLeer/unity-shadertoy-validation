Shader "Shadertoy/ttXSzl_BufferA"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        Pass
        {
            Name "BufferA"
            Tags { "LightMode"="UniversalForward" }
            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };

            float4 _STResolution;
            float _STTime;

            struct Ray { float3 o; float3 d; };

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float IntersectSphere(out float3 normal, Ray v, float3 o, float r2)
            {
                float3 g = v.o - o;
                float a = dot(v.d, v.d);
                float b = 2.0 * dot(g, v.d);
                float c = dot(g, g) - r2;
                float disc = b * b - 4.0 * a * c;
                if (disc < 0.0) return -1.0;
                float d = sqrt(disc);
                float t0 = (-b - d) / (2.0 * a);
                float3 w = g + t0 * v.d;
                normal = normalize(w);
                return t0;
            }

            float IntersectCube(out float3 normal, Ray r, float3 o, float3 s)
            {
                float3 rcp = 1.0 / r.d;
                float3 a = rcp * (o - r.o);
                float3 ta = a - abs(rcp) * s;
                float3 tb = a + abs(rcp) * s;

                float tn = max(max(ta.x, ta.y), ta.z);
                float tf = min(min(tb.x, tb.y), tb.z);
                if (tf < max(0.001, tn)) return -1.0;

                float3 lessThan1 = step(ta.yzx, ta.xyz);
                float3 lessThan2 = step(ta.zxy, ta.xyz);
                normal = -sign(r.d) * lessThan1 * lessThan2;
                return tn;
            }

            float IntersectCylinder(out float3 normal, Ray r, float3 o, float hl, float r2)
            {
                float2 g = r.o.xy - o.xy;
                float a = dot(r.d.xy, r.d.xy);
                float b = 2.0 * dot(g, r.d.xy);
                float c = dot(g, g) - r2;
                float disc = b * b - 4.0 * a * c;
                if (disc < 0.0) return -1.0;

                float d = sqrt(disc);
                float t0 = (-b - d) / (2.0 * a);
                float t1 = (-b + d) / (2.0 * a);

                float rcp = 1.0 / r.d.z;
                float aa = rcp * (o - r.o).z;
                float ta = aa - abs(rcp) * hl;
                float tb = aa + abs(rcp) * hl;

                if (ta <= t0 && t0 <= tb)
                {
                    float2 w = g + t0 * r.d.xy;
                    normal = normalize(float3(w, 0));
                    return t0;
                }

                if (t0 < ta && ta < t1)
                {
                    normal = float3(0, 0, -sign(r.d.z));
                    return ta;
                }

                return -1.0;
            }

            float IntersectPlane(out float3 normal, Ray r, float3 n, float d)
            {
                normal = n;
                return -(d - dot(r.o, n)) / dot(r.d, n);
            }

            float CastRay(out float3 n, out int id, Ray r)
            {
                id = 0;
                float t = 1e37;
                [loop]
                for (int k = 0; k < 3; k++)
                {
                    [loop]
                    for (int j = 0; j < 3; j++)
                    {
                        [loop]
                        for (int i = 0; i < 3; i++)
                        {
                            float3 nn;
                            float tt;
                            int kk = i + j + k;
                            float3 o = float3(i - 1, j - 1, k - 1);
                            if ((kk % 3) == 0) tt = IntersectSphere(nn, r, o, 0.45 * 0.45);
                            else if ((kk % 3) == 1) tt = IntersectCylinder(nn, r, o, 0.45, 0.45 * 0.45);
                            else tt = IntersectCube(nn, r, o, float3(0.45, 0.45, 0.45));

                            if (0.0 < tt && tt < t)
                            {
                                t = tt;
                                n = nn;
                                id = 3 * (3 * k + j) + i + 2;
                            }
                        }
                    }
                }

                float3 nn;
                float tt = IntersectPlane(nn, r, float3(0, 1, 0), 2.0);
                if (0.0 < tt && tt < t)
                {
                    t = tt;
                    n = nn;
                    id = 1;
                }

                return t < 1e37 ? t : -1.0;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.uv * _STResolution.xy;
                float ww = 0.3;
                float c0 = cos(ww * _STTime);
                float s0 = sin(ww * _STTime);
                float c1 = cos(ww * _STTime + 0.6);
                float s1 = sin(ww * _STTime + 0.6);

                float w = 2.0 / max(_STResolution.x, _STResolution.y);
                float3 q = float3(w * (fragCoord.xy - 0.5 * _STResolution.xy), -1.0);

                Ray r;
                r.d.x = c0 * q.x - s0 * q.z;
                r.d.y = q.y + 0.0000001;
                r.d.z = s0 * q.x + c0 * q.z;
                r.d = normalize(r.d);
                r.o = 5.0 * float3(-s0, 0, c0);

                int id;
                float3 n;
                float t = CastRay(n, id, r);
                if (0.0 < t)
                {
                    float3 lp = 7.0 * float3(-s1, 0.75, c1);
                    Ray s;
                    s.o = r.o + t * r.d;
                    s.d = normalize(lp - s.o);

                    float3 foo;
                    int bar;
                    float tt = CastRay(foo, bar, s);
                    bool inShadow = 0.0 < tt;
                    float diffuse = inShadow ? 0.0 : dot(s.d, n);
                    return float4(n, (float)id + frac(max(0.0, diffuse)));
                }

                return float4(0.0, 0.0, 1.0, 0.0);
            }
            ENDHLSL
        }
    }
}
