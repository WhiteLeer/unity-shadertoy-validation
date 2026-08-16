#define ST_R _STResolution.xy
#define ST_H(v) frac(1e4 * sin(1e4 * (i)))

float4 ST_Hue(float v)
{
    return 0.6 + 0.6 * cos(6.3 * v + float4(0, 23, 21, 0));
}

float PushHole(float2 U, out float depth)
{
    float pushDistance = 0.15;
    float slope = 2.0;
    float2 mouse = _STMouse.xy;

    if (length(mouse) > 10.0)
    {
        mouse /= ST_R;
        pushDistance = mouse.y;
        slope = 1.0 / (0.01 + mouse.x);
    }

    depth = pushDistance / length(U);
    return depth > 1.0 ? 0.0 : pow(1.0 - pow(depth, slope), 1.0 / slope);
}

float4 RenderGlobulesBubbles(float2 fragCoord)
{
    float2 R = _STResolution.xy;
    float2 U = (2.0 * fragCoord - R) / R.y;
    float4 O = float4(0, 0, 0, 0);
    float2 V;
    float2 P;
    float v;
    float i = 1.0;
    float d = 1.0;

    [loop]
    for (int iter = 0; iter < 200; ++iter)
    {
        P = (
            float2(cos(_STTime / 4.0 + i * 17.0), sin(_STTime / 4.0 * 1.3 - i * 3.0))
            + float2(sin(-_STTime / 4.0 * 1.5 + i * 13.0), cos(_STTime / 4.0 * 2.1 - i * 7.0))
        ) / 2.0 * R / R.y;

        V = U - P;

        float localDepth;
        v = PushHole(V, localDepth);
        d = min(d, abs(localDepth - 1.0) / min(1.0, fwidth(localDepth)));

        if (v == 0.0 && all(O == (O - O)))
        {
            O = 0.3 + 0.8 * ST_Hue(i / 100.0);
        }

        U = P + v * V;
        i += 1.0;
    }

    O *= smoothstep(0.0, 1.5, d);
    return O;
}
