# w32XzG 抓取报告

- Source: https://www.shadertoy.com/view/w32XzG
- Shader: w32XzG / globules bubbles
- Author: FabriceNeyret2
- Resolution: 960 x 540
- Render passes: 1 (Image)
- Bound inputs: none
- Texture assets downloaded: 0
- Placeholder textures: 0

## 已生成文件

- Shaders/w32XzG_0_image.glsl
- Shaders/w32XzG_image_pass.glsl
- Shaders/w32XzG_hlsl_port.hlsl
- Shaders/shadertoy-w32XzG.shader
- Scripts/ShadertoyW32XzG_v30Bootstrap.cs
- Scenes/shadertoy-30-w32XzG.unity
- shadertoy-30-capture.json
- shadertoy-30-capture.resolution.json
- Shaders/w32XzG_unity_meta.json
- Docs/w32XzG_principle.md

## 端口说明

原始 GLSL 已完整保存。HLSL 端保留 200 次气泡坐标变形、fwidth 轮廓、hue 颜色和鼠标控制。仅对 GLSL/HLSL 语义差异做等价处理：显式向量构造、all 向量比较、out 深度参数和确定性的循环初始化。

该效果的 iMouse 已在 Bootstrap 中转换为画布局部坐标；未直接使用 Unity 编辑器窗口的绝对屏幕坐标。

## 验证边界

本次完成文件级抓取和静态检查，没有操作 Unity 编辑器或 MCP，避免影响同一工程中的其他工作。
