using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.SceneManagement;
#if UNITY_EDITOR
using UnityEditor;
#endif

public class ShadertoySceneAuditCapture : MonoBehaviour
{
    private const string RunningKey = "ShadertoyAudit.Running";
    private const string IndexKey = "ShadertoyAudit.Index";
    private const string PathsKey = "ShadertoyAudit.Paths";
    private const string OutputFolderKey = "ShadertoyAudit.OutputFolder";

    public string scenePath;
    public string outputFolder;
    [SerializeField] private int warmupFrames = 12;
    [SerializeField] private int cooldownFrames = 3;
    private int frameCount;
    private bool captured;
    private int cooldownCount;
    private List<string> scenePaths;
    private int sceneIndex;
    private AsyncOperation loadOperation;
    private enum Phase { Warmup, Captured, LoadingNext }
    private Phase phase = Phase.Warmup;

    private void Awake()
    {
        DontDestroyOnLoad(gameObject);
    }

    private void Start()
    {
#if UNITY_EDITOR
        outputFolder = EditorPrefs.GetString(OutputFolderKey, outputFolder);
        var packed = EditorPrefs.GetString(PathsKey, string.Empty);
        scenePaths = new List<string>(packed.Split(new[] { '|' }, StringSplitOptions.RemoveEmptyEntries));
        sceneIndex = Mathf.Max(0, EditorPrefs.GetInt(IndexKey, 0));
        scenePath = sceneIndex < scenePaths.Count ? scenePaths[sceneIndex] : scenePath;
#else
        scenePaths = new List<string>();
#endif
        phase = Phase.Warmup;
        frameCount = 0;
        cooldownCount = 0;
        captured = false;
    }

    private void Update()
    {
        if (scenePaths == null || scenePaths.Count == 0)
        {
            return;
        }

        if (loadOperation != null)
        {
            if (!loadOperation.isDone)
            {
                return;
            }

            loadOperation = null;
            frameCount = 0;
            cooldownCount = 0;
            captured = false;
            phase = Phase.Warmup;
            return;
        }

        if (phase == Phase.Warmup)
        {
            frameCount++;
            if (frameCount < warmupFrames)
            {
                return;
            }

            phase = Phase.Captured;
        }

        if (phase == Phase.Captured)
        {
            if (captured)
            {
                return;
            }

            CaptureCurrentScene();
            captured = true;
            phase = Phase.LoadingNext;
            cooldownCount = 0;
            return;
        }

        if (phase == Phase.LoadingNext)
        {
            cooldownCount++;
            if (cooldownCount < cooldownFrames)
            {
                return;
            }

            sceneIndex++;
            if (sceneIndex >= scenePaths.Count)
            {
#if UNITY_EDITOR
                EditorPrefs.SetBool(RunningKey, false);
                EditorApplication.isPlaying = false;
#endif
                enabled = false;
                return;
            }

#if UNITY_EDITOR
            EditorPrefs.SetInt(IndexKey, sceneIndex);
#endif
            scenePath = scenePaths[sceneIndex];
            loadOperation = SceneManager.LoadSceneAsync(scenePath, LoadSceneMode.Single);
            if (loadOperation == null)
            {
                Debug.LogError($"[ShadertoyAudit] Failed to load scene asynchronously: {scenePath}");
            }
            return;
        }
    }

    private void CaptureCurrentScene()
    {
        var sceneName = Path.GetFileNameWithoutExtension(scenePath);
        var outputPath = Path.Combine(outputFolder, $"{sceneName}.png");
        ScreenCapture.CaptureScreenshot(outputPath);
        Debug.Log($"[ShadertoyAudit] Captured {scenePath} -> {outputPath}");

#if UNITY_EDITOR
        EditorPrefs.SetInt(IndexKey, EditorPrefs.GetInt(IndexKey, 0) + 1);
#endif
    }
}
