Shader "Shadertoy/WdXXR8_VanGoghRaytracer"
{
    Properties
    {
        _Channel0("Channel0", 2D) = "black" {}
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
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/unity-shadertoy-validation/Common/Shaders/ShadertoyCompat.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; };
            Varyings Vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            float4 _STResolution;
            float _STTime;

            #define PI 3.14159265
            static const float INFINITE = 1e6;
            static const float EPSILON = 1e-6;
            static const int STANDARD_MATERIAL = 1;
            static const int CHECKER_MATERIAL = 2;
            static const int POLKA_MATERIAL = 3;
            static const int SPHERE_PRIMITIVE = 1;
            static const int PLANE_PRIMITIVE = 2;
            static const int RING_PRIMITIVE = 3;
            static const int NUM_PRIMS = 5;

            struct RayT { float3 pos; float3 dir; int level; float4 contrib; };
            struct HitT { float t; float3 pos; float3 normal; int mat; };
            struct MaterialT {
                int type; int flags; int attrib0; int attrib1;
                float4 ambient; float4 diffuse; float4 specular; float4 emission; float4 reflection; float4 transparent;
            };
            struct PrimitiveT { int type; int mat; float3 v0; float3 v1; float3 v2; };

            float3 viewFrom;
            float3 viewAt;
            float3 viewUp;
            float viewFov;
            float3 viewDir;
            float3 viewRight;
            float viewTan;
            float aspect;
            int oversample;
            float4 skyColor;
            float4 horizonColor;
            float4 ambientLight;
            float3 lightDirection;

            MaterialT MaterialMake(int type, int flags, int attrib0, int attrib1, float4 ambient, float4 diffuse, float4 specular, float4 emission, float4 reflection, float4 transparent)
            {
                MaterialT m;
                m.type = type; m.flags = flags; m.attrib0 = attrib0; m.attrib1 = attrib1;
                m.ambient = ambient; m.diffuse = diffuse; m.specular = specular; m.emission = emission; m.reflection = reflection; m.transparent = transparent;
                return m;
            }

            PrimitiveT PrimitiveMake(int type, int mat, float3 v0, float3 v1, float3 v2)
            {
                PrimitiveT p;
                p.type = type; p.mat = mat; p.v0 = v0; p.v1 = v1; p.v2 = v2;
                return p;
            }

            MaterialT GetMaterial(int idx)
            {
                if (idx == 0) return MaterialMake(STANDARD_MATERIAL,0,0,0,float4(.1,.1,.1,1),float4(.1,.1,.1,1),float4(1,1,1,100),float4(0,0,0,0),float4(0,0,0,0),float4(0,0,0,0));
                if (idx == 1) return MaterialMake(STANDARD_MATERIAL,0,0,0,float4(1,1,1,1),float4(1,1,1,1),float4(1,1,1,100),float4(0,0,0,0),float4(0,0,0,0),float4(0,0,0,0));
                if (idx == 2) return MaterialMake(CHECKER_MATERIAL,0,0,1,float4(0.5,0.5,0.5,0),float4(0.001,0.001,0.001,0),float4(0,0,0,0),float4(0,0,0,0),float4(0,0,0,0),float4(0,0,0,0));
                if (idx == 3) return MaterialMake(STANDARD_MATERIAL,0,0,0,float4(0,0,0,1),float4(0,0,0,1),float4(1,1,1,50),float4(0,0,0,0),float4(0.2,0.2,0.2,0),float4(0.6,0.6,0.6,1.24));
                if (idx == 4) return MaterialMake(STANDARD_MATERIAL,0,0,0,float4(0.3,0.3,0.3,1),float4(0.3,0.3,0.3,1),float4(1,1,1,50),float4(0,0,0,0),float4(0.6,0.6,0.6,0),float4(0,0,0,0));
                if (idx == 5) return MaterialMake(STANDARD_MATERIAL,0,0,0,float4(1,0,0,1),float4(1,0,0,1),float4(1,1,1,60),float4(0,0,0,0),float4(0,0,0,0),float4(0,0,0,0));
                return MaterialMake(STANDARD_MATERIAL,0,0,0,float4(.8,.6,0,1),float4(.8,.6,0,1),float4(0.5,0.5,0.5,30),float4(0,0,0,0),float4(0.1,0.1,0.1,0),float4(0,0,0,0));
            }

            PrimitiveT GetPrimitive(int i)
            {
                if (i == 0) return PrimitiveMake(PLANE_PRIMITIVE, 2, float3(0,0,-3), float3(0,0,1), float3(0,0,0));
                if (i == 1) return PrimitiveMake(SPHERE_PRIMITIVE, 3, float3(0,0,-1), float3(2,0,0), float3(0,0,0));
                if (i == 2) return PrimitiveMake(SPHERE_PRIMITIVE, 4, float3(4,2,-1.5), float3(1.5,0,0), float3(0,0,0));
                if (i == 3) return PrimitiveMake(SPHERE_PRIMITIVE, 5, float3(-4,-3,-2), float3(1,0,0), float3(0,0,0));
                return PrimitiveMake(SPHERE_PRIMITIVE, 6, float3(-2,4,-1.8), float3(1.2,0,0), float3(0,0,0));
            }

            RayT PrimaryRay(float fx, float fy)
            {
                RayT ray;
                ray.pos = viewFrom;
                ray.dir = normalize(viewDir + viewRight * fx * aspect + viewUp * fy);
                ray.contrib = float4(1,1,1,1);
                ray.level = 0;
                return ray;
            }

            float4 Background(RayT ray)
            {
                float t = 1.0 - ray.dir.z * ray.dir.z;
                t = pow(t, 50.0);
                return skyColor * (1.0 - t) + horizonColor * t;
            }

            bool HitSphere(float3 center, float radius, int mat, RayT ray, out HitT hit)
            {
                hit.t = INFINITE;
                float3 q = ray.pos - center;
                float a = dot(ray.dir, ray.dir);
                float b = 2.0 * dot(q, ray.dir);
                float c = dot(q, q) - radius * radius;
                float d = b * b - 4.0 * a * c;
                if (d > EPSILON)
                {
                    float t0 = (-b - sqrt(d)) / (2.0 * a);
                    float t1 = (-b + sqrt(d)) / (2.0 * a);
                    float t = (t1 > EPSILON && t1 < t0) ? t1 : t0;
                    if (t < EPSILON) t = INFINITE;
                    if (t != INFINITE)
                    {
                        hit.t = t;
                        hit.pos = ray.pos + ray.dir * hit.t;
                        hit.normal = normalize(hit.pos - center);
                        hit.mat = mat;
                        return true;
                    }
                }
                return false;
            }

            bool HitPlane(float3 p0, float3 normal, int mat, RayT ray, out HitT hit)
            {
                hit.t = INFINITE;
                float d = dot(normal, ray.dir);
                if (abs(d) > EPSILON)
                {
                    float3 q = p0 - ray.pos;
                    float t = dot(q, normal) / d;
                    if (t > EPSILON)
                    {
                        hit.t = t;
                        hit.pos = ray.pos + ray.dir * t;
                        hit.normal = normal;
                        hit.mat = mat;
                        return true;
                    }
                }
                return false;
            }

            bool HitRing(float3 p0, float3 normal, float r1, float r2, int mat, RayT ray, out HitT hit)
            {
                hit.t = INFINITE;
                float d = dot(normal, ray.dir);
                if (abs(d) > EPSILON)
                {
                    float3 q = p0 - ray.pos;
                    float t = dot(q, normal) / d;
                    if (t > EPSILON)
                    {
                        float3 p = ray.pos + ray.dir * t;
                        float3 rr = p - p0;
                        float e = dot(rr, rr);
                        if (e < r1 * r1 && e > r2 * r2)
                        {
                            hit.t = t;
                            hit.pos = p;
                            hit.normal = normal;
                            hit.mat = mat;
                            return true;
                        }
                    }
                }
                return false;
            }

            void Intersect(RayT ray, out HitT hit)
            {
                hit.t = INFINITE;
                [loop]
                for (int i = 0; i < NUM_PRIMS; i++)
                {
                    PrimitiveT p = GetPrimitive(i);
                    HitT h;
                    bool ok = false;
                    if (p.type == PLANE_PRIMITIVE) ok = HitPlane(p.v0, p.v1, p.mat, ray, h);
                    else if (p.type == SPHERE_PRIMITIVE) ok = HitSphere(p.v0, p.v1.x, p.mat, ray, h);
                    else if (p.type == RING_PRIMITIVE) ok = HitRing(p.v0, p.v1, p.v2.x, p.v2.y, p.mat, ray, h);
                    if (ok && h.t < hit.t) hit = h;
                }
            }

            float4 ShadeStandard(RayT ray, HitT hit)
            {
                if (ray.level >= 6) return float4(0,0,0,0);
                MaterialT m = GetMaterial(hit.mat);
                float4 color = m.ambient * ambientLight;

                RayT sray;
                sray.pos = hit.pos - lightDirection * EPSILON;
                sray.dir = -lightDirection;
                sray.level = ray.level;
                sray.contrib = 1;
                HitT sh;
                Intersect(sray, sh);
                if (sh.t == INFINITE)
                {
                    float d = saturate(dot(-lightDirection, hit.normal));
                    color += m.diffuse * d;
                    float3 r = reflect(ray.dir, hit.normal);
                    float s = pow(saturate(dot(-lightDirection, r)), m.specular.a);
                    color.rgb += m.specular.rgb * s;
                }

                color.rgb += m.emission.rgb;
                return color;
            }

            float4 ShadeChecker(RayT ray, HitT hit)
            {
                MaterialT m = GetMaterial(hit.mat);
                float3 p = hit.pos * m.ambient.xyz + m.diffuse.xyz;
                int ix = ((int)floor(p.x)) & 1;
                int iy = ((int)floor(p.y)) & 1;
                int iz = ((int)floor(p.z)) & 1;
                hit.mat = ((ix ^ iy ^ iz) == 0) ? m.attrib0 : m.attrib1;
                return ShadeStandard(ray, hit);
            }

            float4 ShadePolka(RayT ray, HitT hit)
            {
                MaterialT m = GetMaterial(hit.mat);
                float3 p = hit.pos * m.ambient.xyz + m.diffuse.xyz;
                int iy = ((int)floor(p.y)) & 1;
                if ((iy & 1) == 1) p.x += 0.5;
                float3 p2 = ModGLSL(p, 1.0);
                p2 = p2 * 2.0 - 1.0;
                float d = dot(p2, p2);
                hit.mat = (d < (0.666 * 0.666)) ? m.attrib0 : m.attrib1;
                return ShadeStandard(ray, hit);
            }

            float4 Shade(RayT ray, HitT hit)
            {
                float4 color;
                if (hit.t != INFINITE)
                {
                    MaterialT m = GetMaterial(hit.mat);
                    if (m.type == STANDARD_MATERIAL) color = ShadeStandard(ray, hit);
                    else if (m.type == CHECKER_MATERIAL) color = ShadeChecker(ray, hit);
                    else color = ShadePolka(ray, hit);

                    float f = saturate((hit.t - 10.0) / (50.0 - 10.0));
                    color = lerp(color, horizonColor, f);
                }
                else color = Background(ray);
                return color * ray.contrib;
            }

            float4 Raytrace(RayT ray)
            {
                HitT hit;
                Intersect(ray, hit);
                return Shade(ray, hit);
            }

            float4 Frag(Varyings i) : SV_Target
            {
                float2 fragCoord = i.uv * _STResolution.xy;

                viewFrom = float3(sin(_STTime * 0.25) * 14.0, -cos(_STTime * 0.25) * 14.0, 2.0 + sin(_STTime * 0.75) * 3.0);
                viewAt = float3(0,0,-1);
                viewUp = float3(0,0,1);
                viewFov = 30.0;
                aspect = _STResolution.x / _STResolution.y;
                viewTan = tan(((viewFov / 180.0) * PI) / 2.0);
                oversample = 2;
                skyColor = float4(0,0,0.5,1);
                horizonColor = float4(0.5,0.75,1,1);
                ambientLight = float4(0.2,0.2,0.1,1);
                lightDirection = normalize(float3(1,1,-1));

                float2 uv = fragCoord / _STResolution.xy * 2.0 - 1.0;
                uv *= viewTan;
                viewDir = normalize(viewAt - viewFrom);
                viewRight = cross(viewDir, viewUp);
                viewUp = cross(viewRight, viewDir);

                float4 color = float4(0,0,0,0);
                float sx = (1.0 / (float)oversample) / _STResolution.x;
                float sy = (1.0 / (float)oversample) / _STResolution.y;

                [loop]
                for (int a = 0; a < 2; a++)
                {
                    [loop]
                    for (int b = 0; b < 2; b++)
                    {
                        float2 noise = SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, fragCoord / _STResolution.xy).xy * 2.0 - 1.0;
                        float2 offs = noise * 0.2;
                        offs *= 0.1 + abs(uv.y) * 2.0;
                        RayT ray = PrimaryRay(uv.x + (float)a * sx + offs.x, uv.y + (float)b * sy + offs.y);
                        color += Raytrace(ray);
                    }
                }

                color /= 4.0;
                return color;
            }
            ENDHLSL
        }
    }
}
