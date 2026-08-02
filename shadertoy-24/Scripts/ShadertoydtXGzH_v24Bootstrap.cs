using System.IO;
using UnityEngine;

public class ShadertoydtXGzH_v24Bootstrap : ShadertoyBootstrapBase
{
    protected override string TargetShaderName => "Shadertoy/dtXGzH_VolumetricFurBalls";
    protected override string QuadObjectName => "ST_dtXGzH_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-24/shadertoy-24-capture.resolution.json";

    private const string Channel0RelativePath = "unity-shadertoy-validation/shadertoy-24/Textures/3083c722c0c738cad0f468383167a0d246f91af2bfa373e9c5c094fb8c8413e0.png";

    private Texture2D channel0;

    protected override void ConfigureMaterial(Material material)
    {
        if (material == null)
        {
            return;
        }

        if (channel0 == null)
        {
            channel0 = LoadRuntimeTexture(Channel0RelativePath, "T_dtXGzH_0", TextureWrapMode.Repeat, FilterMode.Trilinear);
        }

        if (channel0 != null)
        {
            material.SetTexture("_Channel0", channel0);
        }
    }

    private void OnDestroy()
    {
        ReleaseTexture(ref channel0);
    }

    private static Texture2D LoadRuntimeTexture(string relativePath, string name, TextureWrapMode wrapMode, FilterMode filterMode)
    {
        string fullPath = Path.Combine(Application.dataPath, relativePath.Replace('/', Path.DirectorySeparatorChar));
        if (!File.Exists(fullPath))
        {
            Debug.LogWarning($"[Shadertoy] Missing texture: {fullPath}");
            return null;
        }

        byte[] bytes = File.ReadAllBytes(fullPath);
        var texture = new Texture2D(2, 2, TextureFormat.RGBA32, true, true)
        {
            name = name,
            wrapMode = wrapMode,
            filterMode = filterMode
        };
        texture.LoadImage(bytes, false);
        texture.wrapMode = wrapMode;
        texture.filterMode = filterMode;
        texture.Apply(true, false);
        return texture;
    }

    private static void ReleaseTexture(ref Texture2D texture)
    {
        if (texture == null)
        {
            return;
        }

        if (Application.isPlaying)
        {
            Object.Destroy(texture);
        }
        else
        {
            Object.DestroyImmediate(texture);
        }

        texture = null;
    }
}
