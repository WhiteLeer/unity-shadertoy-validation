using System.IO;
using System.Text.RegularExpressions;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoyNdS3zK_v31Bootstrap : MonoBehaviour
{
    private enum DebugView { Final = 0, BufferA = 1, BufferB = 2 }

    [SerializeField] private Shader bufferAShader;
    [SerializeField] private Shader bufferBShader;
    [SerializeField] private Shader imageShader;
    [SerializeField] private Cubemap environmentCubemap;
    [SerializeField] private int targetWidth = 420;
    [SerializeField] private int targetHeight = 236;
    [SerializeField] private DebugView debugView = DebugView.Final;

    private const string ResolutionPath = "unity-shadertoy-validation/shadertoy-31/shadertoy-31-capture.resolution.json";
    private const string QuadName = "ST_NdS3zK_Quad";

    private Camera runtimeCamera;
    private Transform runtimeQuadTransform;
    private MeshRenderer quadRenderer;

    private Material matA;
    private Material matB;
    private Material matImage;

    private RenderTexture[] rtA = new RenderTexture[2];
    private RenderTexture[] rtB = new RenderTexture[2];
    private int frameIndex;

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (bufferAShader == null) bufferAShader = Shader.Find("Shadertoy/NdS3zK_BufferA");
        if (bufferBShader == null) bufferBShader = Shader.Find("Shadertoy/NdS3zK_BufferB");
        if (imageShader == null) imageShader = Shader.Find("Shadertoy/NdS3zK_OceanElemental");
        TryLoadEnvironmentCubemap();
    }
#endif

    private void OnEnable()
    {
        frameIndex = 0;
        TryLoadResolution();
        EnsureSceneSetup();
    }

    private void Update()
    {
        EnsureSceneSetup();
        EnsureRenderTargets();
        RenderChain();
        FitQuadToCamera();
        frameIndex++;
    }

    private void OnDisable()
    {
        if (matA != null) DestroyImmediate(matA);
        if (matB != null) DestroyImmediate(matB);
        if (matImage != null) DestroyImmediate(matImage);
        for (int i = 0; i < 2; i++)
        {
            if (rtA[i] != null) rtA[i].Release();
            if (rtB[i] != null) rtB[i].Release();
        }
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
        if (bufferAShader == null) bufferAShader = Shader.Find("Shadertoy/NdS3zK_BufferA");
        if (bufferBShader == null) bufferBShader = Shader.Find("Shadertoy/NdS3zK_BufferB");
        if (imageShader == null) imageShader = Shader.Find("Shadertoy/NdS3zK_OceanElemental");
#if UNITY_EDITOR
        TryLoadEnvironmentCubemap();
#endif

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

        if (quadRenderer != null && matImage != null)
        {
            quadRenderer.sharedMaterial = matImage;
        }
    }

    private void EnsureRenderTargets()
    {
        EnsureRT(rtA, "ST_NdS3zK_A", RenderTextureFormat.ARGBHalf, FilterMode.Point, TextureWrapMode.Clamp);
        EnsureRT(rtB, "ST_NdS3zK_B", RenderTextureFormat.ARGBHalf, FilterMode.Bilinear, TextureWrapMode.Repeat);
    }

    private void EnsureRT(RenderTexture[] arr, string namePrefix, RenderTextureFormat format, FilterMode filterMode, TextureWrapMode wrapMode)
    {
        for (int i = 0; i < 2; i++)
        {
            var rt = arr[i];
            if (rt != null && (rt.width != targetWidth || rt.height != targetHeight || rt.format != format))
            {
                rt.Release();
                arr[i] = null;
                rt = null;
            }
            if (rt == null)
            {
                rt = new RenderTexture(targetWidth, targetHeight, 0, format)
                {
                    filterMode = filterMode,
                    wrapMode = wrapMode,
                    name = namePrefix + i
                };
                rt.Create();
                arr[i] = rt;
            }
        }
    }

    private void SetCommon(Material m, Vector4 res)
    {
        if (m == null) return;
        m.SetVector("_STResolution", res);
        m.SetFloat("_STTime", Time.time);
        m.SetFloat("_STFrame", frameIndex);
        var mp = Input.mousePosition;
        var md = Input.GetMouseButton(0) ? 1f : 0f;
        m.SetVector("_STMouse", new Vector4(mp.x, mp.y, md, md));
    }

    private void RenderChain()
    {
        int src = frameIndex & 1;
        int dst = 1 - src;
        var res = new Vector4(targetWidth, targetHeight, 1f / Mathf.Max(1, targetWidth), 1f / Mathf.Max(1, targetHeight));

        if (matA != null)
        {
            SetCommon(matA, res);
            matA.SetTexture("_Channel0", rtA[src]);
            Graphics.Blit(null, rtA[dst], matA, 0);
        }

        if (matB != null)
        {
            SetCommon(matB, res);
            matB.SetTexture("_Channel0", rtA[dst]);
            matB.SetTexture("_Channel1", rtB[src]);
            Graphics.Blit(null, rtB[dst], matB, 0);
        }

        if (matImage != null)
        {
            SetCommon(matImage, res);
            matImage.SetTexture("_Channel0", rtA[dst]);
            matImage.SetTexture("_Channel1", rtB[dst]);
            if (environmentCubemap != null) matImage.SetTexture("_Channel2", environmentCubemap);
        }

        if (quadRenderer == null) return;
        switch (debugView)
        {
            case DebugView.BufferA: quadRenderer.sharedMaterial = matA; break;
            case DebugView.BufferB: quadRenderer.sharedMaterial = matB; break;
            default: quadRenderer.sharedMaterial = matImage; break;
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

#if UNITY_EDITOR
    private void TryLoadEnvironmentCubemap()
    {
        if (environmentCubemap != null) return;
        environmentCubemap = AssetDatabase.LoadAssetAtPath<Cubemap>("Assets/unity-shadertoy-validation/shadertoy-31/Textures/585f9546c092f53ded45332b343144396c0b2d70d9965f585ebc172080d8aa58.jpg");
    }
#endif
}
