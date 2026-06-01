Shader "Shadertoy/4d2yRt_BufferA"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        Pass
        {
            Name "BufferA"
            Cull Off
            ZWrite Off
            ZTest Always
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/unity-shadertoy-validation/Common/Shaders/ShadertoyCompat.hlsl"
            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };
            float4 _STResolution;
            float _STTime;
            Varyings Vert(Attributes i){ Varyings o; o.positionHCS=TransformObjectToHClip(i.positionOS.xyz); o.uv=i.uv; return o; }

            float pmod(float a, float b) { return ModGLSL(ModGLSL(a, b) + b, b); }
            float rep(float a, float r) { return pmod(a + r * 0.5, r) - r * 0.5; }
            float2 rep2(float2 a, float2 r) { return float2(rep(a.x, r.x), rep(a.y, r.y)); }

            float trivalue(float2 p)
            {
                float d = length(-p);
                d = cos(d * 4.0) * 0.5 + 0.5;
                d += cos(p.x / 1.5) * 0.5;
                return d * 1.5;
            }

            float trilattice(float2 p)
            {
                float flip = ModGLSL(p.y, 2.0);
                p.x -= abs(flip - 1.0) * 0.5;
                flip = (flip <= 1.0) ? -1.0 : 1.0;
                float2 bary = p - floor(p);
                bary.x = (bary.x - 0.5) * flip + 0.5;
                float side = -0.5;
                if (bary.x + bary.y > 1.0)
                {
                    side = 0.5;
                    bary = 1.0 - bary.yx;
                }
                float2 ip = floor(p);
                float2 t1 = ip + float2(0.5 + side * flip, 0.5 + side);
                float2 t2 = ip + float2(0.5 + 0.5 * flip, 0.0);
                float2 t3 = ip + float2(0.5 - 0.5 * flip, 1.0);
                float v1 = trivalue(t1);
                float v2 = trivalue(t2);
                float v3 = trivalue(t3);
                return v1 * (1.0 - bary.x - bary.y) + v2 * bary.x + v3 * bary.y;
            }

            float fn(float3 pos)
            {
                pos.y += sin(pos.x / 10.0) * 3.0;
                float tt = _STTime * 148.0 / 60.0;
                tt = floor(tt) + pow(ModGLSL(tt, 1.0), 4.0);
                float aa = AtanGLSL(pos.y, pos.z) * (48.0 / (2.0 * 3.14159265)) + tt * 0.4;
                float z = 10.0 - trilattice(float2(pos.x * 1.5, aa)) - length(pos.yz);
                return z;
            }

            float lfn(float3 pos)
            {
                float sund = ModGLSL(_STTime * 30.0 + 60.0, 120.0) - 60.0;
                float3 l0 = float3(sund, -sin(sund / 10.0) * 3.0, 0.0);
                float sund1 = sund + 120.0;
                float3 l1 = float3(sund1, -sin(sund1 / 10.0) * 3.0, 0.0);
                float d = length(l0 - pos);
                d = min(d, length(l1 - pos));
                return d - 0.4;
            }

            float getLightFall(float n)
            {
                float sund = ModGLSL(_STTime * 30.0 + 60.0, 120.0) - 60.0 + 120.0 * n;
                float fall = smoothstep(0.0, 1.0, (sund + 30.0) / 20.0);
                fall *= clamp((180.0 - sund) / 20.0, 0.0, 1.0);
                return fall;
            }

            float lightAt(float3 n, float3 pos, float3 eye, float3 lpos)
            {
                lpos.y += sin(lpos.x / 10.0) * 3.0;
                float3 ldir = normalize(lpos - pos);
                float dd = length(lpos - pos);
                float sh = 1.0;
                [loop]
                for (int i = 0; i < 30; i++)
                {
                    float3 tpos = pos + (lpos - pos) * ((float)i / 100.0);
                    float d = fn(tpos);
                    sh = min(sh, d * 20.0);
                }
                float3 eyeref = normalize(reflect(pos - eye, n));
                float diff = clamp(dot(n, ldir), 0.0, 1.0);
                float spec = pow(clamp(dot(eyeref, ldir), 0.0, 1.0), 16.0) * clamp(diff * 20.0, 0.0, 1.0);
                float spec2 = pow(clamp(dot(eyeref, ldir), 0.0, 1.0), 64.0) * clamp(diff * 20.0, 0.0, 1.0);
                float attn = 1.0 / max(dd * dd, 1e-4);
                return (diff * 0.1 + spec * 2.0 + spec2 * 15.0 / pow(max(attn, 1e-5), 0.15)) * sh * attn * 100.0;
            }

            float plight(float3 n, float3 rpos, float3 eye, float nl)
            {
                float sund = ModGLSL(_STTime * 30.0 + 60.0, 120.0) - 60.0 + 120.0 * nl;
                float3 lpos = float3(sund, -sin(sund / 10.0) * 3.0, 0.0);
                return lightAt(n, rpos, eye, lpos) * getLightFall(nl);
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.uv * _STResolution.xy;
                float2 mpos = float2(-0.05, 0.6);
                float2 uv = fragCoord / _STResolution.xy;
                float2 vpos = uv * 2.0 - 1.0;
                vpos.x *= _STResolution.x / _STResolution.y;
                vpos *= 0.65;

                float3 front = normalize(float3(1.0, mpos.x, mpos.y - 0.5));
                float3 up = float3(0, 0, 1);
                float3 right = cross(up, front);
                float3 pos = float3(0,0,-2) - front * 12.0;
                float3 rdir = normalize(front + vpos.x * right + vpos.y * up);

                float3 rpos = pos;
                float d = 0.0, d1 = 0.0, type = 0.0;
                [loop]
                for (int k = 0; k < 100; k++)
                {
                    d = fn(rpos) * 0.5;
                    d1 = lfn(rpos);
                    d = min(d, d1);
                    type = (d < d1) ? 0.0 : 1.0;
                    rpos += d * rdir;
                    if (d < 0.02) break;
                }

                if (d > 0.05) return float4(0,0,0,0);
                if (type >= 0.5) return float4(1,1,1,1);

                float e = 0.01;
                float3 n = normalize(float3(
                    fn(float3(rpos.x + e, rpos.y, rpos.z)) - fn(float3(rpos.x - e, rpos.y, rpos.z)),
                    fn(float3(rpos.x, rpos.y + e, rpos.z)) - fn(float3(rpos.x, rpos.y - e, rpos.z)),
                    fn(float3(rpos.x, rpos.y, rpos.z + e)) - fn(float3(rpos.x, rpos.y, rpos.z - e))
                ));

                float3 col = 0.0;
                col += plight(n, rpos, pos, 0.0);
                col += plight(n, rpos, pos, 1.0);
                col *= float3(0.1, 1.0, 0.8);
                return float4(clamp(col, 0.0, 1.0), 0.0);
            }
            ENDHLSL
        }
    }
}
