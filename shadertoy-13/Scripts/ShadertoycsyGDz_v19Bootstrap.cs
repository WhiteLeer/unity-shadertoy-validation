using UnityEngine;

[DisallowMultipleComponent]
public class ShadertoycsyGDz_v19Bootstrap : ShadertoyBootstrapBase
{
    [SerializeField] private Vector2Int resolution = new Vector2Int(512, 288);

    protected override string TargetShaderName => "Shadertoy/csyGDz_ToonFlame";
    protected override string QuadObjectName => "ST_csyGDz_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-19/shadertoy-19-capture.resolution.json";

    protected override void ConfigureMaterial(Material material)
    {
        if (material == null) return;
        material.SetVector("_STResolution", new Vector4(resolution.x, resolution.y, 1f / Mathf.Max(1, resolution.x), 1f / Mathf.Max(1, resolution.y)));
        material.SetFloat("_STTime", 0f);
    }

    protected override void TickCustom(Material material)
    {
        if (material == null) return;
        material.SetVector("_STResolution", new Vector4(resolution.x, resolution.y, 1f / Mathf.Max(1, resolution.x), 1f / Mathf.Max(1, resolution.y)));
        material.SetFloat("_STTime", Time.time);
    }
}
