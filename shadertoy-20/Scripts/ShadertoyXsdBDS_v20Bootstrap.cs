using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoyXsdBDS_v20Bootstrap : ShadertoyBootstrapBase
{
    [SerializeField] private Texture2D channel0Texture;
    [SerializeField] private Vector2Int resolution = new Vector2Int(1024, 576);

    protected override string TargetShaderName => "Shadertoy/XsdBDS_ToonyFire";
    protected override string QuadObjectName => "ST_XsdBDS_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-20/shadertoy-20-capture.resolution.json";

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (channel0Texture == null && "Assets/unity-shadertoy-validation/shadertoy-20/Textures/f735bee5b64ef98879dc618b016ecf7939a5756040c2cde21ccb15e69a6e1cfb.png" != "")
            channel0Texture = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/unity-shadertoy-validation/shadertoy-20/Textures/f735bee5b64ef98879dc618b016ecf7939a5756040c2cde21ccb15e69a6e1cfb.png");
    }
#endif

    protected override void ConfigureMaterial(Material material)
    {
        if (material == null) return;
        if (channel0Texture != null)
        {
            channel0Texture.wrapMode = TextureWrapMode.Repeat;
            channel0Texture.filterMode = FilterMode.Bilinear;
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
