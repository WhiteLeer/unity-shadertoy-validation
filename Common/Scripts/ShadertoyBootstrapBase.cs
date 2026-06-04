using System;
using System.IO;
using System.Text.RegularExpressions;
using UnityEngine;
#if UNITY_RENDER_PIPELINE_UNIVERSAL || UNITY_2021_3_OR_NEWER
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
#endif
#if UNITY_EDITOR
using System.Reflection;
using UnityEditor;
#endif

[ExecuteAlways]
public abstract class ShadertoyBootstrapBase : MonoBehaviour
{
    protected abstract string TargetShaderName { get; }
    protected abstract string QuadObjectName { get; }
    protected abstract string DefaultResolutionJsonRelativePath { get; }

    [Header("Capture Resolution")]
    [SerializeField] private TextAsset captureReport;
    [SerializeField] private int targetWidth = 1024;
    [SerializeField] private int targetHeight = 576;
    [SerializeField] private bool applyEditorGameView = true;
    [SerializeField] private bool applyPlayerResolution = true;

    private Material runtimeMaterial;
    private bool resolutionApplied;
    private Camera runtimeCamera;
    private Transform runtimeQuadTransform;
    private int frameIndex;
    private bool rendererFeaturesSuppressed;

#if UNITY_EDITOR
    private static readonly string[] InterferingRendererFeatureNames = { "SSRRenderFeature" };
    private static readonly System.Collections.Generic.Dictionary<ScriptableRendererFeature, bool> PreviousRendererFeatureStates =
        new System.Collections.Generic.Dictionary<ScriptableRendererFeature, bool>();
#endif

    private void OnEnable()
    {
        frameIndex = 0;
        TryLoadResolutionFromCaptureReport();
        ApplyTargetResolution();
        SuppressInterferingRendererFeatures();
        EnsureSceneSetup();
        PushCommonUniforms(runtimeMaterial);
        FitQuadToCamera();
        TickCustom(runtimeMaterial);
    }

    private void Update()
    {
        if (!Application.isPlaying || resolutionApplied)
        {
            PushCommonUniforms(runtimeMaterial);
            FitQuadToCamera();
            TickCustom(runtimeMaterial);
            return;
        }

        ApplyTargetResolution();
        PushCommonUniforms(runtimeMaterial);
        FitQuadToCamera();
        TickCustom(runtimeMaterial);
        frameIndex++;
    }

    private void OnDisable()
    {
        RestoreSuppressedRendererFeatures();

        if (runtimeMaterial != null)
        {
            if (Application.isPlaying)
            {
                Destroy(runtimeMaterial);
            }
            else
            {
                DestroyImmediate(runtimeMaterial);
            }
            runtimeMaterial = null;
        }
    }

    private void SuppressInterferingRendererFeatures()
    {
#if UNITY_EDITOR && (UNITY_RENDER_PIPELINE_UNIVERSAL || UNITY_2021_3_OR_NEWER)
        if (rendererFeaturesSuppressed)
        {
            return;
        }

        var pipelineAsset = QualitySettings.renderPipeline as UniversalRenderPipelineAsset;
        if (pipelineAsset == null)
        {
            pipelineAsset = GraphicsSettings.currentRenderPipeline as UniversalRenderPipelineAsset;
        }

        if (pipelineAsset == null)
        {
            return;
        }

        var serializedPipeline = new SerializedObject(pipelineAsset);
        var rendererList = serializedPipeline.FindProperty("m_RendererDataList");
        if (rendererList == null || !rendererList.isArray)
        {
            return;
        }

        for (int i = 0; i < rendererList.arraySize; i++)
        {
            var rendererData = rendererList.GetArrayElementAtIndex(i).objectReferenceValue as ScriptableRendererData;
            if (rendererData == null)
            {
                continue;
            }

            bool rendererDirty = false;
            foreach (var feature in rendererData.rendererFeatures)
            {
                if (feature == null)
                {
                    continue;
                }

                bool shouldSuppress = Array.Exists(
                    InterferingRendererFeatureNames,
                    featureName => string.Equals(feature.name, featureName, StringComparison.Ordinal)
                );
                if (!shouldSuppress)
                {
                    continue;
                }

                if (!PreviousRendererFeatureStates.ContainsKey(feature))
                {
                    PreviousRendererFeatureStates[feature] = feature.isActive;
                }

                if (feature.isActive)
                {
                    feature.SetActive(false);
                    EditorUtility.SetDirty(feature);
                    rendererDirty = true;
                }
            }

            if (rendererDirty)
            {
                rendererData.SetDirty();
                EditorUtility.SetDirty(rendererData);
            }
        }

        rendererFeaturesSuppressed = true;
#endif
    }

    private void RestoreSuppressedRendererFeatures()
    {
#if UNITY_EDITOR && (UNITY_RENDER_PIPELINE_UNIVERSAL || UNITY_2021_3_OR_NEWER)
        if (!rendererFeaturesSuppressed)
        {
            return;
        }

        foreach (var kvp in PreviousRendererFeatureStates)
        {
            if (kvp.Key == null)
            {
                continue;
            }

            kvp.Key.SetActive(kvp.Value);
            EditorUtility.SetDirty(kvp.Key);
        }

        PreviousRendererFeatureStates.Clear();
        rendererFeaturesSuppressed = false;
#endif
    }

    private void TryLoadResolutionFromCaptureReport()
    {
        if (captureReport != null && !string.IsNullOrEmpty(captureReport.text))
        {
            var fromTextAsset = TryExtractResolution(captureReport.text);
            if (fromTextAsset.x > 0 && fromTextAsset.y > 0)
            {
                targetWidth = fromTextAsset.x;
                targetHeight = fromTextAsset.y;
                return;
            }
        }

        if (string.IsNullOrWhiteSpace(DefaultResolutionJsonRelativePath))
        {
            return;
        }

        var fullPath = Path.Combine(Application.dataPath, DefaultResolutionJsonRelativePath.Replace('/', Path.DirectorySeparatorChar));
        if (!File.Exists(fullPath))
        {
            return;
        }

        var fileText = File.ReadAllText(fullPath);
        var parsed = TryExtractResolution(fileText);
        if (parsed.x <= 0 || parsed.y <= 0)
        {
            return;
        }

        targetWidth = parsed.x;
        targetHeight = parsed.y;
    }

    private static Vector2Int TryExtractResolution(string json)
    {
        var unityMatch = Regex.Match(
            json,
            "\"unityResolution\"\\s*:\\s*\\{[^\\}]*\"width\"\\s*:\\s*(\\d+)\\s*,\\s*\"height\"\\s*:\\s*(\\d+)",
            RegexOptions.Singleline
        );
        if (unityMatch.Success)
        {
            return new Vector2Int(int.Parse(unityMatch.Groups[1].Value), int.Parse(unityMatch.Groups[2].Value));
        }

        var viewportMatch = Regex.Match(
            json,
            "\"glViewport\"\\s*:\\s*\\{[^\\}]*\"w\"\\s*:\\s*(\\d+)\\s*,\\s*\"h\"\\s*:\\s*(\\d+)",
            RegexOptions.Singleline
        );
        if (viewportMatch.Success)
        {
            return new Vector2Int(int.Parse(viewportMatch.Groups[1].Value), int.Parse(viewportMatch.Groups[2].Value));
        }

        return Vector2Int.zero;
    }

    private void ApplyTargetResolution()
    {
        if (targetWidth <= 0 || targetHeight <= 0)
        {
            return;
        }

        if (applyPlayerResolution)
        {
            Screen.SetResolution(targetWidth, targetHeight, false);
        }

#if UNITY_EDITOR
        if (applyEditorGameView)
        {
            ShadertoyGameViewResolutionUtil.EnsureAndSelect(targetWidth, targetHeight, $"ST {targetWidth}x{targetHeight}");
        }
#endif
        resolutionApplied = true;
    }

    private void EnsureSceneSetup()
    {
        var cam = GetComponent<Camera>();
        if (cam == null)
        {
            cam = Camera.main;
        }

        if (cam == null)
        {
            return;
        }

        cam.orthographic = true;
        cam.orthographicSize = 1f;
        cam.transform.position = new Vector3(0f, 0f, -1f);
        cam.transform.rotation = Quaternion.identity;
        cam.clearFlags = CameraClearFlags.SolidColor;
        cam.backgroundColor = Color.black;
        runtimeCamera = cam;

        var shader = Shader.Find(TargetShaderName);
        if (shader == null)
        {
            Debug.LogError($"Shader not found: {TargetShaderName}");
            return;
        }

        var shouldRecreateMaterial = runtimeMaterial == null || runtimeMaterial.shader != shader || !Application.isPlaying;
        if (shouldRecreateMaterial)
        {
            if (runtimeMaterial != null)
            {
                if (Application.isPlaying)
                {
                    Destroy(runtimeMaterial);
                }
                else
                {
                    DestroyImmediate(runtimeMaterial);
                }
            }
            runtimeMaterial = new Material(shader);
            runtimeMaterial.name = $"M_{QuadObjectName}_Runtime";
        }
        ConfigureMaterial(runtimeMaterial);
        PushCommonUniforms(runtimeMaterial);

        var quad = GameObject.Find(QuadObjectName);
        if (quad == null)
        {
            quad = GameObject.CreatePrimitive(PrimitiveType.Quad);
            quad.name = QuadObjectName;
            quad.transform.position = Vector3.zero;
            quad.transform.rotation = Quaternion.identity;

            var colliderComponent = quad.GetComponent<Collider>();
            if (colliderComponent != null)
            {
                if (Application.isPlaying)
                {
                    Destroy(colliderComponent);
                }
                else
                {
                    DestroyImmediate(colliderComponent);
                }
            }
        }
        runtimeQuadTransform = quad.transform;

        var renderer = quad.GetComponent<MeshRenderer>();
        if (renderer != null)
        {
            renderer.sharedMaterial = runtimeMaterial;
            renderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            renderer.receiveShadows = false;
            renderer.lightProbeUsage = UnityEngine.Rendering.LightProbeUsage.Off;
            renderer.reflectionProbeUsage = UnityEngine.Rendering.ReflectionProbeUsage.Off;
        }

        FitQuadToCamera();
    }

    protected virtual void ConfigureMaterial(Material material)
    {
    }

    /// <summary>
    /// Pushes a stable set of Shadertoy-style uniforms so per-shader bootstraps do not need
    /// to re-implement this boilerplate and accidentally diverge (axis/time/mouse bugs).
    /// </summary>
    private void PushCommonUniforms(Material material)
    {
        if (material == null)
        {
            return;
        }

        var w = Mathf.Max(1, targetWidth);
        var h = Mathf.Max(1, targetHeight);
        material.SetVector("_STResolution", new Vector4(w, h, 1f / w, 1f / h));
        material.SetFloat("_STTime", Time.time);
        material.SetFloat("_STDeltaTime", Time.deltaTime);
        material.SetFloat("_STFrame", frameIndex);

        var mousePos = Input.mousePosition;
        var mouseDown = Input.GetMouseButton(0) ? 1f : 0f;
        material.SetVector("_STMouse", new Vector4(mousePos.x, mousePos.y, mouseDown, mouseDown));
    }

    protected virtual void TickCustom(Material material)
    {
    }

    private void FitQuadToCamera()
    {
        if (runtimeCamera == null || runtimeQuadTransform == null)
        {
            return;
        }

        if (runtimeCamera.orthographic)
        {
            var h = runtimeCamera.orthographicSize * 2f;
            var w = h * runtimeCamera.aspect;
            runtimeQuadTransform.position = new Vector3(0f, 0f, 0f);
            runtimeQuadTransform.rotation = Quaternion.identity;
            runtimeQuadTransform.localScale = new Vector3(w, h, 1f);
        }
    }
}

#if UNITY_EDITOR
internal static class ShadertoyGameViewResolutionUtil
{
    private enum GameViewSizeType
    {
        AspectRatio = 0,
        FixedResolution = 1
    }

    private static readonly object GameViewSizesInstance;
    private static readonly MethodInfo GetGroupMethod;
    private static readonly Type GameViewType;
    private static readonly Type GameViewSizeTypeEnum;
    private static readonly Type GameViewSizeClass;

    static ShadertoyGameViewResolutionUtil()
    {
        var editorAssembly = typeof(Editor).Assembly;
        var sizesType = editorAssembly.GetType("UnityEditor.GameViewSizes");
        var singletonType = typeof(ScriptableSingleton<>).MakeGenericType(sizesType);
        var instanceProp = singletonType.GetProperty("instance");
        GameViewSizesInstance = instanceProp.GetValue(null, null);
        GetGroupMethod = sizesType.GetMethod("GetGroup");
        GameViewType = editorAssembly.GetType("UnityEditor.GameView");
        GameViewSizeTypeEnum = editorAssembly.GetType("UnityEditor.GameViewSizeType");
        GameViewSizeClass = editorAssembly.GetType("UnityEditor.GameViewSize");
    }

    public static void EnsureAndSelect(int width, int height, string label)
    {
        try
        {
            var groupType = GetCurrentGroupType();
            var group = GetGroupMethod.Invoke(GameViewSizesInstance, new object[] { (int)groupType });
            var index = FindSizeIndex(group, width, height);
            if (index < 0)
            {
                AddCustomSize(group, width, height, label);
                index = FindSizeIndex(group, width, height);
            }

            if (index >= 0)
            {
                SetSelectedSizeIndex(index);
            }
        }
        catch (Exception e)
        {
            Debug.LogWarning($"[Shadertoy] Failed to set GameView resolution: {e.Message}");
        }
    }

    private static GameViewSizeGroupType GetCurrentGroupType()
    {
        var prop = GameViewSizesInstance.GetType().GetProperty("currentGroupType");
        return (GameViewSizeGroupType)(int)prop.GetValue(GameViewSizesInstance, null);
    }

    private static int FindSizeIndex(object group, int width, int height)
    {
        var getTotalCount = group.GetType().GetMethod("GetTotalCount");
        var getGameViewSize = group.GetType().GetMethod("GetGameViewSize");
        var count = (int)getTotalCount.Invoke(group, null);
        for (var i = 0; i < count; i++)
        {
            var size = getGameViewSize.Invoke(group, new object[] { i });
            var sizeType = size.GetType();
            var w = (int)sizeType.GetProperty("width").GetValue(size, null);
            var h = (int)sizeType.GetProperty("height").GetValue(size, null);
            if (w == width && h == height)
            {
                return i;
            }
        }
        return -1;
    }

    private static void AddCustomSize(object group, int width, int height, string label)
    {
        var ctor = GameViewSizeClass.GetConstructor(new[] { GameViewSizeTypeEnum, typeof(int), typeof(int), typeof(string) });
        var fixedResolutionEnum = Enum.ToObject(GameViewSizeTypeEnum, (int)GameViewSizeType.FixedResolution);
        var newSize = ctor.Invoke(new object[] { fixedResolutionEnum, width, height, label });
        var addCustomSize = group.GetType().GetMethod("AddCustomSize");
        addCustomSize.Invoke(group, new[] { newSize });
    }

    private static void SetSelectedSizeIndex(int index)
    {
        var gameView = EditorWindow.GetWindow(GameViewType);
        var selectedSizeIndexProp =
            GameViewType.GetProperty("selectedSizeIndex", BindingFlags.Instance | BindingFlags.Public) ??
            GameViewType.GetProperty("selectedSizeIndex", BindingFlags.Instance | BindingFlags.NonPublic);
        selectedSizeIndexProp?.SetValue(gameView, index, null);
        gameView.Repaint();
    }
}
#endif


