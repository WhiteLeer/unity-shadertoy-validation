using UnityEngine;

public class ShadertoyXdyXz3_v29Bootstrap : ShadertoyBootstrapBase
{
    protected override string TargetShaderName => "Shadertoy/XdyXz3_NoiseHoles";
    protected override string TargetShaderAssetPath => "Assets/unity-shadertoy-validation/shadertoy-29/Shaders/shadertoy-XdyXz3.shader";
    protected override string QuadObjectName => "ST_XdyXz3_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-29/shadertoy-29-capture.resolution.json";

    protected override void ConfigureMaterial(Material material)
    {
        if (material == null)
        {
            return;
        }

        material.SetVector("_STResolution", new Vector4(960f, 540f, 1f / 960f, 1f / 540f));
    }
}
