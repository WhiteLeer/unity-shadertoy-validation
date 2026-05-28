using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoywsXBWS_v11Bootstrap : ShadertoyBootstrapBase
{
    [SerializeField] private Texture2D channel0Texture;

    protected override string TargetShaderName => "Shadertoy/wsXBWS_ComicBlobs";
    protected override string QuadObjectName => "ST_wsXBWS_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-11/shadertoy-11-capture.resolution.json";

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (channel0Texture == null && "Assets/unity-shadertoy-validation/shadertoy-11/Textures/85a6d68622b36995ccb98a89bbb119edf167c914660e4450d313de049320005c.png" != "") channel0Texture = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/unity-shadertoy-validation/shadertoy-11/Textures/85a6d68622b36995ccb98a89bbb119edf167c914660e4450d313de049320005c.png");
    }
#endif

    protected override void ConfigureMaterial(Material material)
    {
        if (material == null) return;
        if (channel0Texture != null) material.SetTexture("_Channel0", channel0Texture);
    }
}
