using System.IO;
using System.Text.RegularExpressions;
using UnityEngine;
using UnityEngine.Video;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class ShadertoyMtKcDG_v9Bootstrap : MonoBehaviour
{
    [SerializeField] private Shader bufferShader;
    [SerializeField] private Shader imageShader;

    [SerializeField] private Texture2D noiseTexture;
    [SerializeField] private Texture2D paperTexture;
    [SerializeField] private Texture2D fallbackSource;

    [SerializeField] private int targetWidth = 512;
    [SerializeField] private int targetHeight = 288;

    private const string ResolutionPath = "unity-shadertoy-validation/shadertoy-9/shadertoy-9-capture.resolution.json";
    private const string VideoAssetPath = "Assets/unity-shadertoy-validation/shadertoy-9/Textures/35c87bcb8d7af24c54d41122dadb619dd920646a0bd0e477e7bdc6d12876df17.webm";
    private const string QuadName = "ST_MtKcDG_Quad";

    private Material bufferMat;
    private Material imageMat;
    private RenderTexture sourceRT;
    private RenderTexture bufferRT;
    private VideoPlayer videoPlayer;
    private Camera runtimeCamera;
    private Transform runtimeQuad;

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (bufferShader == null) bufferShader = Shader.Find("Shadertoy/MtKcDG_BufferA");
        if (imageShader == null) imageShader = Shader.Find("Shadertoy/MtKcDG_Image");

        if (noiseTexture == null)
        {
            noiseTexture = AssetDatabase.LoadAssetAtPath<Texture2D>(
                "Assets/unity-shadertoy-validation/shadertoy-9/Textures/f735bee5b64ef98879dc618b016ecf7939a5756040c2cde21ccb15e69a6e1cfb.png");
        }

        if (paperTexture == null)
        {
            paperTexture = AssetDatabase.LoadAssetAtPath<Texture2D>(
                "Assets/unity-shadertoy-validation/shadertoy-9/Textures/8de3a3924cb95bd0e95a443fff0326c869f9d4979cd1d5b6e94e2a01f5be53e9.jpg");
        }

        if (fallbackSource == null)
        {
            fallbackSource = AssetDatabase.LoadAssetAtPath<Texture2D>(
                "Assets/unity-shadertoy-validation/shadertoy-9/Textures/buffer00.png");
        }
    }
#endif

    private void OnEnable()
    {
        LoadResolution();
        EnsureSetup();
    }

    private void Update()
    {
        EnsureSetup();
        RenderPipeline();
        FitQuad();
    }

    private void OnDisable()
    {
        if (bufferMat != null) DestroyImmediate(bufferMat);
        if (imageMat != null) DestroyImmediate(imageMat);
        if (sourceRT != null) sourceRT.Release();
        if (bufferRT != null) bufferRT.Release();
        if (videoPlayer != null) videoPlayer.Stop();
    }

    private void LoadResolution()
    {
        var fullPath = Path.Combine(Application.dataPath, ResolutionPath.Replace('/', Path.DirectorySeparatorChar));
        if (!File.Exists(fullPath)) return;
        var json = File.ReadAllText(fullPath);
        var m = Regex.Match(json, "\"unityResolution\"\\s*:\\s*\\{[^\\}]*\"width\"\\s*:\\s*(\\d+)\\s*,\\s*\"height\"\\s*:\\s*(\\d+)", RegexOptions.Singleline);
        if (!m.Success) return;
        targetWidth = int.Parse(m.Groups[1].Value);
        targetHeight = int.Parse(m.Groups[2].Value);
    }

    private void EnsureSetup()
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

        if (runtimeQuad == null)
        {
            var q = GameObject.Find(QuadName);
            if (q == null)
            {
                q = GameObject.CreatePrimitive(PrimitiveType.Quad);
                q.name = QuadName;
                var c = q.GetComponent<Collider>();
                if (c != null) Destroy(c);
            }
            runtimeQuad = q.transform;
        }

        EnsureRTs();

        if (bufferMat == null && bufferShader != null) bufferMat = new Material(bufferShader);
        if (imageMat == null && imageShader != null) imageMat = new Material(imageShader);

        if (runtimeQuad != null && imageMat != null)
        {
            var r = runtimeQuad.GetComponent<MeshRenderer>();
            if (r != null) r.sharedMaterial = imageMat;
        }

        EnsureVideoPlayer();
    }

    private void EnsureRTs()
    {
        if (targetWidth <= 0 || targetHeight <= 0) return;

        if (sourceRT == null || sourceRT.width != targetWidth || sourceRT.height != targetHeight)
        {
            if (sourceRT != null) sourceRT.Release();
            sourceRT = new RenderTexture(targetWidth, targetHeight, 0, RenderTextureFormat.ARGB32)
            {
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp,
                name = "ST_MtKcDG_SourceRT"
            };
            sourceRT.Create();
        }

        if (bufferRT == null || bufferRT.width != targetWidth || bufferRT.height != targetHeight)
        {
            if (bufferRT != null) bufferRT.Release();
            bufferRT = new RenderTexture(targetWidth, targetHeight, 0, RenderTextureFormat.ARGB32)
            {
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp,
                name = "ST_MtKcDG_BufferRT"
            };
            bufferRT.Create();
        }
    }

    private void EnsureVideoPlayer()
    {
        if (videoPlayer != null) return;

        videoPlayer = gameObject.GetComponent<VideoPlayer>();
        if (videoPlayer == null) videoPlayer = gameObject.AddComponent<VideoPlayer>();

        videoPlayer.playOnAwake = false;
        videoPlayer.isLooping = true;
        videoPlayer.renderMode = VideoRenderMode.RenderTexture;
        videoPlayer.audioOutputMode = VideoAudioOutputMode.None;
        videoPlayer.targetTexture = sourceRT;

        var fullVideoPath = Path.Combine(Application.dataPath, "unity-shadertoy-validation\\shadertoy-9\\Textures\\35c87bcb8d7af24c54d41122dadb619dd920646a0bd0e477e7bdc6d12876df17.webm");
        if (File.Exists(fullVideoPath))
        {
            videoPlayer.source = VideoSource.Url;
            videoPlayer.url = fullVideoPath;
            videoPlayer.Prepare();
            videoPlayer.Play();
        }
    }

    private void RenderPipeline()
    {
        if (bufferMat == null || imageMat == null || bufferRT == null) return;

        Texture src = (videoPlayer != null && videoPlayer.isPrepared && sourceRT != null) ? (Texture)sourceRT : fallbackSource;
        if (src == null) return;

        bufferMat.SetTexture("_Channel0", src);
        if (noiseTexture != null) bufferMat.SetTexture("_Channel1", noiseTexture);
        if (paperTexture != null) bufferMat.SetTexture("_Channel2", paperTexture);
        bufferMat.SetFloat("_STTime", Time.time);

        Graphics.Blit(null, bufferRT, bufferMat);

        imageMat.SetTexture("_Channel0", bufferRT);
        if (paperTexture != null) imageMat.SetTexture("_Channel2", paperTexture);
        imageMat.SetVector("_STResolution", new Vector4(targetWidth, targetHeight, 1f / targetWidth, 1f / targetHeight));
    }

    private void FitQuad()
    {
        if (runtimeCamera == null || runtimeQuad == null) return;
        float h = runtimeCamera.orthographicSize * 2f;
        float w = h * runtimeCamera.aspect;
        runtimeQuad.position = Vector3.zero;
        runtimeQuad.rotation = Quaternion.identity;
        runtimeQuad.localScale = new Vector3(w, h, 1f);
    }
}
