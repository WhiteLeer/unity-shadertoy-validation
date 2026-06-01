using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class Shadertoyw3KyW1_v22Bootstrap : ShadertoyBootstrapBase
{
    [SerializeField] private Texture2D channel0Texture;
    [SerializeField] private Texture2D channel1Texture;
    [SerializeField] private Vector2Int resolution = new Vector2Int(512, 288);

    [Header("Camera State (from BufferA logic)")]
    [SerializeField] private float autoRotSpeed = 0.05f;
    [SerializeField] private float camRotSpeed = 1.4f;
    [SerializeField] private float camYSpeed = 3.5f;
    [SerializeField] private Vector2 baseCamMove = new Vector2(2.5f, 1.3f);
    [SerializeField] private Vector2 minMaxCamY = new Vector2(0.5f, 6f);

    private Vector2 camMove;
    private Vector2 lastMouseNorm;
    private bool wasHeld;
    private bool inited;

    protected override string TargetShaderName => "Shadertoy/w3KyW1_OceanWaterFull";
    protected override string QuadObjectName => "ST_w3KyW1_Quad";
    protected override string DefaultResolutionJsonRelativePath => "unity-shadertoy-validation/shadertoy-22/shadertoy-22-capture.resolution.json";

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (channel0Texture == null)
            channel0Texture = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/unity-shadertoy-validation/shadertoy-22/Textures/0681c014f6c88c356cf9c0394ffe015acc94ec1474924855f45d22c3e70b5785.png");
        if (channel1Texture == null)
            channel1Texture = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/unity-shadertoy-validation/shadertoy-22/Textures/buffer00.png");
    }
#endif

    private void EnsureState()
    {
        if (inited) return;
        camMove = baseCamMove;
        lastMouseNorm = new Vector2(-1f, -1f);
        wasHeld = false;
        inited = true;
    }

    protected override void ConfigureMaterial(Material material)
    {
        EnsureState();
        if (material == null) return;
        if (channel0Texture != null)
        {
            channel0Texture.wrapMode = TextureWrapMode.Clamp;
            channel0Texture.filterMode = FilterMode.Trilinear;
            material.SetTexture("_Channel0", channel0Texture);
        }
        if (channel1Texture != null)
        {
            channel1Texture.wrapMode = TextureWrapMode.Clamp;
            channel1Texture.filterMode = FilterMode.Bilinear;
            material.SetTexture("_Channel1", channel1Texture);
        }
        material.SetVector("_STResolution", new Vector4(resolution.x, resolution.y, 1f / Mathf.Max(1, resolution.x), 1f / Mathf.Max(1, resolution.y)));
        material.SetFloat("_STTime", 0f);
        material.SetVector("_CamMove", camMove);
    }

    protected override void TickCustom(Material material)
    {
        EnsureState();
        if (material == null) return;

        bool isHeld = Input.GetMouseButton(0);
        Vector2 mpNew = new Vector2(Input.mousePosition.x, Input.mousePosition.y) / Mathf.Max(1f, resolution.y);

        if (isHeld && wasHeld && lastMouseNorm.x >= 0f)
        {
            Vector2 delta = mpNew - lastMouseNorm;
            camMove.x -= delta.x * camRotSpeed;
            camMove.y -= delta.y * camYSpeed;
        }
        else
        {
            camMove.x += autoRotSpeed * Time.deltaTime;
        }

        camMove.y = Mathf.Clamp(camMove.y, minMaxCamY.x, minMaxCamY.y);
        lastMouseNorm = isHeld ? mpNew : new Vector2(-1f, -1f);
        wasHeld = isHeld;

        material.SetVector("_STResolution", new Vector4(resolution.x, resolution.y, 1f / Mathf.Max(1, resolution.x), 1f / Mathf.Max(1, resolution.y)));
        material.SetFloat("_STTime", Time.time);
        material.SetVector("_CamMove", camMove);
    }
}
