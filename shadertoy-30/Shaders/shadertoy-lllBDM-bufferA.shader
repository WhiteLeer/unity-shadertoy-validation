Shader "Shadertoy/lllBDM_BufferA"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "BufferA"
            Cull Off ZWrite Off ZTest Always
            HLSLPROGRAM
            #pragma target 4.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS:POSITION; float2 uv:TEXCOORD0; };
            struct Varyings { float4 positionHCS:SV_POSITION; float2 uv:TEXCOORD0; float2 fragCoord:TEXCOORD1; };

            float4 _STResolution;
            float _STTime;

            static const float pi = 3.14159;

            float3x3 rotate(float3 v, float angle)
            {
                float c = cos(angle);
                float s = sin(angle);
                float3x3 m = float3x3(
                    c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y,
                    (1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x,
                    (1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z
                );
                // GLSL mat3 constructor consumes scalars in column-major order.
                // HLSL float3x3 scalar constructor is row-major; transpose to match GLSL layout.
                return transpose(m);
            }

            float3 hash3(float3 p)
            {
                p = float3(dot(p,float3(127.1,311.7,74.7)), dot(p,float3(269.5,183.3,246.1)), dot(p,float3(113.5,271.9,124.6)));
                return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
            }

            float4 noised(float3 x)
            {
                float3 p = floor(x);
                float3 w = frac(x);
                float3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
                float3 du = 30.0*w*w*(w*(w-2.0)+1.0);

                float3 ga = hash3(p + float3(0,0,0));
                float3 gb = hash3(p + float3(1,0,0));
                float3 gc = hash3(p + float3(0,1,0));
                float3 gd = hash3(p + float3(1,1,0));
                float3 ge = hash3(p + float3(0,0,1));
                float3 gf = hash3(p + float3(1,0,1));
                float3 gg = hash3(p + float3(0,1,1));
                float3 gh = hash3(p + float3(1,1,1));

                float va = dot(ga, w-float3(0,0,0));
                float vb = dot(gb, w-float3(1,0,0));
                float vc = dot(gc, w-float3(0,1,0));
                float vd = dot(gd, w-float3(1,1,0));
                float ve = dot(ge, w-float3(0,0,1));
                float vf = dot(gf, w-float3(1,0,1));
                float vg = dot(gg, w-float3(0,1,1));
                float vh = dot(gh, w-float3(1,1,1));

                float value = va + u.x*(vb-va) + u.y*(vc-va) + u.z*(ve-va)
                    + u.x*u.y*(va-vb-vc+vd) + u.y*u.z*(va-vc-ve+vg) + u.z*u.x*(va-vb-ve+vf)
                    + (-va+vb+vc-vd+ve-vf-vg+vh)*u.x*u.y*u.z;

                float3 deriv = ga + u.x*(gb-ga) + u.y*(gc-ga) + u.z*(ge-ga)
                    + u.x*u.y*(ga-gb-gc+gd) + u.y*u.z*(ga-gc-ge+gg) + u.z*u.x*(ga-gb-ge+gf)
                    + (-ga+gb+gc-gd+ge-gf-gg+gh)*u.x*u.y*u.z
                    + du * (float3(vb,vc,ve) - va
                    + u.yzx*float3(va-vb-vc+vd,va-vc-ve+vg,va-vb-ve+vf)
                    + u.zxy*float3(va-vb-ve+vf,va-vb-vc+vd,va-vc-ve+vg)
                    + u.yzx*u.zxy*(-va+vb+vc-vd+ve-vf-vg+vh));

                return float4(value, deriv);
            }

            float mapf(float3 p)
            {
                float d = p.y;
                float c = max(0.0, pow(distance(p.xz, float2(0,16)), 1.0));
                float cc = pow(smoothstep(20.0, 5.0, c), 2.0);
                float4 n = noised(float3(p.xz*0.07, _STTime*0.5));
                float nn = n.x * length(n.yzw);
                n = noised(float3(p.xz*0.173, _STTime*0.639));
                nn += 0.25 * n.x * length(n.yzw);
                nn = smoothstep(-0.5, 0.5, nn);
                d = d - 6.0 * nn * cc;
                return d;
            }

            float err(float dist)
            {
                dist = dist/100.0;
                return min(0.01, dist*dist);
            }

            float3 dr(float3 origin, float3 direction, float3 position)
            {
                [unroll] for(int i=0;i<3;i++)
                {
                    position = position + direction * (mapf(position) - err(distance(origin, position)));
                }
                return position;
            }

            float3 intersect(float3 ro, float3 rd)
            {
                float3 p = ro + rd;
                float t = 0.0;
                [loop] for(int i=0;i<150;i++)
                {
                    float d = 0.5 * mapf(p);
                    t += d;
                    p += rd*d;
                    if(d < 0.01 || t > 60.0) break;
                }
                p = dr(ro, rd, p);
                return p;
            }

            float3 normal(float3 p)
            {
                float e = 0.01;
                float3 g = float3(
                    mapf(p+float3(e,0,0)) - mapf(p-float3(e,0,0)),
                    mapf(p+float3(0,e,0)) - mapf(p-float3(0,e,0)),
                    mapf(p+float3(0,0,e)) - mapf(p-float3(0,0,e)));
                float lg = length(g);
                if (lg < 1e-6 || any(isnan(g)) || any(isinf(g))) return float3(0,1,0);
                return g / lg;
            }

            float G1V(float dnv, float k) { return 1.0/(dnv*(1.0-k)+k); }

            float ggx(float3 n, float3 v, float3 l, float rough, float f0)
            {
                float alpha = rough*rough;
                float3 h = normalize(v+l);
                float dnl = clamp(dot(n,l), 0.0, 1.0);
                float dnv = clamp(dot(n,v), 0.0, 1.0);
                float dnh = clamp(dot(n,h), 0.0, 1.0);
                float dlh = clamp(dot(l,h), 0.0, 1.0);
                float asqr = alpha*alpha;
                float den = dnh*dnh*(asqr-1.0)+1.0;
                float d = asqr/(pi * den * den);
                dlh = pow(1.0-dlh, 5.0);
                float f = f0 + (1.0-f0)*dlh;
                float k = alpha/1.0;
                float vis = G1V(dnl, k)*G1V(dnv, k);
                return dnl * d * f * vis;
            }

            float subsurface(float3 p, float3 v, float3 n)
            {
                float3 d = refract(v, n, 1.0/1.5);
                float3 o = p;
                float a = 0.0;
                const float max_scatter = 2.5;
                [loop] for(float i=0.1;i<max_scatter;i+=0.2)
                {
                    o += i*d;
                    a += mapf(o);
                }
                float thickness = max(0.0, -a);
                const float scatter_strength = 16.0;
                return scatter_strength*pow(max_scatter*0.5, 3.0)/max(thickness,1e-4);
            }

            float3 shade(float3 p, float3 v)
            {
                float3 lp = float3(50,20,10);
                float3 ld = normalize(p+lp);
                float3 n = normal(p);
                float fresnel = pow(max(0.0, 1.0+dot(n, v)), 5.0);
                float3 ambient = float3(0.1, 0.06, 0.035);
                float3 albedo = float3(0.75, 0.9, 0.35);
                float3 sky = float3(0.5,0.65,0.8)*2.0;
                float lamb = max(0.0, dot(n, ld));
                float spec = ggx(n, v, ld, 3.0, fresnel);
                float ss = max(0.0, subsurface(p, v, n));
                lamb = lerp(lamb, 3.5*smoothstep(0.0, 2.0, pow(ss, 0.6)), 0.7);
                float3 final = ambient + albedo*lamb+ 25.0*spec + fresnel*sky;
                return clamp(final*0.5, 0.0, 8.0);
            }

            float3 hash31(float3 p)
            {
                p = float3(dot(p,float3(127.1,311.7,74.7)), dot(p,float3(269.5,183.3,246.1)), dot(p,float3(113.5,271.9,124.6)));
                return frac(sin(p)*43758.5453123);
            }

            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                o.fragCoord = i.uv * _STResolution.xy;
                return o;
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 uv = i.fragCoord / _STResolution.xy;
                float3 a = 0;

                const float campos = 5.1;
                float lr = 0.5 + 0.5*cos(campos*0.4 - pi);
                lr = smoothstep(0.13, 1.0, lr);
                float3 c = lerp(float3(0,217,0), float3(0,4.4,-190), pow(lr,1.0));
                float3x3 rot = rotate(float3(1,0,0), pi/2.0);
                float3x3 ro2 = rotate(float3(1,0,0), -0.008*pi/2.0);

                float2 u2 = -1.0 + 2.0*uv;
                u2.x *= _STResolution.x/_STResolution.y;

                // GLSL uses row-vector * matrix in the source shader.
                float3 d = lerp(normalize(mul(float3(u2,20), rot)), normalize(mul(normalize(float3(u2,20)), ro2)), pow(lr,1.11));
                d = normalize(d);

                float3 ii = intersect(c + 145.0*d, d);
                float3 ss = shade(ii, d);
                if (any(isnan(ss)) || any(isinf(ss))) ss = 0;
                a += ss;

                float n = hash31(float3(uv,0.001*_STTime)).x;
                return float4(max(a*(0.99+0.02*n), 0.0), 1.0);
            }
            ENDHLSL
        }
    }
}
