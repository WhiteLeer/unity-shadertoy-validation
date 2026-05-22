Shader "Shadertoy/3lyXRt_BufferA"
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

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionHCS : SV_POSITION; float2 uv : TEXCOORD0; float2 fragCoord : TEXCOORD1; };

            float4 _STResolution;
            float _STTime;

            static const float DIST_MAX = 1e5;
            static const int OBJECT_TYPE_NONE = -1;
            static const int OBJECT_TYPE_PLANE = 0;
            static const int OBJECT_TYPE_SPHERE = 1;
            static const int PLANE_COUNT = 3;
            static const int SPHERE_COUNT = 2;
            static const float NEAR_DISTANCE = 2.0;
            static const float FAR_DISTANCE = 50.0;

            struct Ray { float3 origin; float3 dir; };
            struct Plane { float3 normal; float offset; float3 col; };
            struct Sphere { float3 center; float radius; float3 col; };
            struct Hit { float dist; int type; int id; };

            static const float3 CAMERA_X = float3(1,0,0);
            static const float3 CAMERA_Y = float3(0,1,0);
            static const float3 CAMERA_Z = float3(0,0,1);
            static const float3 EYE_POS = float3(0,1,-5);

            void GetPlane(int i, out Plane p)
            {
                if (i == 0) { p.normal = float3(0,1,0); p.offset = 3.0; p.col = float3(0.1,0.1,0.1); return; }
                if (i == 1) { p.normal = float3(1,0,0); p.offset = 5.0; p.col = float3(0.9,0.15,0.15); return; }
                p.normal = float3(0,0,-1); p.offset = 10.0; p.col = float3(0.0,0.22,0.6);
            }

            void GetSphere(int i, out Sphere s)
            {
                if (i == 0) { s.center = float3(-1,1,11); s.radius = 2.0; s.col = float3(1,0,0); return; }
                s.center = float3(3,-2.5,8); s.radius = 1.0; s.col = float3(0,1,0);
            }

            void MakeHit(float dist, int type, int id, out Hit h)
            {
                h.dist = dist; h.type = type; h.id = id;
            }

            void IntersectPlane(Plane p, Ray r, int id, out Hit h)
            {
                float d = dot(r.dir, p.normal);
                if (abs(d) < 1e-6) { MakeHit(DIST_MAX, OBJECT_TYPE_NONE, -1, h); return; }
                float t = -(p.offset + dot(r.origin, p.normal)) / d;
                if (t < 0.0) { MakeHit(DIST_MAX, OBJECT_TYPE_NONE, -1, h); return; }
                MakeHit(t, OBJECT_TYPE_PLANE, id, h);
            }

            void IntersectSphere(Sphere s, Ray r, int id, out Hit h)
            {
                float3 offset = r.origin - s.center;
                float a = dot(r.dir, r.dir);
                float b = 2.0 * dot(offset, r.dir);
                float c = dot(offset, offset) - s.radius * s.radius;
                float disc = b * b - 4.0 * a * c;
                if (disc < 0.0) { MakeHit(DIST_MAX, OBJECT_TYPE_NONE, -1, h); return; }
                float det = sqrt(disc);
                float t0 = (-b - det) / (2.0 * a);
                float t1 = (-b + det) / (2.0 * a);
                float t = (t0 > 0.0) ? t0 : t1;
                if (t < 0.0) { MakeHit(DIST_MAX, OBJECT_TYPE_NONE, -1, h); return; }
                MakeHit(t, OBJECT_TYPE_SPHERE, id, h);
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
                float3 eye = EYE_POS + float3(3.0 * cos(_STTime), 1.0 * sin(_STTime), 0.0);
                float2 uv = 2.0 * i.fragCoord / _STResolution.y - float2(_STResolution.x / _STResolution.y, 1.0);
                Ray ray;
                ray.origin = eye;
                ray.dir = normalize(uv.x * CAMERA_X + uv.y * CAMERA_Y + NEAR_DISTANCE * CAMERA_Z);

                Hit nearestObj; MakeHit(FAR_DISTANCE, OBJECT_TYPE_NONE, -1, nearestObj);
                [unroll] for (int p = 0; p < PLANE_COUNT; p++)
                {
                    Plane pl; GetPlane(p, pl);
                    Hit h; IntersectPlane(pl, ray, p, h);
                    if (h.dist < nearestObj.dist) nearestObj = h;
                }
                [unroll] for (int s = 0; s < SPHERE_COUNT; s++)
                {
                    Sphere sp; GetSphere(s, sp);
                    Hit h; IntersectSphere(sp, ray, s, h);
                    if (h.dist < nearestObj.dist) nearestObj = h;
                }

                float z = dot(ray.dir * nearestObj.dist, CAMERA_Z);
                return float4(z, z, z, FAR_DISTANCE) / FAR_DISTANCE;
            }
            ENDHLSL
        }
    }
}
