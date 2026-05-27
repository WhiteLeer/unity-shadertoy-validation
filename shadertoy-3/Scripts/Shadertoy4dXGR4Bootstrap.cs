using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
public class Shadertoy4dXGR4Bootstrap : ShadertoyBootstrapBase
{
    [SerializeField] private Texture2D channel0Texture;
    [SerializeField] private AudioClip channel1Clip;
    [SerializeField] [Range(0f, 2f)] private float audioDrive = 1f;
    [SerializeField] private bool playAudioInScene = false;

    private AudioSource audioSource;
    private Texture2D audioTexture;
    private readonly float[] spectrum = new float[512];

    protected override string TargetShaderName => "Shadertoy/4dXGR4_MainSequenceStar";
    protected override string QuadObjectName => "ST_4dXGR4_Quad";
    protected override string DefaultResolutionJsonRelativePath => "Shadertoy/shadertoy-3/shadertoy-3-capture.resolution.json";

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (channel0Texture == null)
        {
            channel0Texture = AssetDatabase.LoadAssetAtPath<Texture2D>(
                "Assets/Shadertoy/shadertoy-3/Textures/92d7758c402f0927011ca8d0a7e40251439fba3a1dac26f5b8b62026323501aa.jpg"
            );
        }

        if (channel1Clip == null)
        {
            channel1Clip = AssetDatabase.LoadAssetAtPath<AudioClip>(
                "Assets/Shadertoy/shadertoy-3/Audio/3c33c415862bb7964d256f4749408247da6596f2167dca2c86cc38f83c244aa6.mp3"
            );
        }
    }
#endif

    protected override void ConfigureMaterial(Material material)
    {
        if (material == null)
        {
            return;
        }

        EnsureAudioSource();
        EnsureAudioTexture();

        if (channel0Texture != null)
        {
            material.SetTexture("_Channel0", channel0Texture);
        }

        if (audioTexture != null)
        {
            material.SetTexture("_Channel1", audioTexture);
        }

        if (playAudioInScene && audioSource != null && channel1Clip != null && !audioSource.isPlaying)
        {
            audioSource.Play();
        }
    }

    protected override void TickCustom(Material material)
    {
        if (material == null)
        {
            return;
        }

        EnsureAudioSource();
        EnsureAudioTexture();

        if (audioTexture == null)
        {
            return;
        }

        UpdateAudioTexture();
        material.SetTexture("_Channel1", audioTexture);
    }

    private void EnsureAudioSource()
    {
        if (audioSource == null)
        {
            audioSource = GetComponent<AudioSource>();
            if (audioSource == null)
            {
                audioSource = gameObject.AddComponent<AudioSource>();
            }
        }

        if (audioSource != null)
        {
            audioSource.playOnAwake = false;
            audioSource.loop = true;
            audioSource.spatialBlend = 0f;
            if (channel1Clip != null && audioSource.clip != channel1Clip)
            {
                audioSource.clip = channel1Clip;
            }
        }
    }

    private void EnsureAudioTexture()
    {
        if (audioTexture != null)
        {
            return;
        }

        audioTexture = new Texture2D(512, 2, TextureFormat.RGBA32, false, true)
        {
            wrapMode = TextureWrapMode.Clamp,
            filterMode = FilterMode.Bilinear,
            name = "ST_4dXGR4_AudioTex"
        };
    }

    private void UpdateAudioTexture()
    {
        if (audioSource != null && audioSource.isPlaying)
        {
            audioSource.GetSpectrumData(spectrum, 0, FFTWindow.BlackmanHarris);
        }
        else
        {
            var t = Time.time;
            for (var i = 0; i < spectrum.Length; i++)
            {
                var x = i / 511f;
                spectrum[i] = 0.25f + 0.25f * Mathf.Sin(t * (0.5f + x * 3.0f) + x * 10.0f);
            }
        }

        for (var x = 0; x < 512; x++)
        {
            var v = Mathf.Clamp01(spectrum[x] * 12f * audioDrive);
            var c = new Color(v, v, v, 1f);
            audioTexture.SetPixel(x, 0, c);
            audioTexture.SetPixel(x, 1, c);
        }

        audioTexture.Apply(false, false);
    }
}
