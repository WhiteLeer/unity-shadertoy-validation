#ifndef SHADERTOY_DEPTH_ONLY_PASS_INCLUDED
#define SHADERTOY_DEPTH_ONLY_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct DepthOnlyVaryings
{
    float4 positionCS : SV_POSITION;
};

struct DepthOnlyAttributes
{
    float4 positionOS : POSITION;
};

DepthOnlyVaryings DepthOnlyVertex(DepthOnlyAttributes input)
{
    DepthOnlyVaryings output = (DepthOnlyVaryings)0;

    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    return output;
}

half4 DepthOnlyFragment(DepthOnlyVaryings input) : SV_Target
{
    return half4(0, 0, 0, 0);
}

#endif
