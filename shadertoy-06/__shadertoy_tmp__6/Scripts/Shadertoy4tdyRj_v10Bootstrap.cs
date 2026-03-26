using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class Shadertoy4tdyRj_v10Bootstrap : ShadertoyBootstrapBase
{
    protected override string TargetShaderName => "Shadertoy/4tdyRj_ProceduralPlant";
    protected override string QuadObjectName => "ST_4tdyRj_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-10/shadertoy-10-capture.resolution.json";

#if UNITY_EDITOR
    private void OnValidate() { }
#endif

    protected override void ConfigureMaterial(Material material) { }
}
