using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoydlScDt_v13Bootstrap : ShadertoyBootstrapBase
{
    protected override string TargetShaderName => "Shadertoy/dlScDt_WaterToonTorrent";
    protected override string QuadObjectName => "ST_dlScDt_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-13/shadertoy-13-capture.resolution.json";

#if UNITY_EDITOR
    private void OnValidate()
    {
    }
#endif

    protected override void ConfigureMaterial(Material material) { }
}
