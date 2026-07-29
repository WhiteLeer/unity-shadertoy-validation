using System.IO;
using UnityEngine;

public class ShadertoyXsSGDh_v47Bootstrap : ShadertoyBootstrapBase
{
    protected override string TargetShaderName => "Shadertoy/XsSGDh_Marble";
    protected override string QuadObjectName => "ST_XsSGDh_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-47/shadertoy-47-capture.resolution.json";

    private const string Channel1RelativePath = "unity-shadertoy-validation/shadertoy-47/Textures/95b90082f799f48677b4f206d856ad572f1d178c676269eac6347631d4447258.jpg";
    private const string Channel2RelativePath = "unity-shadertoy-validation/shadertoy-47/Textures/585f9546c092f53ded45332b343144396c0b2d70d9965f585ebc172080d8aa58.jpg";
    private const string Channel3RelativePath = "unity-shadertoy-validation/shadertoy-47/Textures/793a105653fbdadabdc1325ca08675e1ce48ae5f12e37973829c87bea4be3232.png";

    private Texture2D channel1;
    private Texture2D channel2;
    private Texture2D channel3;

    protected override void ConfigureMaterial(Material material)
    {
        if (material == null)
        {
            return;
        }

        if (channel1 == null)
        {
            channel1 = LoadRuntimeTexture(Channel1RelativePath, "T_XsSGDh_1", TextureWrapMode.Repeat, FilterMode.Trilinear);
        }

        if (channel2 == null)
        {
            channel2 = LoadRuntimeTexture(Channel2RelativePath, "T_XsSGDh_2", TextureWrapMode.Clamp, FilterMode.Bilinear);
        }

        if (channel3 == null)
        {
            channel3 = LoadRuntimeTexture(Channel3RelativePath, "T_XsSGDh_3", TextureWrapMode.Clamp, FilterMode.Bilinear);
        }

        if (channel1 != null) material.SetTexture("_Channel1", channel1);
        if (channel2 != null) material.SetTexture("_Channel2", channel2);
        if (channel3 != null) material.SetTexture("_Channel3", channel3);
    }

    private void OnDestroy()
    {
        ReleaseTexture(ref channel1);
        ReleaseTexture(ref channel2);
        ReleaseTexture(ref channel3);
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
