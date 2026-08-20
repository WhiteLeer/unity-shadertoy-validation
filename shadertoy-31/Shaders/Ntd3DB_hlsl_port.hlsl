static const float ST_CHROMATIC_ABERRATION = 0.02;
static const float ST_ITERATIONS = 20.0;
static const float ST_INITIAL_LUMA = 0.5;

float2x2 Rotate2D(float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return float2x2(c, -s, s, c);
}

float2 ST_Mod(float2 x, float y)
{
    return x - y * floor(x / y);
}

float GetColorComponent(float2 st, float modScale, float blur, float shapeSize)
{
    float2 modSt = ST_Mod(st, 1.0 / modScale) * modScale * 2.0 - 1.0;
    float dist = length(modSt);
    float angle = atan2(modSt.x, modSt.y);
    float shapeMap = smoothstep(shapeSize + blur, shapeSize - blur, dist);
    return shapeMap;
}

float4 RenderBlackHolesAcid(float2 fragCoord)
{
    float2 resolution = _STResolution.xy;
    float2 st = (2.0 * fragCoord - resolution) / min(resolution.x, resolution.y);

    st = mul(st, Rotate2D(sin(_STTime * 0.6 + st.x + st.y) * 0.3));
    st *= (sin(_STTime * 0.3) + 2.0) * 0.3;
    st *= log(length(sin(st * 5.18)) * cos(_STTime * 0.1) + 1.2) * 5.0;

    float modScale = 1.0;
    float3 color = float3(0, 0, 0);
    float luma = ST_INITIAL_LUMA;
    float blur = 0.2;
    float shapeSize = 0.2 + (sin(_STTime * 0.7) + 1.0) * 0.2;

    [loop]
    for (int iteration = 0; iteration < 20; ++iteration)
    {
        float i = (float)iteration;
        float2 center = st + float2(sin(_STTime * 0.5), cos(_STTime * 0.3)) * 2.0;

        float3 shapeColor = float3(
            GetColorComponent(center - st * ST_CHROMATIC_ABERRATION, modScale, blur, shapeSize),
            GetColorComponent(center, modScale, blur, shapeSize),
            GetColorComponent(center + st * ST_CHROMATIC_ABERRATION, modScale, blur, shapeSize)
        ) * luma;

        st *= 1.1;
        st = mul(st, Rotate2D(sin(_STTime * 0.05) * 0.3));
        color += shapeColor;
        color = clamp(color, 0.0, 1.0);

        if (all(color == float3(1, 1, 1)))
        {
            break;
        }

        luma *= 0.8;
        blur *= 0.63;
    }

    return float4(color, 1.0);
}
