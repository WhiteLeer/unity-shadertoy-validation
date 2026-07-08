using System.IO;
using UnityEngine;

public class ShadertoyXdB3DG_v43Bootstrap : ShadertoyBootstrapBase
{
    protected override string TargetShaderName => "Shadertoy/XdB3DG_AnisotropicHighlights";
    protected override string QuadObjectName => "ST_XdB3DG_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-43/shadertoy-43-capture.resolution.json";

    private const string Channel0RelativePath = "unity-shadertoy-validation/shadertoy-43/Textures/f735bee5b64ef98879dc618b016ecf7939a5756040c2cde21ccb15e69a6e1cfb.png";
    private const string Channel1RelativePath = "unity-shadertoy-validation/shadertoy-43/Textures/92d7758c402f0927011ca8d0a7e40251439fba3a1dac26f5b8b62026323501aa.jpg";

    private Texture2D channel0;
    private Texture2D channel1;

    protected override void ConfigureMaterial(Material material)
    {
        if (material == null)
        {
            return;
        }

        if (channel0 == null)
        {
            channel0 = LoadRuntimeTexture(Channel0RelativePath, "T_XdB3DG_0", TextureWrapMode.Repeat, FilterMode.Trilinear);
        }

        if (channel1 == null)
        {
            channel1 = LoadRuntimeTexture(Channel1RelativePath, "T_XdB3DG_1", TextureWrapMode.Repeat, FilterMode.Trilinear);
        }

        if (channel0 != null)
        {
            material.SetTexture("_Channel0", channel0);
            material.SetVector("_ChannelResolution0", new Vector4(channel0.width, channel0.height, 0f, 0f));
        }

        if (channel1 != null)
        {
            material.SetTexture("_Channel1", channel1);
            material.SetVector("_ChannelResolution1", new Vector4(channel1.width, channel1.height, 0f, 0f));
        }
    }

    private void OnDestroy()
    {
        ReleaseTexture(ref channel0);
        ReleaseTexture(ref channel1);
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
