Shader "Shadertoy/XlBSRz_VolumetricIntegration"
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
        _Channel0("Noise Texture", 2D) = "white" {}
        _Mouse("Mouse", Vector) = (0,0,0,0)
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

        #define vec2 float2
        #define vec3 float3
        #define vec4 float4
        #define mat2 float2x2
        #define mat3 float3x3
        #define mat4 float4x4
        #define mix lerp
        #define fract frac
        #define mod fmod
        #define textureLod(tex,uv,lod) SAMPLE_TEXTURE2D_LOD(_Channel0, sampler_Channel0, uv, lod)
        #define texture(tex,uv) SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, uv)
        // float4 iMouse;
        float4 _Mouse;
        /* Hi there!
         * Here is a demo presenting volumetric rendering single with shadowing.
         * Did it quickly so I hope I have not made any big mistakes :)
         *
         * I also added the improved scattering integration I propose in my SIGGRAPH'15 presentation
         * about Frostbite new volumetric system I have developed. See slide 28 at http://www.frostbite.com/2015/08/physically-based-unified-volumetric-rendering-in-frostbite/
         * Basically it improves the scattering integration for each step with respect to extinction
         * The difference is mainly visible for some participating media having a very strong scattering value. 
         * I have setup some pre-defined settings for you to checkout below (to present the case it improves):
         * - D_DEMO_SHOW_IMPROVEMENT_xxx: shows improvement (on the right side of the screen). You can still see aliasing due to volumetric shadow and the low amount of sample we take for it.
         * - D_DEMO_SHOW_IMPROVEMENT_xxx_NOVOLUMETRICSHADOW: same as above but without volumetric shadow
         *
         * To increase the volumetric rendering accuracy, I constrain the ray marching steps to a maximum distance.
         *
         * Volumetric shadows are evaluated by raymarching toward the light to evaluate transmittance for each view ray steps (ouch!)
         *
         * Do not hesitate to contact me to discuss about all that :) 
         * SebH
         */


        /*
         * This are predefined settings you can quickly use
         *    - D_DEMO_FREE play with parameters as you would like
         *    - D_DEMO_SHOW_IMPROVEMENT_FLAT show improved integration on flat surface
         *    - D_DEMO_SHOW_IMPROVEMENT_NOISE show improved integration on noisy surface
         *    - the two previous without volumetric shadows
         */
        #define D_DEMO_FREE
        //#define D_DEMO_SHOW_IMPROVEMENT_FLAT
        //#define D_DEMO_SHOW_IMPROVEMENT_NOISE
        //#define D_DEMO_SHOW_IMPROVEMENT_FLAT_NOVOLUMETRICSHADOW
        //#define D_DEMO_SHOW_IMPROVEMENT_NOISE_NOVOLUMETRICSHADOW


        #ifdef D_DEMO_FREE
        // Apply noise on top of the height fog?
        #define D_FOG_NOISE 1.0

        // Height fog multiplier to show off improvement with new integration formula
        #define D_STRONG_FOG 0.0

        // Enable/disable volumetric shadow (single scattering shadow)
        #define D_VOLUME_SHADOW_ENABLE 1

        // Use imporved scattering?
        // In this mode it is full screen and can be toggle on/off.
        #define D_USE_IMPROVE_INTEGRATION 1

        //
        // Pre defined setup to show benefit of the new integration. Use D_DEMO_FREE to play with parameters
        //
        #elif defined(D_DEMO_SHOW_IMPROVEMENT_FLAT)
                #define D_STRONG_FOG 10.0
                #define D_FOG_NOISE 0.0
            	#define D_VOLUME_SHADOW_ENABLE 1
        #elif defined(D_DEMO_SHOW_IMPROVEMENT_NOISE)
                #define D_STRONG_FOG 5.0
                #define D_FOG_NOISE 1.0
            	#define D_VOLUME_SHADOW_ENABLE 1
        #elif defined(D_DEMO_SHOW_IMPROVEMENT_FLAT_NOVOLUMETRICSHADOW)
                #define D_STRONG_FOG 10.0
                #define D_FOG_NOISE 0.0
            	#define D_VOLUME_SHADOW_ENABLE 0
        #elif defined(D_DEMO_SHOW_IMPROVEMENT_NOISE_NOVOLUMETRICSHADOW)
                #define D_STRONG_FOG 3.0
                #define D_FOG_NOISE 1.0
            	#define D_VOLUME_SHADOW_ENABLE 0
        #endif


        /*
         * Other options you can tweak
         */

        // Used to control wether transmittance is updated before or after scattering (when not using improved integration)
        // If 0 strongly scattering participating media will not be energy conservative
        // If 1 participating media will look too dark especially for strong extinction (as compared to what it should be)
        // Toggle only visible zhen not using the improved scattering integration.
        #define D_UPDATE_TRANS_FIRST 0

        // Apply bump mapping on walls
        #define D_DETAILED_WALLS 0

        // Use to restrict ray marching length. Needed for volumetric evaluation.
        #define D_MAX_STEP_LENGTH_ENABLE 1

        // Light position and color
        #define LPOS vec3( 20.0+15.0*sin(iTime), 15.0+12.0*cos(iTime),-20.0)
        #define LCOL (600.0*vec3( 1.0, 0.9, 0.5))


        float displacementSimple(vec2 p)
        {
            float f;
            f = 0.5000 * textureLod(iChannel0, p, 0.0).x;
            p = p * 2.0;
            f += 0.2500 * textureLod(iChannel0, p, 0.0).x;
            p = p * 2.0;
            f += 0.1250 * textureLod(iChannel0, p, 0.0).x;
            p = p * 2.0;
            f += 0.0625 * textureLod(iChannel0, p, 0.0).x;
            p = p * 2.0;

            return f;
        }


        vec3 getSceneColor(vec3 p, float material)
        {
            if (material == 1.0)
            {
                return vec3(1.0, 0.5, 0.5);
            }
            else if (material == 2.0)
            {
                return vec3(0.5, 1.0, 0.5);
            }
            else if (material == 3.0)
            {
                return vec3(0.5, 0.5, 1.0);
            }

            return vec3(0.0, 0.0, 0.0);
        }


        float getClosestDistance(vec3 p, out float material)
        {
            float d = 0.0;
            #if D_MAX_STEP_LENGTH_ENABLE
            float minD = 1.0; // restrict max step for better scattering evaluation
            #else
            	float minD = 10000000.0;
            #endif
            material = 0.0;

            float yNoise = 0.0;
            float xNoise = 0.0;
            float zNoise = 0.0;
            #if D_DETAILED_WALLS
                yNoise = 1.0*clamp(displacementSimple(p.xz*0.005),0.0,1.0);
                xNoise = 2.0*clamp(displacementSimple(p.zy*0.005),0.0,1.0);
                zNoise = 0.5*clamp(displacementSimple(p.xy*0.01),0.0,1.0);
            #endif

            d = max(0.0, p.y - yNoise);
            if (d < minD)
            {
                minD = d;
                material = 2.0;
            }

            d = max(0.0, p.x - xNoise);
            if (d < minD)
            {
                minD = d;
                material = 1.0;
            }

            d = max(0.0, 40.0 - p.x - xNoise);
            if (d < minD)
            {
                minD = d;
                material = 1.0;
            }

            d = max(0.0, -p.z - zNoise);
            if (d < minD)
            {
                minD = d;
                material = 3.0;
            }

            return minD;
        }


        vec3 calcNormal(in vec3 pos)
        {
            float material = 0.0;
            vec3 eps = vec3(0.3, 0.0, 0.0);
            return normalize(vec3(
                getClosestDistance(pos + eps.xyy, material) - getClosestDistance(pos - eps.xyy, material),
                getClosestDistance(pos + eps.yxy, material) - getClosestDistance(pos - eps.yxy, material),
                getClosestDistance(pos + eps.yyx, material) - getClosestDistance(pos - eps.yyx, material)));
        }

        vec3 evaluateLight(in vec3 pos)
        {
            vec3 lightPos = LPOS;
            vec3 lightCol = LCOL;
            vec3 L = lightPos - pos;
            return lightCol * 1.0 / dot(L, L);
        }

        vec3 evaluateLight(in vec3 pos, in vec3 normal)
        {
            vec3 lightPos = LPOS;
            vec3 L = lightPos - pos;
            float distanceToL = length(L);
            vec3 Lnorm = L / distanceToL;
            return max(0.0, dot(normal, Lnorm)) * evaluateLight(pos);
        }

        // To simplify: wavelength independent scattering and extinction
        void getParticipatingMedia(out float sigmaS, out float sigmaE, in vec3 pos)
        {
            float heightFog = 7.0 + D_FOG_NOISE * 3.0 * clamp(displacementSimple(pos.xz * 0.005 + iTime * 0.01), 0.0,
                                                              1.0);
            heightFog = 0.3 * clamp((heightFog - pos.y) * 1.0, 0.0, 1.0);

            const float fogFactor = 1.0 + D_STRONG_FOG * 5.0;

            const float sphereRadius = 5.0;
            float sphereFog = clamp((sphereRadius - length(pos - vec3(20.0, 19.0, -17.0))) / sphereRadius, 0.0, 1.0);

            const float constantFog = 0.02;

            sigmaS = constantFog + heightFog * fogFactor + sphereFog;

            const float sigmaA = 0.0;
            sigmaE = max(0.000000001, sigmaA + sigmaS); // to avoid division by zero extinction
        }

        float phaseFunction()
        {
            return 1.0 / (4.0 * 3.14);
        }

        float volumetricShadow(in vec3 from, in vec3 to)
        {
            #if D_VOLUME_SHADOW_ENABLE
            const float numStep = 16.0; // quality control. Bump to avoid shadow alisaing
            float shadow = 1.0;
            float sigmaS = 0.0;
            float sigmaE = 0.0;
            float dd = length(to - from) / numStep;
            for (float s = 0.5; s < (numStep - 0.1); s += 1.0) // start at 0.5 to sample at center of integral part
            {
                vec3 pos = from + (to - from) * (s / (numStep));
                getParticipatingMedia(sigmaS, sigmaE, pos);
                shadow *= exp(-sigmaE * dd);
            }
            return shadow;
            #else
                return 1.0;
            #endif
        }

        void traceScene(bool improvedScattering, vec3 rO, vec3 rD, inout vec3 finalPos, inout vec3 normal,
                        inout vec3 albedo, inout vec4 scatTrans)
        {
            const int numIter = 100;

            float sigmaS = 0.0;
            float sigmaE = 0.0;

            vec3 lightPos = LPOS;

            // Initialise volumetric scattering integration (to view)
            float transmittance = 1.0;
            vec3 scatteredLight = vec3(0.0, 0.0, 0.0);

            float d = 1.0; // hack: always have a first step of 1 unit to go further
            float material = 0.0;
            vec3 p = vec3(0.0, 0.0, 0.0);
            float dd = 0.0;
            [loop]
            for (int i = 0; i < numIter; ++i)
            {
                vec3 p = rO + d * rD;


                getParticipatingMedia(sigmaS, sigmaE, p);

                #ifdef D_DEMO_FREE
                if (D_USE_IMPROVE_INTEGRATION > 0) // freedom/tweakable version
                #else
                    if(improvedScattering)
                #endif
                {
                    // See slide 28 at http://www.frostbite.com/2015/08/physically-based-unified-volumetric-rendering-in-frostbite/
                    vec3 S = evaluateLight(p) * sigmaS * phaseFunction() * volumetricShadow(p, lightPos);
                    // incoming light
                    vec3 Sint = (S - S * exp(-sigmaE * dd)) / sigmaE; // integrate along the current step segment
                    scatteredLight += transmittance * Sint;
                    // accumulate and also take into account the transmittance from previous steps

                    // Evaluate transmittance to view independentely
                    transmittance *= exp(-sigmaE * dd);
                }
                else
                {
                    // Basic scatering/transmittance integration
                    #if D_UPDATE_TRANS_FIRST
                        transmittance *= exp(-sigmaE * dd);
                    #endif
                    scatteredLight += sigmaS * evaluateLight(p) * phaseFunction() * volumetricShadow(p, lightPos) *
                        transmittance * dd;
                    #if !D_UPDATE_TRANS_FIRST
                    transmittance *= exp(-sigmaE * dd);
                    #endif
                }


                dd = getClosestDistance(p, material);
                if (dd < 0.2)
                    break; // give back a lot of performance without too much visual loss
                d += dd;
            }

            albedo = getSceneColor(p, material);

            finalPos = rO + d * rD;

            normal = calcNormal(finalPos);

            scatTrans = vec4(scatteredLight, transmittance);
        }


        void mainImage(out vec4 fragColor, in vec2 fragCoord)
        {
            //iTime
            //iMouse
            //iResolution

            vec2 uv = fragCoord.xy / iResolution.xy;

            float hfactor = float(iResolution.y) / float(iResolution.x); // make it screen ratio independent
            vec2 uv2 = vec2(2.0, 2.0 * hfactor) * fragCoord.xy / iResolution.xy - vec2(1.0, hfactor);

            vec3 camPos = vec3(20.0, 18.0, -50.0);
            if (iMouse.x + iMouse.y > 0.0) // to handle first loading and see somthing on screen
                camPos += vec3(0.05, 0.12, 0.0) * (vec3(iMouse.x, iMouse.y, 0.0) - vec3(iResolution.xy * 0.5, 0.0));
            vec3 camX = vec3(1.0, 0.0, 0.0);
            vec3 camY = vec3(0.0, 1.0, 0.0);
            vec3 camZ = vec3(0.0, 0.0, 1.0);

            vec3 rO = camPos;
            vec3 rD = normalize(uv2.x * camX + uv2.y * camY + camZ);
            vec3 finalPos = rO;
            vec3 albedo = vec3(0.0, 0.0, 0.0);
            vec3 normal = vec3(0.0, 0.0, 0.0);
            vec4 scatTrans = vec4(0.0, 0.0, 0.0, 0.0);
            traceScene(fragCoord.x > (iResolution.x / 2.0),
                                           rO, rD, finalPos, normal, albedo, scatTrans);


            //lighting
            vec3 color = (albedo / 3.14) * evaluateLight(finalPos, normal) * volumetricShadow(finalPos, LPOS);
            // Apply scattering/transmittance
            color = color * scatTrans.w + scatTrans.xyz;

            // Gamma correction
            color = pow(color, vec3(1.0 / 2.2, 1.0 / 2.2, 1.0 / 2.2)); // simple linear to gamma, exposure of 1.0

            #ifndef D_DEMO_FREE
                // Separation line
                if(abs(fragCoord.x-(iResolution.x*0.5))<0.6)
                    color.r = 0.5;
            #endif

            fragColor = vec4(color, 1.0);
        }


        float4 RenderCrystal(float2 fragCoord)
        {
            iResolution = _STResolution.xyz;
            iTime = _STTime;
            iMouse = _STMouse;
            iFrame = _STFrame;
            iTimeDelta = _STDeltaTime;
            float4 fragColor = 0.0;
            mainImage(fragColor, fragCoord);
            return fragColor;
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
            #include "Assets/unity-shadertoy-validation/Common/Shaders/ShadertoyURPForwardPass.hlsl"
            ENDHLSL
        }
    }
}