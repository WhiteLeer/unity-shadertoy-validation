using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoyttXczl_v17Bootstrap : ShadertoyBootstrapBase
{
    [SerializeField] private Texture2D channel0Texture;
    [SerializeField] private Texture2D channel1Texture;
    [SerializeField] private Vector2Int resolution = new Vector2Int(512, 288);

    protected override string TargetShaderName => "Shadertoy/ttXczl_Screenprinting";
    protected override string QuadObjectName => "ST_ttXczl_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-17/shadertoy-17-capture.resolution.json";

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (channel0Texture == null && "Assets/unity-shadertoy-validation/shadertoy-17/Textures/f735bee5b64ef98879dc618b016ecf7939a5756040c2cde21ccb15e69a6e1cfb.png" != "") channel0Texture = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/unity-shadertoy-validation/shadertoy-17/Textures/f735bee5b64ef98879dc618b016ecf7939a5756040c2cde21ccb15e69a6e1cfb.png");
        if (channel1Texture == null && "Assets/unity-shadertoy-validation/shadertoy-17/Textures/fb918796edc3d2221218db0811e240e72e340350008338b0c07a52bd353666a6.jpg" != "") channel1Texture = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/unity-shadertoy-validation/shadertoy-17/Textures/fb918796edc3d2221218db0811e240e72e340350008338b0c07a52bd353666a6.jpg");
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
        if (channel1Texture != null)
        {
            channel1Texture.wrapMode = TextureWrapMode.Repeat;
            channel1Texture.filterMode = FilterMode.Trilinear;
            material.SetTexture("_Channel1", channel1Texture);
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
