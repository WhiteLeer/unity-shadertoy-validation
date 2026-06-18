using System.Text;
using UnityEditor;
using UnityEngine;

public static class ShadertoyDiagnostics
{
    [MenuItem("Tools/Shadertoy/Log Active Scene Diagnostics")]
    private static void LogActiveSceneDiagnostics()
    {
        var sb = new StringBuilder();
        var cam = Camera.main;
        sb.AppendLine("[ShadertoyDiag] Scene diagnostics");

        if (cam == null)
        {
            sb.AppendLine("Camera: <null>");
        }
        else
        {
            sb.AppendLine($"Camera: {cam.name}");
            sb.AppendLine($"  orthographic={cam.orthographic}");
            sb.AppendLine($"  orthoSize={cam.orthographicSize}");
            sb.AppendLine($"  aspect={cam.aspect}");
            sb.AppendLine($"  position={cam.transform.position}");
            sb.AppendLine($"  rotation={cam.transform.rotation.eulerAngles}");
            sb.AppendLine($"  clearFlags={cam.clearFlags}");
            sb.AppendLine($"  background={cam.backgroundColor}");
        }

        var all = Object.FindObjectsOfType<Transform>(true);
        foreach (var t in all)
        {
            if (t == null)
            {
                continue;
            }

            if (!t.name.StartsWith("ST_", System.StringComparison.Ordinal) ||
                !t.name.EndsWith("_Quad", System.StringComparison.Ordinal))
            {
                continue;
            }

            var go = t.gameObject;
            var mf = go.GetComponent<MeshFilter>();
            var mr = go.GetComponent<MeshRenderer>();
            sb.AppendLine($"Quad: {go.name}");
            sb.AppendLine($"  active={go.activeInHierarchy}");
            sb.AppendLine($"  position={t.position}");
            sb.AppendLine($"  scale={t.localScale}");
            sb.AppendLine($"  mesh={(mf != null && mf.sharedMesh != null ? mf.sharedMesh.name : "<null>")}");
            sb.AppendLine($"  rendererEnabled={(mr != null && mr.enabled)}");
            sb.AppendLine($"  material={(mr != null && mr.sharedMaterial != null ? mr.sharedMaterial.name : "<null>")}");
            sb.AppendLine($"  shader={(mr != null && mr.sharedMaterial != null && mr.sharedMaterial.shader != null ? mr.sharedMaterial.shader.name : "<null>")}");
        }

        Debug.Log(sb.ToString());
    }
}
