using System.IO;
using System.Text.RegularExpressions;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoyWdXXR8_v16Bootstrap : MonoBehaviour
{
    [SerializeField] private Shader bufferAShader;
    [SerializeField] private Shader imageShader;
    [SerializeField] private int targetWidth = 512;
    [SerializeField] private int targetHeight = 288;
    [SerializeField] private bool flipY = true;

    private const string ResolutionPath = "unity-shadertoy-validation/shadertoy-16/shadertoy-16-capture.resolution.json";
    private const string VolumePath = "Assets/unity-shadertoy-validation/shadertoy-16/Audio/27012b4eadd0c3ce12498b867058e4f717ce79e10a99568cca461682d84a4b04.bin";
    private const string QuadName = "ST_WdXXR8_Quad";

    private Camera runtimeCamera;
    private Transform runtimeQuadTransform;
    private Material bufferAMaterial;
    private Material imageMaterial;
    private RenderTexture bufferART;
    private Texture3D volumeTexture;
    private bool volumeLoadAttempted;

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (bufferAShader == null) bufferAShader = Shader.Find("Shadertoy/WdXXR8_BufferA");
        if (imageShader == null) imageShader = Shader.Find("Shadertoy/WdXXR8_VanGoghRaytracer");
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
        if (volumeTexture == null && !volumeLoadAttempted) volumeTexture = LoadVolumeTexture();

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
                name = "ST_WdXXR8_BufferA_RT"
            };
            bufferART.Create();
        }
    }

    private Texture3D LoadVolumeTexture()
    {
        volumeLoadAttempted = true;
        var rel = VolumePath;
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
        const int voxels = size * size * size;
        const int expectedR = voxels;          // single channel
        const int expectedRGBA = voxels * 4;   // rgba
        int offset = 0;
        int channels = 0;
        if (bytes.Length == expectedR + 20) { offset = 20; channels = 1; }
        else if (bytes.Length == expectedR) { offset = 0; channels = 1; }
        else if (bytes.Length == expectedRGBA + 20) { offset = 20; channels = 4; }
        else if (bytes.Length == expectedRGBA) { offset = 0; channels = 4; }

        if (channels == 0)
        {
            Debug.LogWarning($"[Shadertoy] Volume size mismatch: {bytes.Length}, expected {expectedR}/{expectedRGBA} (+optional 20-byte header)");
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
                    int sx = x;
                    int sy = flipY ? (size - 1 - y) : y;
                    int sz = z;
                    int si = ((sz * w + sy) * w + sx);
                    int bi = offset + si * channels;
                    int di = ((z * w + y) * w + x);
                    if (channels == 1)
                    {
                        byte v = bytes[bi];
                        colors[di] = new Color32(v, v, v, 255);
                    }
                    else
                    {
                        colors[di] = new Color32(bytes[bi + 0], bytes[bi + 1], bytes[bi + 2], bytes[bi + 3]);
                    }
                }
            }
        }

        var tex = new Texture3D(size, size, size, GraphicsFormat.R8G8B8A8_UNorm, TextureCreationFlags.MipChain)
        {
            name = "ST_WdXXR8_VolumeTex3D",
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
        bufferAMaterial.SetVector("_STResolution", new Vector4(targetWidth, targetHeight, 1f / targetWidth, 1f / targetHeight));
        bufferAMaterial.SetFloat("_STTime", Time.time);
        Graphics.Blit(null, bufferART, bufferAMaterial, 0);
    }

    private void UpdateImageMaterial()
    {
        if (imageMaterial == null || bufferART == null) return;
        imageMaterial.SetTexture("_Channel0", bufferART);
        imageMaterial.SetVector("_STResolution", new Vector4(targetWidth, targetHeight, 1f / targetWidth, 1f / targetHeight));
        imageMaterial.SetFloat("_STTime", Time.time);
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
