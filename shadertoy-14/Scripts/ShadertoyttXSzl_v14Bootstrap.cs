using System.IO;
using System.Text.RegularExpressions;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoyttXSzl_v14Bootstrap : MonoBehaviour
{
    [SerializeField] private Shader bufferAShader;
    [SerializeField] private Shader imageShader;
    [SerializeField] private int targetWidth = 512;
    [SerializeField] private int targetHeight = 288;

    private const string ResolutionPath = "unity-shadertoy-validation/shadertoy-14/shadertoy-14-capture.resolution.json";
    private const string QuadName = "ST_ttXSzl_Quad";

    private Camera runtimeCamera;
    private Transform runtimeQuadTransform;
    private Material bufferAMaterial;
    private Material imageMaterial;
    private RenderTexture bufferART;

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (bufferAShader == null) bufferAShader = Shader.Find("Shadertoy/ttXSzl_BufferA");
        if (imageShader == null) imageShader = Shader.Find("Shadertoy/ttXSzl_Image");
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
            bufferART = new RenderTexture(targetWidth, targetHeight, 0, RenderTextureFormat.ARGBFloat)
            {
                filterMode = FilterMode.Point,
                wrapMode = TextureWrapMode.Clamp,
                name = "ST_ttXSzl_BufferA_RT"
            };
            bufferART.Create();
        }
    }

    private void RenderBufferA()
    {
        if (bufferART == null || bufferAMaterial == null) return;
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
