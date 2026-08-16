using UnityEngine;

public class ShadertoyW32XzG_v30Bootstrap : ShadertoyBootstrapBase
{
    protected override string TargetShaderName => "Shadertoy/w32XzG_GlobulesBubbles";
    protected override string TargetShaderAssetPath => "Assets/unity-shadertoy-validation/shadertoy-30/Shaders/shadertoy-w32XzG.shader";
    protected override string QuadObjectName => "ST_w32XzG_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-30/shadertoy-30-capture.resolution.json";

    protected override void ConfigureMaterial(Material material)
    {
        if (material == null)
        {
            return;
        }

        material.SetVector("_STResolution", new Vector4(960f, 540f, 1f / 960f, 1f / 540f));
    }

    protected override void TickCustom(Material material)
    {
        if (material == null)
        {
            return;
        }

        var camera = GetComponent<Camera>();
        if (camera == null)
        {
            camera = Camera.main;
        }

        if (camera == null)
        {
            material.SetVector("_STMouse", Vector4.zero);
            return;
        }

        var viewport = camera.ScreenToViewportPoint(Input.mousePosition);
        if (viewport.x < 0f || viewport.x > 1f || viewport.y < 0f || viewport.y > 1f)
        {
            material.SetVector("_STMouse", Vector4.zero);
            return;
        }

        var mouse = new Vector4(
            viewport.x * 960f,
            viewport.y * 540f,
            Input.GetMouseButton(0) ? 1f : 0f,
            Input.GetMouseButton(0) ? 1f : 0f
        );
        material.SetVector("_STMouse", mouse);
    }
}
