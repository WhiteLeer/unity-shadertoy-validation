using System;
using System.IO;
using System.Text.RegularExpressions;
using UnityEngine;
#if UNITY_EDITOR
using System.Reflection;
using UnityEditor;
#endif

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

    private void OnEnable()
    {
        TryLoadResolutionFromCaptureReport();
        ApplyTargetResolution();
        EnsureSceneSetup();
    }

    private void Update()
    {
        if (!Application.isPlaying || resolutionApplied)
        {
            FitQuadToCamera();
            TickCustom(runtimeMaterial);
            return;
        }

        ApplyTargetResolution();
        FitQuadToCamera();
        TickCustom(runtimeMaterial);
    }

    private void OnDisable()
    {
        if (runtimeMaterial != null)
        {
            Destroy(runtimeMaterial);
            runtimeMaterial = null;
        }
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

        if (runtimeMaterial == null || runtimeMaterial.shader != shader)
        {
            runtimeMaterial = new Material(shader);
            runtimeMaterial.name = $"M_{QuadObjectName}_Runtime";
        }
        ConfigureMaterial(runtimeMaterial);

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
                Destroy(colliderComponent);
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

