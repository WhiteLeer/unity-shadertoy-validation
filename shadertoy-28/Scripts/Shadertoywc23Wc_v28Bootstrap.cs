using UnityEngine;

public class Shadertoywc23Wc_v28Bootstrap : ShadertoyBootstrapBase
{
    protected override string TargetShaderName => "Shadertoy/wc23Wc_Grok";
    protected override string TargetShaderAssetPath => "Assets/unity-shadertoy-validation/shadertoy-28/Shaders/shadertoy-wc23Wc.shader";
    protected override string QuadObjectName => "ST_wc23Wc_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-28/shadertoy-28-capture.resolution.json";

    protected override void ConfigureMaterial(Material material)
    {
        if (material == null)
        {
            return;
        }

        material.SetVector("_STResolution", new Vector4(960f, 540f, 1f / 960f, 1f / 540f));
    }
}
