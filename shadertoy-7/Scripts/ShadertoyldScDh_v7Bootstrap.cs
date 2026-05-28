using System.IO;
using System.Text.RegularExpressions;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoyldScDh_v7Bootstrap : MonoBehaviour
{
    [SerializeField] private Shader bufferAShader;
    [SerializeField] private Shader imageShader;

    [SerializeField] private Texture2D channel0Texture;
    [SerializeField] private Texture2D channel1Texture;
    [SerializeField] private Texture2D channel2Texture;
    [SerializeField] private Texture2D channel3Texture;

    [SerializeField] private int targetWidth = 512;
    [SerializeField] private int targetHeight = 288;

    private const string ResolutionPath = "unity-shadertoy-validation/shadertoy-7/shadertoy-7-capture.resolution.json";
    private const string QuadName = "ST_ldScDh_Quad";

    private Camera runtimeCamera;
    private Transform runtimeQuadTransform;
    private RenderTexture bufferART;
    private Material bufferAMaterial;
    private Material imageMaterial;

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (bufferAShader == null) bufferAShader = Shader.Find("Shadertoy/ldScDh_BufferA");
        if (imageShader == null) imageShader = Shader.Find("Shadertoy/ldScDh_GreekTemple");

        if (channel0Texture == null)
            channel0Texture = AssetDatabase.LoadAssetAtPath<Texture2D>(
                "Assets/unity-shadertoy-validation/shadertoy-7/Textures/79520a3d3a0f4d3caa440802ef4362e99d54e12b1392973e4ea321840970a88a.jpg");
        if (channel1Texture == null)
            channel1Texture = AssetDatabase.LoadAssetAtPath<Texture2D>(
                "Assets/unity-shadertoy-validation/shadertoy-7/Textures/f735bee5b64ef98879dc618b016ecf7939a5756040c2cde21ccb15e69a6e1cfb.png");
        if (channel2Texture == null)
            channel2Texture = AssetDatabase.LoadAssetAtPath<Texture2D>(
                "Assets/unity-shadertoy-validation/shadertoy-7/Textures/52d2a8f514c4fd2d9866587f4d7b2a5bfa1a11a0e772077d7682deb8b3b517e5.jpg");
        if (channel3Texture == null)
            channel3Texture = AssetDatabase.LoadAssetAtPath<Texture2D>(
                "Assets/unity-shadertoy-validation/shadertoy-7/Textures/buffer00.png");

        // Align Unity import settings with captured Shadertoy sampler hints.
        ApplyImportSettings("Assets/unity-shadertoy-validation/shadertoy-7/Textures/79520a3d3a0f4d3caa440802ef4362e99d54e12b1392973e4ea321840970a88a.jpg", true, TextureWrapMode.Repeat, FilterMode.Trilinear);
        ApplyImportSettings("Assets/unity-shadertoy-validation/shadertoy-7/Textures/f735bee5b64ef98879dc618b016ecf7939a5756040c2cde21ccb15e69a6e1cfb.png", false, TextureWrapMode.Repeat, FilterMode.Bilinear);
        ApplyImportSettings("Assets/unity-shadertoy-validation/shadertoy-7/Textures/52d2a8f514c4fd2d9866587f4d7b2a5bfa1a11a0e772077d7682deb8b3b517e5.jpg", true, TextureWrapMode.Repeat, FilterMode.Trilinear);
        ApplyImportSettings("Assets/unity-shadertoy-validation/shadertoy-7/Textures/buffer00.png", false, TextureWrapMode.Clamp, FilterMode.Bilinear);
    }

    private static void ApplyImportSettings(string assetPath, bool useMipMap, TextureWrapMode wrapMode, FilterMode filterMode)
    {
        var importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
        if (importer == null)
        {
            return;
        }

        var changed = false;
        if (importer.sRGBTexture)
        {
            importer.sRGBTexture = false;
            changed = true;
        }
        if (importer.mipmapEnabled != useMipMap)
        {
            importer.mipmapEnabled = useMipMap;
            changed = true;
        }
        if (importer.wrapMode != wrapMode)
        {
            importer.wrapMode = wrapMode;
            changed = true;
        }
        if (importer.filterMode != filterMode)
        {
            importer.filterMode = filterMode;
            changed = true;
        }

        if (changed)
        {
            importer.SaveAndReimport();
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
        if (!Application.isPlaying)
        {
            FitQuadToCamera();
            return;
        }

        EnsureRenderTargets();
        RenderBufferA();
        UpdateImageMaterial();
        FitQuadToCamera();
    }

    private void OnDisable()
    {
        if (bufferAMaterial != null) DestroyImmediate(bufferAMaterial);
        if (imageMaterial != null) DestroyImmediate(imageMaterial);
        if (bufferART != null) bufferART.Release();
    }

    private void TryLoadResolution()
    {
        var fullPath = Path.Combine(Application.dataPath, ResolutionPath.Replace('/', Path.DirectorySeparatorChar));
        if (!File.Exists(fullPath)) return;

        var json = File.ReadAllText(fullPath);
        var m = Regex.Match(
            json,
            "\"unityResolution\"\\s*:\\s*\\{[^\\}]*\"width\"\\s*:\\s*(\\d+)\\s*,\\s*\"height\"\\s*:\\s*(\\d+)",
            RegexOptions.Singleline
        );
        if (!m.Success) return;

        targetWidth = int.Parse(m.Groups[1].Value);
        targetHeight = int.Parse(m.Groups[2].Value);
    }

    private void EnsureSceneSetup()
    {
        runtimeCamera = GetComponent<Camera>();
        if (runtimeCamera == null) runtimeCamera = Camera.main;
        if (runtimeCamera == null) return;

        runtimeCamera.orthographic = true;
        runtimeCamera.orthographicSize = 1f;
        runtimeCamera.transform.position = new Vector3(0f, 0f, -1f);
        runtimeCamera.transform.rotation = Quaternion.identity;
        runtimeCamera.clearFlags = CameraClearFlags.SolidColor;
        runtimeCamera.backgroundColor = Color.black;

        var quad = GameObject.Find(QuadName);
        if (quad == null)
        {
            quad = GameObject.CreatePrimitive(PrimitiveType.Quad);
            quad.name = QuadName;
            var col = quad.GetComponent<Collider>();
            if (col != null) Destroy(col);
        }
        runtimeQuadTransform = quad.transform;
        runtimeQuadTransform.position = Vector3.zero;
        runtimeQuadTransform.rotation = Quaternion.identity;

        EnsureRenderTargets();
        if (bufferAShader != null && bufferAMaterial == null) bufferAMaterial = new Material(bufferAShader);
        if (imageShader != null && imageMaterial == null) imageMaterial = new Material(imageShader);

        var renderer = quad.GetComponent<MeshRenderer>();
        if (renderer != null && imageMaterial != null)
        {
            renderer.sharedMaterial = imageMaterial;
        }
    }

    private void EnsureRenderTargets()
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
                wrapMode = TextureWrapMode.Clamp,
                filterMode = FilterMode.Bilinear,
                name = "ST_ldScDh_BufferA_RT"
            };
            bufferART.Create();
        }
    }

    private void RenderBufferA()
    {
        if (bufferAMaterial == null || bufferART == null) return;

        bufferAMaterial.SetVector("_STResolution", new Vector4(targetWidth, targetHeight, 1f / targetWidth, 1f / targetHeight));
        bufferAMaterial.SetFloat("_STTime", Time.time);
        if (channel0Texture != null) bufferAMaterial.SetTexture("_Channel0", channel0Texture);
        if (channel1Texture != null) bufferAMaterial.SetTexture("_Channel1", channel1Texture);
        if (channel2Texture != null) bufferAMaterial.SetTexture("_Channel2", channel2Texture);
        if (channel3Texture != null) bufferAMaterial.SetTexture("_Channel3", channel3Texture);

        Graphics.Blit(null, bufferART, bufferAMaterial, 0);
    }

    private void UpdateImageMaterial()
    {
        if (imageMaterial == null) return;
        if (bufferART != null) imageMaterial.SetTexture("_Channel0", bufferART);
        if (channel1Texture != null) imageMaterial.SetTexture("_Channel1", channel1Texture);
        if (channel2Texture != null) imageMaterial.SetTexture("_Channel2", channel2Texture);
        if (channel3Texture != null) imageMaterial.SetTexture("_Channel3", channel3Texture);
    }

    private void FitQuadToCamera()
    {
        if (runtimeCamera == null || runtimeQuadTransform == null) return;
        var h = runtimeCamera.orthographicSize * 2f;
        var w = h * runtimeCamera.aspect;
        runtimeQuadTransform.localScale = new Vector3(w, h, 1f);
        runtimeQuadTransform.position = Vector3.zero;
        runtimeQuadTransform.rotation = Quaternion.identity;
    }
}
