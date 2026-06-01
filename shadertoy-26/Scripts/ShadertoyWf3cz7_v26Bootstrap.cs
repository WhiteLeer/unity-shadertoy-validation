using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoyWf3cz7_v26Bootstrap : ShadertoyBootstrapBase
{
    [SerializeField] private Texture2D channel0Texture;
    [SerializeField] private Vector2Int resolution = new Vector2Int(512, 288);

    protected override string TargetShaderName => "Shadertoy/Wf3cz7_DistortedGlow";
    protected override string QuadObjectName => "ST_Wf3cz7_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-26/shadertoy-26-capture.resolution.json";

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (channel0Texture == null)
            channel0Texture = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/unity-shadertoy-validation/shadertoy-26/Textures/08b42b43ae9d3c0605da11d0eac86618ea888e62cdd9518ee8b9097488b31560.png");
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
