using System.IO;
using UnityEngine;

public class Shadertoylst3Df_v41Bootstrap : ShadertoyBootstrapBase
{
    protected override string TargetShaderName => "Shadertoy/lst3Df_BokehBlurOctagon4Pass";
    protected override string QuadObjectName => "ST_lst3Df_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-41/shadertoy-41-capture.resolution.json";

    private const string Texture0RelativePath = "unity-shadertoy-validation/shadertoy-41/Textures/e6e5631ce1237ae4c05b3563eda686400a401df4548d0f9fad40ecac1659c46c.jpg";
    private const string Texture1RelativePath = "unity-shadertoy-validation/shadertoy-41/Textures/fb918796edc3d2221218db0811e240e72e340350008338b0c07a52bd353666a6.jpg";
    private const string Texture2RelativePath = "unity-shadertoy-validation/shadertoy-41/Textures/92d7758c402f0927011ca8d0a7e40251439fba3a1dac26f5b8b62026323501aa.jpg";

    private Material matA;
    private Material matB;
    private Material matC;
    private Material matD;
    private RenderTexture rtA;
    private RenderTexture rtB;
    private RenderTexture rtC;
    private RenderTexture rtD;
    private Texture2D tex0;
    private Texture2D tex1;
    private Texture2D tex2;
    private int cachedWidth;
    private int cachedHeight;

    private void OnDestroy()
    {
        ReleaseResources();
    }

    protected override void TickCustom(Material material)
    {
        if (material == null)
        {
            return;
        }

        Vector4 resolution = material.GetVector("_STResolution");
        int width = Mathf.Max(1, Mathf.RoundToInt(resolution.x));
        int height = Mathf.Max(1, Mathf.RoundToInt(resolution.y));
        EnsureResources(width, height);
        if (matA == null || matB == null || matC == null || matD == null || tex0 == null || tex1 == null || tex2 == null)
        {
            return;
        }

        PushCommon(matA, material);
        PushCommon(matB, material);
        PushCommon(matC, material);
        PushCommon(matD, material);

        matA.SetTexture("_Tex0", tex0);
        matA.SetTexture("_Tex1", tex1);
        matA.SetTexture("_Tex2", tex2);

        matC.SetTexture("_Tex0", tex0);
        matC.SetTexture("_Tex1", tex1);
        matC.SetTexture("_Tex2", tex2);

        Graphics.Blit(Texture2D.blackTexture, rtA, matA, 0);
        matB.SetTexture("_SourceTex", rtA);
        Graphics.Blit(Texture2D.blackTexture, rtB, matB, 0);

        Graphics.Blit(Texture2D.blackTexture, rtC, matC, 0);
        matD.SetTexture("_SourceTex", rtC);
        Graphics.Blit(Texture2D.blackTexture, rtD, matD, 0);

        material.SetTexture("_BufferA", rtA);
        material.SetTexture("_BufferB", rtB);
        material.SetTexture("_BufferC", rtC);
        material.SetTexture("_BufferD", rtD);
    }

    private void EnsureResources(int width, int height)
    {
        if (cachedWidth != width || cachedHeight != height)
        {
            ReleaseRenderTextures();
            cachedWidth = width;
            cachedHeight = height;
        }

        if (matA == null) { matA = CreateMaterial("Shadertoy/lst3Df_BufferA", "M_ST_lst3Df_A_Runtime"); }
        if (matB == null) { matB = CreateMaterial("Shadertoy/lst3Df_BufferB", "M_ST_lst3Df_B_Runtime"); }
        if (matC == null) { matC = CreateMaterial("Shadertoy/lst3Df_BufferC", "M_ST_lst3Df_C_Runtime"); }
        if (matD == null) { matD = CreateMaterial("Shadertoy/lst3Df_BufferD", "M_ST_lst3Df_D_Runtime"); }

        if (rtA == null) { rtA = CreateRt(width, height, "RT_lst3Df_A"); }
        if (rtB == null) { rtB = CreateRt(width, height, "RT_lst3Df_B"); }
        if (rtC == null) { rtC = CreateRt(width, height, "RT_lst3Df_C"); }
        if (rtD == null) { rtD = CreateRt(width, height, "RT_lst3Df_D"); }

        if (tex0 == null) { tex0 = LoadRuntimeTexture(Texture0RelativePath, "T_lst3Df_0"); }
        if (tex1 == null) { tex1 = LoadRuntimeTexture(Texture1RelativePath, "T_lst3Df_1"); }
        if (tex2 == null) { tex2 = LoadRuntimeTexture(Texture2RelativePath, "T_lst3Df_2"); }
    }

    private static Material CreateMaterial(string shaderName, string runtimeName)
    {
        Shader shader = Shader.Find(shaderName);
        if (shader == null)
        {
            Debug.LogError($"Shader not found: {shaderName}");
            return null;
        }

        return new Material(shader) { name = runtimeName };
    }

    private static RenderTexture CreateRt(int width, int height, string name)
    {
        var rt = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBHalf)
        {
            name = name,
            wrapMode = TextureWrapMode.Clamp,
            filterMode = FilterMode.Bilinear,
            useMipMap = false,
            autoGenerateMips = false
        };
        rt.Create();
        return rt;
    }

    private static void PushCommon(Material target, Material source)
    {
        target.SetVector("_STResolution", source.GetVector("_STResolution"));
        if (source.HasProperty("_STTime"))
        {
            target.SetFloat("_STTime", source.GetFloat("_STTime"));
        }
        if (source.HasProperty("_STMouse"))
        {
            target.SetVector("_STMouse", source.GetVector("_STMouse"));
        }
    }

    private static Texture2D LoadRuntimeTexture(string relativePath, string name)
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
            wrapMode = TextureWrapMode.Repeat,
            filterMode = FilterMode.Trilinear
        };
        texture.LoadImage(bytes, false);
        texture.wrapMode = TextureWrapMode.Repeat;
        texture.filterMode = FilterMode.Trilinear;
        texture.Apply(true, false);
        return texture;
    }

    private void ReleaseResources()
    {
        ReleaseRenderTextures();
        ReleaseMaterial(ref matA);
        ReleaseMaterial(ref matB);
        ReleaseMaterial(ref matC);
        ReleaseMaterial(ref matD);
        ReleaseTexture(ref tex0);
        ReleaseTexture(ref tex1);
        ReleaseTexture(ref tex2);
    }

    private void ReleaseRenderTextures()
    {
        ReleaseRt(ref rtA);
        ReleaseRt(ref rtB);
        ReleaseRt(ref rtC);
        ReleaseRt(ref rtD);
    }

    private static void ReleaseMaterial(ref Material material)
    {
        if (material == null)
        {
            return;
        }

        if (Application.isPlaying)
        {
            Object.Destroy(material);
        }
        else
        {
            Object.DestroyImmediate(material);
        }
        material = null;
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

    private static void ReleaseRt(ref RenderTexture rt)
    {
        if (rt == null)
        {
            return;
        }

        rt.Release();
        if (Application.isPlaying)
        {
            Object.Destroy(rt);
        }
        else
        {
            Object.DestroyImmediate(rt);
        }
        rt = null;
    }
}
