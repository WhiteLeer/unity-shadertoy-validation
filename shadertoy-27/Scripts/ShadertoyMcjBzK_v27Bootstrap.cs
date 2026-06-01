using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoyMcjBzK_v27Bootstrap : ShadertoyBootstrapBase
{
    [SerializeField] private Texture2D channel0Texture;
    [SerializeField] private Vector2Int resolution = new Vector2Int(512, 288);

    protected override string TargetShaderName => "Shadertoy/McjBzK_PixelScan";
    protected override string QuadObjectName => "ST_McjBzK_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-27/shadertoy-27-capture.resolution.json";

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (channel0Texture == null)
            channel0Texture = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/unity-shadertoy-validation/shadertoy-27/Textures/8de3a3924cb95bd0e95a443fff0326c869f9d4979cd1d5b6e94e2a01f5be53e9.jpg");
    }
#endif

    protected override void ConfigureMaterial(Material material)
    {
        if (material == null) return;
        if (channel0Texture != null)
        {
            channel0Texture.wrapMode = TextureWrapMode.Repeat;
            channel0Texture.filterMode = FilterMode.Trilinear;
            material.SetTexture("_Channel0", channel0Texture);
        }
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
