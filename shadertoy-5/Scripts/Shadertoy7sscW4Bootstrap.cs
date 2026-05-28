using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class Shadertoy7sscW4Bootstrap : ShadertoyBootstrapBase
{
    [SerializeField] private Cubemap channel0Cubemap;

    protected override string TargetShaderName => "Shadertoy/7sscW4_MoreFractalRopes";
    protected override string QuadObjectName => "ST_7sscW4_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-5/shadertoy-5-capture.resolution.json";

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (channel0Cubemap == null)
        {
            channel0Cubemap = AssetDatabase.LoadAssetAtPath<Cubemap>(
                "Assets/unity-shadertoy-validation/shadertoy-5/Textures/793a105653fbdadabdc1325ca08675e1ce48ae5f12e37973829c87bea4be3232.png"
            );
        }
    }
#endif

    protected override void ConfigureMaterial(Material material)
    {
        if (material != null && channel0Cubemap != null)
        {
            material.SetTexture("_Channel0", channel0Cubemap);
        }
    }

    protected override void TickCustom(Material material)
    {
        if (material == null) return;
        var mp = Input.mousePosition;
        var down = Input.GetMouseButton(0) ? 1f : 0f;
        material.SetVector("_Mouse", new Vector4(mp.x, mp.y, down, down));
    }
}
