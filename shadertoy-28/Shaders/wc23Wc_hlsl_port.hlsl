float4 RenderGrok(float2 fragCoord)
{
    float2 r = _STResolution.xy;
    float2 p = (fragCoord + fragCoord - r) / r.y;
    float4 pBroadcastY = float4(p.y, p.y, p.y, p.y);
    return 0.1 / abs(length(p) - 0.5 + 0.01 / (p.xxxx - pBroadcastY));
}
