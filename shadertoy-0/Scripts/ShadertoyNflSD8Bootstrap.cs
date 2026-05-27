using UnityEngine;

[DisallowMultipleComponent]
public class ShadertoyNflSD8Bootstrap : ShadertoyBootstrapBase
{
    protected override string TargetShaderName => "Shadertoy/NflSD8_Unimagined";
    protected override string QuadObjectName => "ST_NflSD8_Quad";
    protected override string DefaultResolutionJsonRelativePath => "Shadertoy/shadertoy-0/shadertoy-0-capture.resolution.json";
}

