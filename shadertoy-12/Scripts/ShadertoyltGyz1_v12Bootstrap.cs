using System.IO;
using System.Text.RegularExpressions;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoyltGyz1_v12Bootstrap : MonoBehaviour
{
    [SerializeField] private Shader bufferAShader;
    [SerializeField] private Shader imageShader;
    [SerializeField] private Texture2D channel1Fallback;
    [SerializeField] private bool flipY = true;
    [SerializeField] private bool swapRB = false;
    [SerializeField] private bool preferGpuDumpedRaw = false;
    [SerializeField] private int targetWidth = 512;
    [SerializeField] private int targetHeight = 288;

    private const string ResolutionPath = "unity-shadertoy-validation/shadertoy-12/shadertoy-12-capture.resolution.json";
    private const string VolumePath = "Assets/unity-shadertoy-validation/shadertoy-12/Audio/aea6b99da1d53055107966b59ac5444fc8bc7b3ce2d0bbb6a4a3cbae1d97f3aa.bin";
    private const string VolumeGpuRawPath = "Assets/unity-shadertoy-validation/shadertoy-12/Audio/ltGyz1_volume_from_gpu_rgba32.raw";
    private const string BufferFallbackPath = "Assets/unity-shadertoy-validation/shadertoy-12/Textures/buffer00.png";
    private const string QuadName = "ST_ltGyz1_Quad";

    private Camera runtimeCamera;
    private Transform runtimeQuadTransform;
    private Material bufferAMaterial;
    private Material imageMaterial;
    private RenderTexture bufferART;
    private Texture3D volumeTexture;

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (bufferAShader == null) bufferAShader = Shader.Find("Shadertoy/ltGyz1_BufferA");
        if (imageShader == null) imageShader = Shader.Find("Shadertoy/ltGyz1_Image");
        if (channel1Fallback == null)
        {
            channel1Fallback = AssetDatabase.LoadAssetAtPath<Texture2D>(BufferFallbackPath);
        }
    }
#endif

    private void OnEnable()
    {
        TryLoadResolution();
        EnsureSceneSetup();
    }

    private void Update()
    {
        EnsureSceneSetup();
        EnsureRenderTarget();
        RenderBufferA();
        UpdateImageMaterial();
        FitQuadToCamera();
    }

    private void OnDisable()
    {
        if (bufferAMaterial != null) DestroyImmediate(bufferAMaterial);
        if (imageMaterial != null) DestroyImmediate(imageMaterial);
        if (bufferART != null) bufferART.Release();
        if (volumeTexture != null) DestroyImmediate(volumeTexture);
    }

    private void TryLoadResolution()
    {
        var fullPath = Path.Combine(Application.dataPath, ResolutionPath.Replace('/', Path.DirectorySeparatorChar));
        if (!File.Exists(fullPath)) return;
        var json = File.ReadAllText(fullPath);
        var m = Regex.Match(json, "\"unityResolution\"\\s*:\\s*\\{[^\\}]*\"width\"\\s*:\\s*(\\d+)\\s*,\\s*\"height\"\\s*:\\s*(\\d+)", RegexOptions.Singleline);
        if (!m.Success) return;
        targetWidth = int.Parse(m.Groups[1].Value);
        targetHeight = int.Parse(m.Groups[2].Value);
    }

    private void EnsureSceneSetup()
    {
        if (runtimeCamera == null)
        {
            runtimeCamera = GetComponent<Camera>();
            if (runtimeCamera == null) runtimeCamera = Camera.main;
            if (runtimeCamera != null)
            {
                runtimeCamera.orthographic = true;
                runtimeCamera.orthographicSize = 1f;
                runtimeCamera.transform.position = new Vector3(0f, 0f, -1f);
                runtimeCamera.transform.rotation = Quaternion.identity;
                runtimeCamera.clearFlags = CameraClearFlags.SolidColor;
                runtimeCamera.backgroundColor = Color.black;
            }
        }

        if (runtimeQuadTransform == null)
        {
            var quad = GameObject.Find(QuadName);
            if (quad == null)
            {
                quad = GameObject.CreatePrimitive(PrimitiveType.Quad);
                quad.name = QuadName;
                var col = quad.GetComponent<Collider>();
                if (col != null) Destroy(col);
            }
            runtimeQuadTransform = quad.transform;
        }

        if (bufferAMaterial == null && bufferAShader != null) bufferAMaterial = new Material(bufferAShader);
        if (imageMaterial == null && imageShader != null) imageMaterial = new Material(imageShader);
        if (volumeTexture == null) volumeTexture = LoadVolumeTexture();

        if (runtimeQuadTransform != null && imageMaterial != null)
        {
            var renderer = runtimeQuadTransform.GetComponent<MeshRenderer>();
            if (renderer != null) renderer.sharedMaterial = imageMaterial;
        }
    }

    private void EnsureRenderTarget()
    {
        if (targetWidth <= 0 || targetHeight <= 0) return;
        if (bufferART != null && (bufferART.width != targetWidth || bufferART.height != targetHeight))
        {
            bufferART.Release();
            bufferART = null;
        }
        if (bufferART == null)
        {
            bufferART = new RenderTexture(targetWidth, targetHeight, 0, RenderTextureFormat.ARGBHalf)
            {
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp,
                name = "ST_ltGyz1_BufferA_RT"
            };
            bufferART.Create();
        }
    }

    private Texture3D LoadVolumeTexture()
    {
        var rel = preferGpuDumpedRaw ? VolumeGpuRawPath : VolumePath;
        if (!File.Exists(Path.Combine(Application.dataPath, rel.Replace("Assets/", "").Replace('/', Path.DirectorySeparatorChar))))
        {
            rel = VolumePath;
        }
        if (rel.StartsWith("Assets/")) rel = rel.Substring("Assets/".Length);
        if (rel.StartsWith("Assets\\")) rel = rel.Substring("Assets\\".Length);
        var fullPath = Path.Combine(Application.dataPath, rel.Replace('/', Path.DirectorySeparatorChar));
        if (!File.Exists(fullPath))
        {
            Debug.LogWarning($"[Shadertoy] Volume asset missing: {fullPath}");
            return null;
        }

        var bytes = File.ReadAllBytes(fullPath);
        const int size = 32;
        const int expected = size * size * size * 4;
        int offset = 0;
        if (bytes.Length == expected + 20)
        {
            // Shadertoy volume .bin commonly carries a 20-byte header.
            offset = 20;
        }
        else if (bytes.Length == expected)
        {
            offset = 0;
        }

        if (bytes.Length < expected + offset)
        {
            Debug.LogWarning($"[Shadertoy] Volume size mismatch: {bytes.Length}, expected at least {expected + offset}");
            return null;
        }

        var colors = new Color32[size * size * size];
        int w = size;
        for (int z = 0; z < size; z++)
        {
            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    // GPU-dumped raw already matches runtime upload orientation; for .bin path keep legacy Y flip.
                    int sx = x;
                    int sy = (offset == 0) ? y : (flipY ? (size - 1 - y) : y);
                    int sz = z;
                    int si = ((sz * w + sy) * w + sx);
                    int bi = offset + si * 4;

                    byte r = bytes[bi + 0];
                    byte g = bytes[bi + 1];
                    byte b = bytes[bi + 2];
                    byte c0 = swapRB ? b : r;
                    byte c1 = g;
                    byte c2 = swapRB ? r : b;
                    byte c3 = bytes[bi + 3];

                    int di = ((z * w + y) * w + x);
                    colors[di] = new Color32(c0, c1, c2, c3);
                }
            }
        }

        var tex = new Texture3D(size, size, size, GraphicsFormat.R8G8B8A8_UNorm, TextureCreationFlags.MipChain)
        {
            name = "ST_ltGyz1_VolumeTex3D",
            wrapMode = TextureWrapMode.Repeat,
            filterMode = FilterMode.Trilinear
        };
        tex.SetPixels32(colors);
        tex.Apply(true, false);
        return tex;
    }

    private void RenderBufferA()
    {
        if (bufferART == null || bufferAMaterial == null) return;
        if (volumeTexture != null) bufferAMaterial.SetTexture("_Channel0", volumeTexture);
        if (channel1Fallback != null) bufferAMaterial.SetTexture("_Channel1", channel1Fallback);
        bufferAMaterial.SetVector("_STResolution", new Vector4(targetWidth, targetHeight, 1f / targetWidth, 1f / targetHeight));
        bufferAMaterial.SetFloat("_STTime", Time.time);
        var mouse = Input.mousePosition;
        bufferAMaterial.SetVector("_STMouse", new Vector4(mouse.x, mouse.y, 0f, 0f));
        Graphics.Blit(null, bufferART, bufferAMaterial, 0);
    }

    private void UpdateImageMaterial()
    {
        if (imageMaterial == null || bufferART == null) return;
        imageMaterial.SetTexture("_Channel0", bufferART);
        imageMaterial.SetVector("_STResolution", new Vector4(targetWidth, targetHeight, 1f / targetWidth, 1f / targetHeight));
    }

    private void FitQuadToCamera()
    {
        if (runtimeCamera == null || runtimeQuadTransform == null) return;
        var h = runtimeCamera.orthographicSize * 2f;
        var w = h * runtimeCamera.aspect;
        runtimeQuadTransform.position = Vector3.zero;
        runtimeQuadTransform.rotation = Quaternion.identity;
        runtimeQuadTransform.localScale = new Vector3(w, h, 1f);
    }
}
