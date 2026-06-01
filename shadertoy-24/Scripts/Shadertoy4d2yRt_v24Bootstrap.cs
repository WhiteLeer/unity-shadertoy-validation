using System.IO;
using System.Text.RegularExpressions;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class Shadertoy4d2yRt_v24Bootstrap : MonoBehaviour
{
    [SerializeField] private Shader bufferAShader;
    [SerializeField] private Shader bufferBShader;
    [SerializeField] private Shader bufferCShader;
    [SerializeField] private Shader imageShader;
    [SerializeField] private int targetWidth = 1024;
    [SerializeField] private int targetHeight = 576;

    private const string ResolutionPath = "unity-shadertoy-validation/shadertoy-24/shadertoy-24-capture.resolution.json";
    private const string QuadName = "ST_4d2yRt_Quad";

    private Camera runtimeCamera;
    private Transform runtimeQuadTransform;
    private Material matA;
    private Material matB;
    private Material matC;
    private Material matImage;
    private RenderTexture rtA;
    private RenderTexture rtB;
    private RenderTexture rtC;

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (bufferAShader == null) bufferAShader = Shader.Find("Shadertoy/4d2yRt_BufferA");
        if (bufferBShader == null) bufferBShader = Shader.Find("Shadertoy/4d2yRt_BufferB");
        if (bufferCShader == null) bufferCShader = Shader.Find("Shadertoy/4d2yRt_BufferC");
        if (imageShader == null) imageShader = Shader.Find("Shadertoy/4d2yRt_SynTech001");
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
        EnsureRenderTargets();
        RenderChain();
        FitQuadToCamera();
    }

    private void OnDisable()
    {
        if (matA != null) DestroyImmediate(matA);
        if (matB != null) DestroyImmediate(matB);
        if (matC != null) DestroyImmediate(matC);
        if (matImage != null) DestroyImmediate(matImage);
        if (rtA != null) rtA.Release();
        if (rtB != null) rtB.Release();
        if (rtC != null) rtC.Release();
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

        if (matA == null && bufferAShader != null) matA = new Material(bufferAShader);
        if (matB == null && bufferBShader != null) matB = new Material(bufferBShader);
        if (matC == null && bufferCShader != null) matC = new Material(bufferCShader);
        if (matImage == null && imageShader != null) matImage = new Material(imageShader);

        if (runtimeQuadTransform != null && matImage != null)
        {
            var renderer = runtimeQuadTransform.GetComponent<MeshRenderer>();
            if (renderer != null) renderer.sharedMaterial = matImage;
        }
    }

    private void EnsureRenderTargets()
    {
        EnsureRT(ref rtA, "ST_4d2yRt_A");
        EnsureRT(ref rtB, "ST_4d2yRt_B");
        EnsureRT(ref rtC, "ST_4d2yRt_C");
    }

    private void EnsureRT(ref RenderTexture rt, string name)
    {
        if (targetWidth <= 0 || targetHeight <= 0) return;
        if (rt != null && (rt.width != targetWidth || rt.height != targetHeight))
        {
            rt.Release();
            rt = null;
        }
        if (rt == null)
        {
            rt = new RenderTexture(targetWidth, targetHeight, 0, RenderTextureFormat.ARGBHalf)
            {
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp,
                name = name
            };
            rt.Create();
        }
    }

    private void RenderChain()
    {
        var res = new Vector4(targetWidth, targetHeight, 1f / Mathf.Max(1, targetWidth), 1f / Mathf.Max(1, targetHeight));
        float t = Time.time;

        if (matA != null && rtA != null)
        {
            matA.SetVector("_STResolution", res);
            matA.SetFloat("_STTime", t);
            Graphics.Blit(null, rtA, matA, 0);
        }

        if (matB != null && rtA != null && rtB != null)
        {
            matB.SetTexture("_Channel0", rtA);
            matB.SetVector("_STResolution", res);
            Graphics.Blit(null, rtB, matB, 0);
        }

        if (matC != null && rtB != null && rtC != null)
        {
            matC.SetTexture("_Channel0", rtB);
            matC.SetVector("_STResolution", res);
            Graphics.Blit(null, rtC, matC, 0);
        }

        if (matImage != null)
        {
            if (rtA != null) matImage.SetTexture("_Channel0", rtA);
            if (rtC != null) matImage.SetTexture("_Channel1", rtC);
            matImage.SetVector("_STResolution", res);
            matImage.SetFloat("_STTime", t);
        }
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
