Shader "Shadertoy/wsXBWS_ComicBlobs"
{
    Properties
    {

        [MainTexture] _BaseMap("Texture", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)
        _Cutoff("AlphaCutout", Range(0.0, 1.0)) = 0.5
        _Surface("__surface", Float) = 0.0
        _Blend("__mode", Float) = 0.0
        _Cull("__cull", Float) = 0.0
        [ToggleUI] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _BlendOp("__blendop", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _SrcBlendAlpha("__srcA", Float) = 1.0
        [HideInInspector] _DstBlendAlpha("__dstA", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 0.0
        [HideInInspector] _AlphaToMask("__alphaToMask", Float) = 0.0
        _QueueOffset("Queue offset", Float) = 0.0
        _STResolution("ST Resolution", Vector) = (512,288,0.001953125,0.003472222)
        _STMouse("ST Mouse", Vector) = (0,0,0,0)
        _STTime("ST Time", Float) = 0
        _STDeltaTime("ST DeltaTime", Float) = 0
        _STFrame("ST Frame", Float) = 0
        _Channel0("Channel0", 2D) = "white" {}
    }

    SubShader
    {
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Assets/unity-shadertoy-validation/Common/Shaders/ShadertoyCompat.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half _Cutoff;
            half _Surface;
            float4 _STResolution;
            float4 _STMouse;
            float _STTime;
            float _STDeltaTime;
            float _STFrame;
        CBUFFER_END

        #ifndef SHADERTOY_GLOBALS_DEFINED
        #define SHADERTOY_GLOBALS_DEFINED
        float3 iResolution;
        float iTime;
        float4 iMouse;
        float iFrame;
        float iTimeDelta;
        #endif

        #ifndef SHADERTOY_SHARED_VARYINGS_DEFINED
        #define SHADERTOY_SHARED_VARYINGS_DEFINED

        struct Attributes
        {
            float4 positionOS : POSITION;
            float2 uv : TEXCOORD0;
            #if defined(DEBUG_DISPLAY)
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #endif
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct Varyings
        {
            float2 uv : TEXCOORD0;
            float fogCoord : TEXCOORD1;
            float4 positionCS : SV_POSITION;
            float2 fragCoord : TEXCOORD5;
            #if defined(DEBUG_DISPLAY)
            float3 positionWS : TEXCOORD2;
            float3 normalWS : TEXCOORD3;
            float3 viewDirWS : TEXCOORD4;
            #endif
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };
        #endif
        TEXTURE2D(_Channel0);
        SAMPLER(sampler_Channel0);

        int FK(float k)
        {
            return asint(cos(k)) ^ asint(k);
        }

        float hash21(float2 k)
        {
            int x = FK(k.x);
            int y = FK(k.y);
            int v = (x * x - y) * (y * y + x) - x;
            return (float)v / 2.14e9;
        }

        float hash31(float3 k)
        {
            float h1 = hash21(k.xy);
            return hash21(float2(h1, k.z));
        }

        float3 hash33(float3 k)
        {
            float h1 = hash31(k);
            float h2 = hash31(k * h1);
            float h3 = hash31(k * h2);
            return float3(h1, h2, h3);
        }

        float sminf(float a, float b, float k)
        {
            float h = max(k - abs(a - b), 0.0) / k;
            return min(a, b) - h * h * h * k * (1.0 / 6.0);
        }

        float3 sphercoord(float2 p)
        {
            float l1 = acos(clamp(p.x, -1.0, 1.0));
            float l2 = acos(-1.0) * p.y;
            return float3(cos(l1), sin(l1) * sin(l2), sin(l1) * cos(l2));
        }

        float3 erot(float3 p, float3 ax, float ro)
        {
            return lerp(dot(p, ax) * ax, p, cos(ro)) + sin(ro) * cross(p, ax);
        }

        float comp(float3 p, float3 ro, float t)
        {
            float3 ax = sphercoord(ro.xy);
            p.z -= t;
            p = erot(p, ax, ro.z * acos(-1.0));
            float scale = 4.0 + hash21(ro.xz) * 0.5 + 0.5;
            p = (frac(p / scale) - 0.5) * scale;
            return length(p) - 0.8;
        }

        float scene(float3 p)
        {
            float rad = 3.0 + p.z + sin(p.y / 2.0 + _STTime) + cos(p.x / 3.0 + _STTime * 0.9);
            float dist = 10000.0;
            [unroll]
            for (int i = 0; i < 4; i++)
            {
                float fi = (float)(i + 1);
                float3 rot = hash33(float3(fi, cos((float)i), sin((float)i)));
                float d = comp(p, rot, _STTime / 2.0 * fi);
                dist = sminf(dist, d, 1.0);
            }
            return lerp(dist, rad, lerp(0.3, 0.8 + sin(_STTime) * 0.2, 0.1));
        }

        float3 norm(float3 p)
        {
            float e = 0.1;
            float3 ex = float3(e, 0, 0);
            float3 ey = float3(0, e, 0);
            float3 ez = float3(0, 0, e);
            return normalize(scene(p) - float3(scene(p - ex), scene(p - ey), scene(p - ez)));
        }

        float bayer8(int2 uv)
        {
            int2 q = int2((uv.x % 8 + 8) % 8, (uv.y % 8 + 8) % 8);
            // Shadertoy sampler for this texture is vflip=true.
            q.y = 7 - q.y;
            return _Channel0.Load(int3(q, 0)).x;
        }

        float marchAO(float3 p, float3 bias, float seed)
        {
            [loop]
            for (int i = 0; i < 10; i++)
            {
                float3 rnd = tan(hash33(float3((float)i, seed, 2.0)));
                p += normalize(bias + rnd) * scene(p);
            }
            return sqrt(smoothstep(0.0, 2.0, scene(p)));
        }

        float4 Frag(Varyings i) : SV_Target
        {
            float2 fragCoord = i.uv * _STResolution.xy;
            float2 uv = float2(fragCoord.x / _STResolution.x, fragCoord.y / _STResolution.y);
            uv -= 0.5;
            uv /= float2(_STResolution.y / _STResolution.x, 1.0);

            float3 cam = normalize(float3(4.0, uv));
            float3 init = float3(-50.0, 0.0, sin(_STTime * 0.37) * 1.4);
            cam = erot(cam, float3(0, 1, 0), -0.5);
            init = erot(init, float3(0, 1, 0), -0.5);

            float3 p = init;
            bool hit = false;
            bool trig = false;
            bool outline = false;

            [loop]
            for (int k = 0; k < 500 && !hit; k++)
            {
                float dist = scene(p);
                if (dist < 0.08) trig = true;
                if (trig)
                {
                    float odist = 0.09 - dist;
                    outline = odist < dist;
                    dist = min(dist, odist);
                }
                hit = dist * dist < 1e-6;
                p += dist * cam;
            }

            float3 n = norm(p);
            float3 r = reflect(cam, n);
            float2 ao = float2(0, 0);

            [loop]
            for (int a = 0; a < 8; a++)
            {
                int2 id = (((int2)(fragCoord / 16.0 + float2(_STTime * 10.0, _STTime * 20.0))) % 2) * 2 - 1;
                // GLSL: bayer(ivec2(fragCoord)+i+ivec2(i/4,0))
                // "+ i" adds to both components in GLSL vector-scalar arithmetic.
                float seed = bayer8((int2)fragCoord + int2(a, a) + int2(a / 4, 0));
                ao += float2(marchAO(p + n * 0.1, r, seed), 1.0);
            }
            ao.x /= max(ao.y, 1e-5);

            float3 col = (hit && !outline) ? float3(ao.x, ao.x, ao.x) : float3(0, 0, 0);
            col = pow(smoothstep(float3(0, 0, 0), float3(1, 1, 1), sqrt(saturate(col))), float3(1.7, 1.6, 1.5));
            return float4(saturate(col), 1.0);
        }


        float4 RenderShadertoy(float2 fragCoord)
        {
            Varyings input = (Varyings)0;
            input.uv = fragCoord / _STResolution.xy;
            input.fragCoord = fragCoord;
            return Frag(input);
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
            #define SHADERTOY_RENDER_FUNCTION RenderShadertoy
            #include "Assets/unity-shadertoy-validation/Common/Shaders/ShadertoyURPForwardPass.hlsl"
            ENDHLSL
        }
    }
}