using System;
using System.Diagnostics;
using System.IO;
using UnityEditor;
using UnityEngine;

public static class ShadertoyBatchAuditBackgroundLauncher
{
    private const string OutputEnvVar = "SHADERTOY_AUDIT_OUTPUT_ROOT";

    [MenuItem("Tools/Shadertoy/Run Batch Audit In Background")]
    public static void RunInBackground()
    {
        var projectRoot = Directory.GetParent(Application.dataPath)?.FullName;
        if (string.IsNullOrWhiteSpace(projectRoot))
        {
            UnityEngine.Debug.LogError("[ShadertoyBatchAuditBackgroundLauncher] Cannot resolve project root.");
            return;
        }

        var unityExe = EditorApplication.applicationPath;
        var tempRoot = Path.Combine(Path.GetTempPath(), "shadertoy-batch-audit", DateTime.Now.ToString("yyyyMMdd-HHmmss"));
        Directory.CreateDirectory(tempRoot);

        CopyProjectSkeleton(projectRoot, tempRoot);

        var logFile = Path.Combine(tempRoot, "batch-audit.log");
        var psi = new ProcessStartInfo
        {
            FileName = unityExe,
            Arguments =
                $"-batchmode -projectPath \"{tempRoot}\" -executeMethod ShadertoyBatchAudit.Run -logFile \"{logFile}\"",
            UseShellExecute = false,
            CreateNoWindow = true
        };

        psi.EnvironmentVariables[OutputEnvVar] = projectRoot;

        Process.Start(psi);
        UnityEngine.Debug.Log($"[ShadertoyBatchAuditBackgroundLauncher] Started hidden batch audit in {tempRoot}");
    }

    private static void CopyProjectSkeleton(string sourceRoot, string targetRoot)
    {
        CopyDirectory(Path.Combine(sourceRoot, "Assets"), Path.Combine(targetRoot, "Assets"));
        CopyDirectory(Path.Combine(sourceRoot, "Packages"), Path.Combine(targetRoot, "Packages"));
        CopyDirectory(Path.Combine(sourceRoot, "ProjectSettings"), Path.Combine(targetRoot, "ProjectSettings"));
    }

    private static void CopyDirectory(string sourceDir, string targetDir)
    {
        if (!Directory.Exists(sourceDir))
        {
            return;
        }

        Directory.CreateDirectory(targetDir);

        foreach (var file in Directory.GetFiles(sourceDir, "*", SearchOption.AllDirectories))
        {
            var relative = Path.GetRelativePath(sourceDir, file);
            var destination = Path.Combine(targetDir, relative);
            Directory.CreateDirectory(Path.GetDirectoryName(destination)!);
            File.Copy(file, destination, true);
        }
    }
}
