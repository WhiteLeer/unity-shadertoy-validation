using UnityEngine;

public class Shadertoy43cBzn_v27Bootstrap : ShadertoyBootstrapBase
{
    protected override string TargetShaderName => "Shadertoy/43cBzn_GridAttractor";
    protected override string TargetShaderAssetPath => "Assets/unity-shadertoy-validation/shadertoy-27/Shaders/shadertoy-43cBzn.shader";
    protected override string QuadObjectName => "ST_43cBzn_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-27/shadertoy-27-capture.resolution.json";

    protected override void ConfigureMaterial(Material material)
    {
        if (material == null)
        {
            return;
        }

        material.SetVector("_STResolution", new Vector4(960f, 540f, 1f / 960f, 1f / 540f));
    }
}
