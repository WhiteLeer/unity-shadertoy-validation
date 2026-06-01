# Shadertoy GLSL -> Unity HLSL Porting Method (Reusable)

This project should follow this checklist before running any new capture result.

## 1) Mandatory runtime contract
- Use `ShadertoyBootstrapBase` (or equivalent) and always provide:
- `_STResolution = (w, h, 1/w, 1/h)`
- `_STTime`
- `_STDeltaTime`
- `_STFrame`
- `_STMouse = (x, y, down, down)`

Do not hand-roll these in each scene unless strictly required.

## 2) Mandatory compatibility layer
- Include `Common/Shaders/ShadertoyCompat.hlsl`.
- Replace risky direct usages:
- GLSL `atan(y, x)` -> `AtanGLSL(y, x)`
- GLSL `mod` -> `ModGLSL`
- `asin(x)` -> `SafeAsin(x)` when value can drift outside `[-1, 1]`

## 3) Axis and UV policy
- Assume Shadertoy logic is bottom-left UV.
- In Unity, explicitly choose one convention:
- If using mesh UVs directly, convert when needed with `ToShadertoyUV`.
- Never mix conventions in the same shader.
- For environment/equirectangular mapping:
- `u = AtanGLSL(dir.z, dir.x) / TAU + 0.5`
- `v = SafeAsin(dir.y) / PI + 0.5`

## 4) Matrix and vector math policy
- Use explicit helper for 2x2 transforms (`MulMat2GLSL`) to avoid row/column confusion.
- For scalar replication, use `V2/V3/V4` helpers instead of constructor guesses.

## 5) Texture sampling policy
- `texture(...)` -> `SAMPLE_TEXTURE2D(...)`
- `textureLod(...)` -> `SAMPLE_TEXTURE2D_LOD(...)`
- `texelFetch(...)` -> `Texture.Load(int3(...))`
- Verify sampler wrap/filter/vflip exactly from capture metadata.

## 6) Multi-pass policy
- Build explicit pass chain in bootstrap:
- Buffer A -> Buffer B -> Buffer C -> Image
- Bind channels from produced RTs in the same order as Shadertoy inputs.
- If an asset channel fails to fetch, keep chain running with deterministic fallback and log it.

## 7) Compile-robust style (D3D11)
- Prefer `#define` for frequently problematic global constants if `static const` parser errors appear.
- Keep literal precision conservative (avoid overly long float literals).
- Normalize line endings to CRLF after generation for stable line numbers.

## 8) Preflight checklist (must pass before handoff)
- No `AutoScaffold` references remain.
- Shader name and `TargetShaderName` match.
- All required channels bound and non-null fallbacks set.
- Scene runs without compile errors.
- Orientation check: compare against Shadertoy screenshot for left-right/up-down parity.

