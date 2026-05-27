using UnityEngine;

[DisallowMultipleComponent]
public class Shadertoy4tc3DXBootstrap : ShadertoyBootstrapBase
{
    protected override string TargetShaderName => "Shadertoy/4tc3DX_GloriousLine";
    protected override string QuadObjectName => "ST_4tc3DX_Quad";
    protected override string DefaultResolutionJsonRelativePath => "Shadertoy/shadertoy-1/shadertoy-1-capture.resolution.json";
}
