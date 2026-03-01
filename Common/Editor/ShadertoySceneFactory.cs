using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

public static class ShadertoySceneFactory
{
    [MenuItem("Tools/Shadertoy/Create Default Scene/0 - NflSD8")]
    private static void CreateShadertoy0Scene()
    {
        CreateDefaultAcceptanceScene(
            "Assets/unity-shadertoy-validation/shadertoy-0/Scenes/shadertoy-0-acceptance.unity",
            "ShadertoyNflSD8Bootstrap"
        );
    }

    [MenuItem("Tools/Shadertoy/Create Default Scene/1 - 4tc3DX")]
    private static void CreateShadertoy1Scene()
    {
        CreateDefaultAcceptanceScene(
            "Assets/unity-shadertoy-validation/shadertoy-1/Scenes/shadertoy-1-acceptance.unity",
            "Shadertoy4tc3DXBootstrap"
        );
    }

    private static void CreateDefaultAcceptanceScene(string sceneAssetPath, string bootstrapTypeName)
    {
        var dir = Path.GetDirectoryName(sceneAssetPath);
        if (!string.IsNullOrEmpty(dir) && !AssetDatabase.IsValidFolder(dir))
        {
            EnsureFolders(dir);
        }

        var scene = EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single);
        var cam = Camera.main ?? UnityEngine.Object.FindObjectsOfType<Camera>().FirstOrDefault();
        if (cam == null)
        {
            Debug.LogError("[Shadertoy] No camera found in new scene.");
            return;
        }

        var t = AppDomain.CurrentDomain.GetAssemblies()
            .SelectMany(a => a.GetTypes())
            .FirstOrDefault(x => x.Name == bootstrapTypeName);
        if (t == null)
        {
            Debug.LogError($"[Shadertoy] Bootstrap type not found: {bootstrapTypeName}");
            return;
        }

        if (cam.GetComponent(t) == null)
        {
            cam.gameObject.AddComponent(t);
        }

        EditorSceneManager.SaveScene(scene, sceneAssetPath);
        AssetDatabase.Refresh();
        Debug.Log($"[Shadertoy] Created scene: {sceneAssetPath}");
    }

    private static void EnsureFolders(string assetPath)
    {
        var parts = assetPath.Split('/');
        var current = parts[0];
        for (var i = 1; i < parts.Length; i++)
        {
            var next = $"{current}/{parts[i]}";
            if (!AssetDatabase.IsValidFolder(next))
            {
                AssetDatabase.CreateFolder(current, parts[i]);
            }
            current = next;
        }
    }
}

