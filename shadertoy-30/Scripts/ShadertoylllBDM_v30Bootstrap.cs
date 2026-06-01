using System.IO;
using System.Text.RegularExpressions;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoylllBDM_v30Bootstrap : MonoBehaviour
{
    private enum DebugView
    {
        Final = 0,
        BufferA = 1,
        BufferB = 2
    }

    [SerializeField] private Shader bufferAShader;
    [SerializeField] private Shader bufferBShader;
    [SerializeField] private Shader imageShader;
    [SerializeField] private int targetWidth = 840;
    [SerializeField] private int targetHeight = 473;
    [SerializeField] private DebugView debugView = DebugView.Final;

    private const string ResolutionPath = "unity-shadertoy-validation/shadertoy-30/shadertoy-30-capture.resolution.json";
    private const string QuadName = "ST_lllBDM_Quad";

    private Camera runtimeCamera;
    private Transform runtimeQuadTransform;
    private Material matA;
    private Material matB;
    private Material matImage;
    private RenderTexture rtA;
    private RenderTexture rtB;
    private MeshRenderer quadRenderer;

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (bufferAShader == null) bufferAShader = Shader.Find("Shadertoy/lllBDM_BufferA");
        if (bufferBShader == null) bufferBShader = Shader.Find("Shadertoy/lllBDM_BufferB");
        if (imageShader == null) imageShader = Shader.Find("Shadertoy/lllBDM_Goo");
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
        if (matImage != null) DestroyImmediate(matImage);
        if (rtA != null) rtA.Release();
        if (rtB != null) rtB.Release();
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
        if (bufferAShader == null) bufferAShader = Shader.Find("Shadertoy/lllBDM_BufferA");
        if (bufferBShader == null) bufferBShader = Shader.Find("Shadertoy/lllBDM_BufferB");
        if (imageShader == null) imageShader = Shader.Find("Shadertoy/lllBDM_Goo");

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
            quadRenderer = quad.GetComponent<MeshRenderer>();
        }
        else if (quadRenderer == null)
        {
            quadRenderer = runtimeQuadTransform.GetComponent<MeshRenderer>();
        }

        if (matA == null && bufferAShader != null) matA = new Material(bufferAShader);
        if (matB == null && bufferBShader != null) matB = new Material(bufferBShader);
        if (matImage == null && imageShader != null) matImage = new Material(imageShader);

        if (runtimeQuadTransform != null && matImage != null && quadRenderer != null)
        {
            quadRenderer.sharedMaterial = matImage;
        }
    }

    private void EnsureRenderTargets()
    {
        EnsureRT(ref rtA, "ST_lllBDM_A", RenderTextureFormat.ARGBHalf);
        EnsureRT(ref rtB, "ST_lllBDM_B", RenderTextureFormat.ARGBHalf);
    }

    private void EnsureRT(ref RenderTexture rt, string name, RenderTextureFormat format)
    {
        if (targetWidth <= 0 || targetHeight <= 0) return;
        if (rt != null && (rt.width != targetWidth || rt.height != targetHeight || rt.format != format))
        {
            rt.Release();
            rt = null;
        }
        if (rt == null)
        {
            rt = new RenderTexture(targetWidth, targetHeight, 0, format)
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
            matB.SetVector("_STResolution", res);
            matB.SetTexture("_Channel0", rtA);
            Graphics.Blit(null, rtB, matB, 0);
        }

        if (matImage != null && rtB != null)
        {
            matImage.SetVector("_STResolution", res);
            matImage.SetFloat("_STTime", t);
            matImage.SetTexture("_Channel0", rtB);
        }

        if (quadRenderer == null) return;
        switch (debugView)
        {
            case DebugView.BufferA:
                if (matA != null)
                {
                    matA.SetVector("_STResolution", res);
                    matA.SetFloat("_STTime", t);
                    quadRenderer.sharedMaterial = matA;
                }
                break;
            case DebugView.BufferB:
                if (matB != null)
                {
                    matB.SetVector("_STResolution", res);
                    matB.SetTexture("_Channel0", rtA);
                    quadRenderer.sharedMaterial = matB;
                }
                break;
            default:
                if (matImage != null) quadRenderer.sharedMaterial = matImage;
                break;
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
