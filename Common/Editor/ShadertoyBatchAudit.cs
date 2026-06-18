using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

public static class ShadertoyBatchAudit
{
    private static readonly List<string> Scenes = new List<string>();
    private static int sceneIndex = -1;
    private static string outputFolder;
    private static Camera activeCamera;
    private static RenderTexture activeRenderTexture;
    private static RenderTexture previousActiveRenderTexture;
    private static float previousCameraAspect;
    private static bool isRunning;
    private static int warmupFramesRemaining;
    private const int Width = 512;
    private const int Height = 288;

    public static void Run()
    {
        if (isRunning)
        {
            return;
        }

        Scenes.Clear();
        Scenes.AddRange(FindAcceptanceScenes());
        if (Scenes.Count == 0)
        {
            Debug.LogWarning("[ShadertoyBatchAudit] No acceptance scenes found.");
            EditorApplication.Exit(1);
            return;
        }

        var outputRoot = Environment.GetEnvironmentVariable("SHADERTOY_AUDIT_OUTPUT_ROOT");
        var outputBase = string.IsNullOrWhiteSpace(outputRoot)
            ? Application.dataPath
            : Path.Combine(outputRoot, "Assets");
        outputFolder = Path.Combine(outputBase, "Screenshots", "shadertoy-batch-audit");
        Directory.CreateDirectory(outputFolder);
        sceneIndex = -1;
        isRunning = true;
        EditorApplication.update += Tick;
        Debug.Log($"[ShadertoyBatchAudit] Started background audit for {Scenes.Count} scene(s).");
        QueueNextScene();
    }

    private static List<string> FindAcceptanceScenes()
    {
        var guids = AssetDatabase.FindAssets("t:Scene", new[] { "Assets/unity-shadertoy-validation" });
        return guids
            .Select(AssetDatabase.GUIDToAssetPath)
            .Where(path => path.EndsWith("-acceptance.unity", StringComparison.OrdinalIgnoreCase))
            .OrderBy(path => path)
            .ToList();
    }

    private static void Tick()
    {
        if (!isRunning)
        {
            return;
        }

        if (sceneIndex < 0)
        {
            return;
        }

        if (warmupFramesRemaining > 0)
        {
            warmupFramesRemaining--;
            EditorApplication.QueuePlayerLoopUpdate();
            return;
        }

        if (activeCamera == null)
        {
            activeCamera = Camera.main != null ? Camera.main : UnityEngine.Object.FindObjectOfType<Camera>(true);
            if (activeCamera == null)
            {
                Debug.LogWarning($"[ShadertoyBatchAudit] No camera found in {Scenes[sceneIndex]}");
                QueueNextScene();
                return;
            }

            activeRenderTexture = new RenderTexture(Width, Height, 24, RenderTextureFormat.ARGB32)
            {
                antiAliasing = 1
            };
            previousActiveRenderTexture = RenderTexture.active;
            previousCameraAspect = activeCamera.aspect;
            activeCamera.targetTexture = activeRenderTexture;
            activeCamera.aspect = (float)Width / Height;
            EditorApplication.QueuePlayerLoopUpdate();
            return;
        }

        try
        {
            activeCamera.Render();
            RenderTexture.active = activeRenderTexture;
            var tex = new Texture2D(Width, Height, TextureFormat.RGBA32, false);
            tex.ReadPixels(new Rect(0, 0, Width, Height), 0, 0);
            tex.Apply();

            var scenePath = Scenes[sceneIndex];
            var fileName = Path.GetFileNameWithoutExtension(scenePath) + ".png";
            var outPath = Path.Combine(outputFolder, fileName);
            File.WriteAllBytes(outPath, tex.EncodeToPNG());
            UnityEngine.Object.DestroyImmediate(tex);
            Debug.Log($"[ShadertoyBatchAudit] Captured {scenePath} -> {outPath}");
        }
        finally
        {
            if (activeCamera != null)
            {
                activeCamera.targetTexture = null;
                activeCamera.aspect = previousCameraAspect;
            }
            RenderTexture.active = previousActiveRenderTexture;
            if (activeRenderTexture != null)
            {
                UnityEngine.Object.DestroyImmediate(activeRenderTexture);
                activeRenderTexture = null;
            }
            activeCamera = null;
            previousActiveRenderTexture = null;
        }

        QueueNextScene();
    }

    private static void QueueNextScene()
    {
        sceneIndex++;
        if (sceneIndex >= Scenes.Count)
        {
            EditorApplication.update -= Tick;
            AssetDatabase.Refresh();
            isRunning = false;
            Debug.Log($"[ShadertoyBatchAudit] Finished {Scenes.Count} scene(s).");
            EditorApplication.Exit(0);
            return;
        }

        var scenePath = Scenes[sceneIndex];
        EditorSceneManager.OpenScene(scenePath, OpenSceneMode.Single);
        warmupFramesRemaining = 2;
        EditorApplication.QueuePlayerLoopUpdate();
    }
}
