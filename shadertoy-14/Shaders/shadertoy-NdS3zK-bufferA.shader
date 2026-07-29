Shader "Shadertoy/NdS3zK_BufferA"
{
    Properties { _Channel0("Previous Buffer A", 2D) = "black" {} }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "BufferA"
            Cull Off ZWrite Off ZTest Always
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes { float4 positionOS:POSITION; float2 uv:TEXCOORD0; };
            struct Varyings { float4 positionHCS:SV_POSITION; float2 uv:TEXCOORD0; float2 fragCoord:TEXCOORD1; };

            TEXTURE2D(_Channel0); SAMPLER(sampler_Channel0);
            float4 _STResolution;
            float4 _STMouse;
            float _STFrame;

            #define PI 3.14159
            #define CAMERA_DIST 2.5

            float4 FetchPrev(float2 pix)
            {
                return SAMPLE_TEXTURE2D(_Channel0, sampler_Channel0, (pix + 0.5) / _STResolution.xy);
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
                float2 p = floor(i.fragCoord);
                float4 outColor = 0;

                if (p.x == 0.0 && p.y < 4.0)
                {
                    float4 oldMouse = FetchPrev(float2(0, 0));
                    float4 mouse = _STMouse / _STResolution.xyxy;
                    float4 newMouse = float4(oldMouse.xy, mouse.xy);
                    float mouseDownLastFrame = FetchPrev(float2(0, 3)).x;

                    if (_STMouse.z > 0.0 && mouseDownLastFrame > 0.0)
                    {
                        float2 mouseMove = mouse.xy - oldMouse.zw;
                        newMouse = float4(oldMouse.xy + float2(5.0, 3.0) * mouseMove, mouse.xy);
                    }

                    newMouse.x = fmod(newMouse.x, 2.0 * PI);
                    if (newMouse.x < 0.0) newMouse.x += 2.0 * PI;
                    newMouse.y = min(0.99, max(-0.99, newMouse.y));

                    if (p.y == 0.0)
                    {
                        if (_STFrame < 5.0) newMouse = float4(1.15, 0.2, 0.0, 0.0);
                        outColor = newMouse;
                    }
                    else if (p.y == 1.0)
                    {
                        float3 cameraPos = CAMERA_DIST * float3(sin(newMouse.x), -sin(newMouse.y), -cos(newMouse.x));
                        outColor = float4(cameraPos, 1.0);
                    }
                    else if (p.y == 2.0)
                    {
                        float2 oldResolution = FetchPrev(float2(0, 2)).yz;
                        float resolutionChangeFlag = any(abs(_STResolution.xy - oldResolution) > 0.5) ? 1.0 : 0.0;
                        outColor = float4(resolutionChangeFlag, _STResolution.xy, 1.0);
                    }
                    else if (p.y == 3.0)
                    {
                        outColor = (_STMouse.z > 0.0) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 1);
                    }
                }

                return outColor;
            }
            ENDHLSL
        }
    }
}
