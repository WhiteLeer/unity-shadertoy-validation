using System;
using System.Globalization;
using System.IO;
using System.Text.RegularExpressions;
using UnityEngine;

public class ShadertoyMdGBWG_v40Bootstrap : ShadertoyBootstrapBase
{
    protected override string TargetShaderName => "Shadertoy/MdGBWG_GlobalWindCirculation";
    protected override string QuadObjectName => "ST_MdGBWG_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-40/shadertoy-40-capture.resolution.json";

    private const string LandSourceRelativePath = "unity-shadertoy-validation/shadertoy-40/Shaders/MdGBWG_2_buffer.glsl";

    private Material bufferBMaterial;
    private Material bufferCMaterial;
    private RenderTexture prevB;
    private RenderTexture currB;
    private RenderTexture prevC;
    private RenderTexture currC;
    private Texture2D landTexture;
    private int simulationFrame;
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

        var resolution = material.GetVector("_STResolution");
        var width = Mathf.Max(1, Mathf.RoundToInt(resolution.x));
        var height = Mathf.Max(1, Mathf.RoundToInt(resolution.y));
        EnsureResources(width, height);
        if (bufferBMaterial == null || bufferCMaterial == null || landTexture == null || prevB == null || prevC == null)
        {
            return;
        }

        PushBufferUniforms(bufferBMaterial, material);
        bufferBMaterial.SetTexture("_LandTex", landTexture);
        bufferBMaterial.SetTexture("_PrevBTex", prevB);
        Graphics.Blit(Texture2D.blackTexture, currB, bufferBMaterial);

        PushBufferUniforms(bufferCMaterial, material);
        bufferCMaterial.SetFloat("_SimFrame", simulationFrame);
        bufferCMaterial.SetTexture("_PrevCTex", prevC);
        bufferCMaterial.SetTexture("_BufferBTex", currB);
        Graphics.Blit(Texture2D.blackTexture, currC, bufferCMaterial);

        Swap(ref prevB, ref currB);
        Swap(ref prevC, ref currC);
        simulationFrame++;

        material.SetTexture("_LandTex", landTexture);
        material.SetTexture("_BufferBTex", prevB);
        material.SetTexture("_BufferCTex", prevC);
    }

    private void EnsureResources(int width, int height)
    {
        if (cachedWidth != width || cachedHeight != height)
        {
            ReleaseResources();
            cachedWidth = width;
            cachedHeight = height;
        }

        if (bufferBMaterial == null)
        {
            var shader = Shader.Find("Shadertoy/MdGBWG_BufferB");
            if (shader != null)
            {
                bufferBMaterial = new Material(shader) { name = "M_ST_MdGBWG_BufferB_Runtime" };
            }
        }

        if (bufferCMaterial == null)
        {
            var shader = Shader.Find("Shadertoy/MdGBWG_BufferC");
            if (shader != null)
            {
                bufferCMaterial = new Material(shader) { name = "M_ST_MdGBWG_BufferC_Runtime" };
            }
        }

        if (prevB == null)
        {
            prevB = CreateRt(width, height, "RT_MdGBWG_B_Prev");
            currB = CreateRt(width, height, "RT_MdGBWG_B_Curr");
        }

        if (prevC == null)
        {
            prevC = CreateRt(width, height, "RT_MdGBWG_C_Prev");
            currC = CreateRt(width, height, "RT_MdGBWG_C_Curr");
        }

        if (landTexture == null)
        {
            landTexture = BuildLandTexture(width, height);
        }
    }

    private static RenderTexture CreateRt(int width, int height, string name)
    {
        var rt = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat)
        {
            name = name,
            wrapMode = TextureWrapMode.Clamp,
            filterMode = FilterMode.Bilinear,
            useMipMap = false,
            autoGenerateMips = false
        };
        rt.Create();
        var active = RenderTexture.active;
        RenderTexture.active = rt;
        GL.Clear(false, true, Color.clear);
        RenderTexture.active = active;
        return rt;
    }

    private void PushBufferUniforms(Material target, Material source)
    {
        target.SetVector("_STResolution", source.GetVector("_STResolution"));
        if (source.HasProperty("_STTime"))
        {
            target.SetFloat("_STTime", source.GetFloat("_STTime"));
        }
    }

    private Texture2D BuildLandTexture(int width, int height)
    {
        var fullPath = Path.Combine(Application.dataPath, LandSourceRelativePath.Replace('/', Path.DirectorySeparatorChar));
        if (!File.Exists(fullPath))
        {
            Debug.LogWarning($"[Shadertoy] Missing land source: {fullPath}");
            return null;
        }

        var text = File.ReadAllText(fullPath);
        var sizeMatch = Regex.Match(text, @"const\s+vec2\s+bitmap_size\s*=\s*vec2\((\d+),\s*(\d+)\)");
        var paletteMatch = Regex.Match(text, @"const\s+int\[\]\s+palette\s*=\s*int\[\]\s*\((.*?)\);", RegexOptions.Singleline);
        var rleMatch = Regex.Match(text, @"const\s+int\[\]\s+rle\s*=\s*int\[\]\s*\((.*?)\);", RegexOptions.Singleline);
        if (!sizeMatch.Success || !paletteMatch.Success || !rleMatch.Success)
        {
            Debug.LogWarning("[Shadertoy] Failed to parse land source arrays.");
            return null;
        }

        var mapWidth = int.Parse(sizeMatch.Groups[1].Value, CultureInfo.InvariantCulture);
        var mapHeight = int.Parse(sizeMatch.Groups[2].Value, CultureInfo.InvariantCulture);
        var palette = ParseUintArray(paletteMatch.Groups[1].Value);
        var rle = ParseUintArray(rleMatch.Groups[1].Value);

        var texture = new Texture2D(width, height, TextureFormat.RGBA32, false, true)
        {
            name = "T_MdGBWG_LandMap_Runtime",
            wrapMode = TextureWrapMode.Clamp,
            filterMode = FilterMode.Point
        };

        var colors = new Color32[width * height];
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                Color32 color = new Color32(0, 0, 0, 255);
                if (x < mapWidth && y < mapHeight)
                {
                    int paletteIndex = GetPaletteIndexXY(x, y, mapWidth, mapHeight, rle);
                    uint intColor = palette[Mathf.Clamp(paletteIndex, 0, palette.Length - 1)];
                    color = new Color32(
                        (byte)(intColor & 0xffu),
                        (byte)((intColor >> 8) & 0xffu),
                        (byte)((intColor >> 16) & 0xffu),
                        255);
                }
                colors[y * width + x] = color;
            }
        }

        texture.SetPixels32(colors);
        texture.Apply(false, true);
        return texture;
    }

    private static uint[] ParseUintArray(string body)
    {
        var parts = body.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
        var values = new uint[parts.Length];
        for (int i = 0; i < parts.Length; i++)
        {
            var token = parts[i].Trim();
            if (token.StartsWith("0x", StringComparison.OrdinalIgnoreCase))
            {
                values[i] = uint.Parse(token.Substring(2), NumberStyles.HexNumber, CultureInfo.InvariantCulture);
            }
            else
            {
                values[i] = uint.Parse(token, CultureInfo.InvariantCulture);
            }
        }
        return values;
    }

    private static int GetPaletteIndexXY(int x, int y, int width, int height, uint[] rle)
    {
        if (x < 0 || y < 0 || x >= width || y >= height)
        {
            return 0;
        }

        int byteIndex = y * (width >> 3) + (x >> 3);
        uint uncomprByte = GetUncompressedByte(byteIndex, rle);
        int bitIndex = x & 0x07;
        return (int)((uncomprByte >> bitIndex) & 1u);
    }

    private static uint GetUncompressedByte(int byteIndex, uint[] rle)
    {
        int rleIndex = 0;
        int currentByteIndex = 0;
        int rleLenBytes = rle.Length << 2;
        while (rleIndex < rleLenBytes)
        {
            uint curRleByte = GetRleByte(rleIndex, rle);
            bool isSequence = (curRleByte & 0x80u) == 0u;
            int count = (int)(curRleByte & 0x7fu) + 1;
            if (byteIndex >= currentByteIndex && byteIndex < currentByteIndex + count)
            {
                return isSequence ? GetRleByte(rleIndex + 1 + (byteIndex - currentByteIndex), rle) : GetRleByte(rleIndex + 1, rle);
            }

            if (isSequence)
            {
                rleIndex += count + 1;
                currentByteIndex += count;
            }
            else
            {
                rleIndex += 2;
                currentByteIndex += count;
            }
        }
        return 0u;
    }

    private static uint GetRleByte(int byteIndex, uint[] rle)
    {
        uint longVal = rle[byteIndex >> 2];
        return (longVal >> ((byteIndex & 0x03) << 3)) & 0xffu;
    }

    private void ReleaseResources()
    {
        ReleaseRt(ref prevB);
        ReleaseRt(ref currB);
        ReleaseRt(ref prevC);
        ReleaseRt(ref currC);
        ReleaseMaterial(ref bufferBMaterial);
        ReleaseMaterial(ref bufferCMaterial);
        if (landTexture != null)
        {
            DestroyImmediate(landTexture);
            landTexture = null;
        }
    }

    private static void ReleaseRt(ref RenderTexture rt)
    {
        if (rt == null) return;
        rt.Release();
        DestroyImmediate(rt);
        rt = null;
    }

    private static void ReleaseMaterial(ref Material material)
    {
        if (material == null) return;
        DestroyImmediate(material);
        material = null;
    }

    private static void Swap(ref RenderTexture a, ref RenderTexture b)
    {
        var temp = a;
        a = b;
        b = temp;
    }
}
