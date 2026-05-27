using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoyXlBSRzBootstrap : ShadertoyBootstrapBase
{
    [SerializeField] private Texture2D channel0Texture;

    protected override string TargetShaderName => "Shadertoy/XlBSRz_VolumetricIntegration";
    protected override string QuadObjectName => "ST_XlBSRz_Quad";
    protected override string DefaultResolutionJsonRelativePath => "Shadertoy/shadertoy-4/shadertoy-4-capture.resolution.json";

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (channel0Texture == null)
        {
            channel0Texture = AssetDatabase.LoadAssetAtPath<Texture2D>(
                "Assets/Shadertoy/shadertoy-4/Textures/0a40562379b63dfb89227e6d172f39fdce9022cba76623f1054a2c83d6c0ba5d.png"
            );
        }
    }
#endif

    protected override void ConfigureMaterial(Material material)
    {
        if (material != null && channel0Texture != null)
        {
            material.SetTexture("_Channel0", channel0Texture);
        }
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
