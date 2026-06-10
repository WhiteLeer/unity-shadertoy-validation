Shader "Shadertoy/lst3Df_BokehBlurOctagon4Pass"
{
    Properties
    {
        _BufferA ("Buffer A", 2D) = "black" {}
        _BufferB ("Buffer B", 2D) = "black" {}
        _BufferC ("Buffer C", 2D) = "black" {}
        _BufferD ("Buffer D", 2D) = "black" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            Name "ForwardUnlit"
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #include "UnityCG.cginc"

            sampler2D _BufferA;
            sampler2D _BufferB;
            sampler2D _BufferC;
            sampler2D _BufferD;
            float4 _STResolution;

            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionCS = UnityObjectToClipPos(input.vertex);
                output.uv = input.uv;
                return output;
            }

            float3 SrgbToLin(float3 c) { return c * c; }
            float3 LinToSrgb(float3 c) { return sqrt(max(c, 0.0)); }

            float4 Frag(Varyings input) : SV_Target
            {
                float2 uv = input.uv;
                float3 s0 = SrgbToLin(tex2Dlod(_BufferA, float4(uv, 0.0, -10.0)).rgb);
                float3 s1 = SrgbToLin(tex2Dlod(_BufferB, float4(uv, 0.0, -10.0)).rgb);
                float3 s2 = SrgbToLin(tex2Dlod(_BufferC, float4(uv, 0.0, -10.0)).rgb);
                float3 s3 = SrgbToLin(tex2Dlod(_BufferD, float4(uv, 0.0, -10.0)).rgb);
                return float4(LinToSrgb(min(s1, s3)), 1.0);
            }
            ENDHLSL
        }
    }
}
