using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

public static class ShadertoySceneAuditRunner
{
    private const string RunningKey = "ShadertoySceneAudit.Running";
    private const string IndexKey = "ShadertoySceneAudit.Index";
    private const string PathsKey = "ShadertoySceneAudit.Paths";
    private const string OutputFolderKey = "ShadertoySceneAudit.OutputFolder";
    private const string AgentName = "ShadertoySceneAuditCapture";

    [MenuItem("Tools/Shadertoy/Capture Acceptance Scenes")]
    private static void StartAudit()
    {
        var scenePaths = FindAcceptanceScenes();
        if (scenePaths.Count == 0)
        {
            Debug.LogWarning("[ShadertoyAudit] No acceptance scenes found.");
            return;
        }

        var outputFolder = Path.Combine(Application.dataPath, "Screenshots", "shadertoy-audit");
        Directory.CreateDirectory(outputFolder);

        EditorPrefs.SetBool(RunningKey, true);
        EditorPrefs.SetInt(IndexKey, 0);
        EditorPrefs.SetString(PathsKey, string.Join("|", scenePaths));
        EditorPrefs.SetString(OutputFolderKey, outputFolder);
        Debug.Log($"[ShadertoyAudit] Prepared {scenePaths.Count} scene(s). Load the first scene, add a ShadertoySceneAuditCapture component, then enter Play.");
    }

    private static List<string> FindAcceptanceScenes()
    {
        var guids = AssetDatabase.FindAssets("t:Scene", new[] { "Assets/unity-shadertoy-validation" });
        var paths = guids
            .Select(AssetDatabase.GUIDToAssetPath)
            .Where(path => path.EndsWith("-acceptance.unity", System.StringComparison.OrdinalIgnoreCase))
            .OrderBy(path => path)
            .ToList();
        return paths;
    }
}
