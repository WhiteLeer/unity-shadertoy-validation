using UnityEngine;

public class ShadertoyNtd3DB_v31Bootstrap : ShadertoyBootstrapBase
{
    protected override string TargetShaderName => "Shadertoy/Ntd3DB_BlackHolesAcid";
    protected override string TargetShaderAssetPath => "Assets/unity-shadertoy-validation/shadertoy-31/Shaders/shadertoy-Ntd3DB.shader";
    protected override string QuadObjectName => "ST_Ntd3DB_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-31/shadertoy-31-capture.resolution.json";

    protected override void ConfigureMaterial(Material material)
    {
        if (material == null)
        {
            return;
        }

        material.SetVector("_STResolution", new Vector4(960f, 540f, 1f / 960f, 1f / 540f));
    }
}
