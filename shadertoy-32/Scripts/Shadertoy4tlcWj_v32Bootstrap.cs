using System.IO;
using System.Text.RegularExpressions;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class Shadertoy4tlcWj_v32Bootstrap : MonoBehaviour
{
    private enum DebugView { Final = 0, BufferA = 1, BufferB = 2, BufferC = 3 }

    [SerializeField] private Shader bufferAShader;
    [SerializeField] private Shader bufferBShader;
    [SerializeField] private Shader bufferCShader;
    [SerializeField] private Shader imageShader;
    [SerializeField] private int targetWidth = 840;
    [SerializeField] private int targetHeight = 473;
    [SerializeField] private DebugView debugView = DebugView.Final;

    private const string ResolutionPath = "unity-shadertoy-validation/shadertoy-32/shadertoy-32-capture.resolution.json";
    private const string QuadName = "ST_4tlcWj_Quad";

    private Camera runtimeCamera;
    private Transform runtimeQuadTransform;
    private MeshRenderer quadRenderer;
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
        if (bufferAShader == null) bufferAShader = Shader.Find("Shadertoy/4tlcWj_BufferA");
        if (bufferBShader == null) bufferBShader = Shader.Find("Shadertoy/4tlcWj_BufferB");
        if (bufferCShader == null) bufferCShader = Shader.Find("Shadertoy/4tlcWj_BufferC");
        if (imageShader == null) imageShader = Shader.Find("Shadertoy/4tlcWj_SubsurfaceScattering");
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
        if (bufferAShader == null) bufferAShader = Shader.Find("Shadertoy/4tlcWj_BufferA");
        if (bufferBShader == null) bufferBShader = Shader.Find("Shadertoy/4tlcWj_BufferB");
        if (bufferCShader == null) bufferCShader = Shader.Find("Shadertoy/4tlcWj_BufferC");
        if (imageShader == null) imageShader = Shader.Find("Shadertoy/4tlcWj_SubsurfaceScattering");

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
        if (matC == null && bufferCShader != null) matC = new Material(bufferCShader);
        if (matImage == null && imageShader != null) matImage = new Material(imageShader);
    }

    private void EnsureRenderTargets()
    {
        EnsureRT(ref rtA, "ST_4tlcWj_A", RenderTextureFormat.ARGBFloat, FilterMode.Point);
        EnsureRT(ref rtB, "ST_4tlcWj_B", RenderTextureFormat.ARGBFloat, FilterMode.Point);
        EnsureRT(ref rtC, "ST_4tlcWj_C", RenderTextureFormat.ARGBHalf, FilterMode.Bilinear);
    }

    private void EnsureRT(ref RenderTexture rt, string name, RenderTextureFormat format, FilterMode filter)
    {
        if (rt != null && (rt.width != targetWidth || rt.height != targetHeight || rt.format != format))
        {
            rt.Release();
            rt = null;
        }
        if (rt == null)
        {
            rt = new RenderTexture(targetWidth, targetHeight, 0, format)
            {
                filterMode = filter,
                wrapMode = TextureWrapMode.Clamp,
                name = name
            };
            rt.Create();
        }
    }

    private void SetCommon(Material mat, Vector4 res)
    {
        if (mat == null) return;
        mat.SetVector("_STResolution", res);
        mat.SetFloat("_STTime", Time.time);
    }

    private void RenderChain()
    {
        var res = new Vector4(targetWidth, targetHeight, 1f / Mathf.Max(1, targetWidth), 1f / Mathf.Max(1, targetHeight));

        if (matA != null && rtA != null)
        {
            SetCommon(matA, res);
            Graphics.Blit(null, rtA, matA, 0);
        }

        if (matB != null && rtA != null && rtB != null)
        {
            SetCommon(matB, res);
            matB.SetTexture("_Channel0", rtA);
            Graphics.Blit(null, rtB, matB, 0);
        }

        if (matC != null && rtA != null && rtB != null && rtC != null)
        {
            SetCommon(matC, res);
            matC.SetTexture("_Channel0", rtB);
            matC.SetTexture("_Channel1", rtA);
            Graphics.Blit(null, rtC, matC, 0);
        }

        if (matImage != null)
        {
            SetCommon(matImage, res);
            matImage.SetTexture("_Channel0", rtC);
            matImage.SetTexture("_Channel1", rtA);
        }

        if (quadRenderer == null) return;
        quadRenderer.sharedMaterial = debugView == DebugView.BufferA ? matA :
            debugView == DebugView.BufferB ? matB :
            debugView == DebugView.BufferC ? matC : matImage;
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
