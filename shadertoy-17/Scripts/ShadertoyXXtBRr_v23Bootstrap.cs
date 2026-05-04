using UnityEngine;

[DisallowMultipleComponent]
public class ShadertoyXXtBRr_v23Bootstrap : ShadertoyBootstrapBase
{
    [SerializeField] private Vector2Int resolution = new Vector2Int(512, 288);

    protected override string TargetShaderName => "Shadertoy/XXtBRr_BalatroSwirl";
    protected override string QuadObjectName => "ST_XXtBRr_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-23/shadertoy-23-capture.resolution.json";

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
