using UnityEngine;

public class TempRendererProbe : MonoBehaviour
{
    private Material probeMaterial;

    private void OnEnable()
    {
        var renderer = GetComponent<MeshRenderer>();
        if (renderer == null)
        {
            return;
        }

        var shader = Shader.Find("Universal Render Pipeline/Unlit");
        if (shader == null)
        {
            Debug.LogError("TempRendererProbe: shader not found");
            return;
        }

        probeMaterial = new Material(shader)
        {
            name = "M_TempRendererProbe_Runtime"
        };
        probeMaterial.color = Color.red;
        renderer.sharedMaterial = probeMaterial;
    }

    private void OnDestroy()
    {
        if (probeMaterial != null)
        {
            DestroyImmediate(probeMaterial);
            probeMaterial = null;
        }
    }
}
