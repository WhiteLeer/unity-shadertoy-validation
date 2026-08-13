# XdyXz3 抓取报告

- Source: https://www.shadertoy.com/view/XdyXz3
- Shader: XdyXz3 / Noise Holes
- Author: airtight
- Resolution: 960 x 540
- Render passes: 1 (Image)
- Bound inputs: none
- Referenced but unbound input: iChannel0
- Texture assets downloaded: 0
- Placeholder textures: 0

## 已生成文件

- Shaders/XdyXz3_0_image.glsl
- Shaders/XdyXz3_image_pass.glsl
- Shaders/XdyXz3_hlsl_port.hlsl
- Shaders/shadertoy-XdyXz3.shader
- Scripts/ShadertoyXdyXz3_v29Bootstrap.cs
- Scenes/shadertoy-29-XdyXz3.unity
- shadertoy-29-capture.json
- shadertoy-29-capture.resolution.json
- Shaders/XdyXz3_unity_meta.json
- Docs/XdyXz3_principle.md

## 端口说明

原始 GLSL 已完整保存。HLSL 端保持原始噪声、阈值、深度量化、HSV 着色、offset bevel 和垂直渐变逻辑。唯一有意的输入替换是未绑定的 iChannel0：它不对应任何页面资源，因此使用黑色采样常量，而不是占位贴图。

## 验证边界

本次完成了文件级转换和静态结构校验，没有操作 Unity 编辑器或 MCP，避免影响同一工程中的其他工作。
