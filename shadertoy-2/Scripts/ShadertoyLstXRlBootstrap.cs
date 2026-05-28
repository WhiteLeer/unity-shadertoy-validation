using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoyLstXRlBootstrap : ShadertoyBootstrapBase
{
    [SerializeField] private Cubemap channel0Cubemap;
    [SerializeField] private Texture2D channel1Texture;

    protected override string TargetShaderName => "Shadertoy/lstXRl_RayMarchingExperiment43";
    protected override string QuadObjectName => "ST_lstXRl_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-2/shadertoy-2-capture.resolution.json";

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (channel0Cubemap == null)
        {
            channel0Cubemap = AssetDatabase.LoadAssetAtPath<Cubemap>(
                "Assets/unity-shadertoy-validation/shadertoy-2/Textures/793a105653fbdadabdc1325ca08675e1ce48ae5f12e37973829c87bea4be3232.png"
            );
        }

        if (channel1Texture == null)
        {
            channel1Texture = AssetDatabase.LoadAssetAtPath<Texture2D>(
                "Assets/unity-shadertoy-validation/shadertoy-2/Textures/ad56fba948dfba9ae698198c109e71f118a54d209c0ea50d77ea546abad89c57.png"
            );
        }
    }
#endif

    protected override void ConfigureMaterial(Material material)
    {
        if (material == null)
        {
            return;
        }

        if (channel0Cubemap != null)
        {
            material.SetTexture("_Channel0", channel0Cubemap);
        }

        if (channel1Texture != null)
        {
            material.SetTexture("_Channel1", channel1Texture);
        }
    }
}


