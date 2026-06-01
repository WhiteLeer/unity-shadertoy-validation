// Shared GLSL -> HLSL compatibility helpers for Shadertoy ports.
// Include this in every converted shader before implementing main logic.

#ifndef SHADERTOY_COMPAT_INCLUDED
#define SHADERTOY_COMPAT_INCLUDED

// Prefer this to atan/atan2 directly when porting GLSL atan(y, x).
inline float AtanGLSL(float y, float x)
{
    return atan2(y, x);
}

inline float2 AtanGLSL(float2 y, float2 x)
{
    return float2(atan2(y.x, x.x), atan2(y.y, x.y));
}

// GLSL mod semantics for negative values.
inline float ModGLSL(float x, float y)
{
    return x - y * floor(x / y);
}

inline float2 ModGLSL(float2 x, float2 y)
{
    return x - y * floor(x / y);
}

inline float2 ModGLSL(float2 x, float y)
{
    return x - y * floor(x / y);
}

inline float3 ModGLSL(float3 x, float3 y)
{
    return x - y * floor(x / y);
}

inline float3 ModGLSL(float3 x, float y)
{
    return x - y * floor(x / y);
}

// GLSL repeat helper.
inline float RepeatGLSL(float x, float period)
{
    return ModGLSL(x + 0.5 * period, period) - 0.5 * period;
}

// Safe asin input clamp, avoids NaN and hemisphere clipping mistakes.
inline float SafeAsin(float x)
{
    return asin(clamp(x, -0.999999f, 0.999999f));
}

inline float2 SafeAsin(float2 x)
{
    return asin(clamp(x, -0.999999f, 0.999999f));
}

inline float3 SafeAsin(float3 x)
{
    return asin(clamp(x, -0.999999f, 0.999999f));
}

inline float4 SafeAsin(float4 x)
{
    return asin(clamp(x, -0.999999f, 0.999999f));
}

// Explicit UV origin conversions. Shadertoy logic expects bottom-left UV.
inline float2 ToShadertoyUV(float2 uvTopLeft)
{
    return float2(uvTopLeft.x, 1.0f - uvTopLeft.y);
}

// Explicit matrix application matching common GLSL vector-matrix expectation.
inline float2 MulMat2GLSL(float2 v, float2x2 m)
{
    return mul(v, m);
}

// Avoid repeated scalar-vector constructor mistakes in ports.
inline float2 V2(float x) { return float2(x, x); }
inline float3 V3(float x) { return float3(x, x, x); }
inline float4 V4(float x) { return float4(x, x, x, x); }

#endif
