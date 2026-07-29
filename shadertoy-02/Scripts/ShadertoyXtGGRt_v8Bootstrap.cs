using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoyXtGGRt_v8Bootstrap : ShadertoyBootstrapBase
{
    protected override string TargetShaderName => "Shadertoy/XtGGRt_Auroras";
    protected override string QuadObjectName => "ST_XtGGRt_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-8/shadertoy-8-capture.resolution.json";

#if UNITY_EDITOR
    private void OnValidate() { }
#endif

    protected override void ConfigureMaterial(Material material)
    {
        if (material == null)
        {
            return;
        }
        material.SetVector("_Mouse", Vector4.zero);
    }

    protected override void TickCustom(Material material)
    {
        if (material == null)
        {
            return;
        }
        var mp = Input.mousePosition;
        var down = Input.GetMouseButton(0) ? 1f : 0f;
        material.SetVector("_Mouse", new Vector4(mp.x, mp.y, down, down));
    }
}
