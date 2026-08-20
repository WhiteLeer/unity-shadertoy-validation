# Ntd3DB 抓取报告

- Source: https://www.shadertoy.com/view/Ntd3DB
- Shader: Ntd3DB / black holes - acid
- Author: morisil
- Resolution: 960 x 540
- Render passes: 1 (Image)
- Bound inputs: none
- Texture assets downloaded: 0
- Placeholder textures: 0

## 已生成文件

- Shaders/Ntd3DB_0_image.glsl
- Shaders/Ntd3DB_image_pass.glsl
- Shaders/Ntd3DB_hlsl_port.hlsl
- Shaders/shadertoy-Ntd3DB.shader
- Scripts/ShadertoyNtd3DB_v31Bootstrap.cs
- Scenes/shadertoy-31-Ntd3DB.unity
- Ntd3DB-capture.json
- Ntd3DB-capture.resolution.json
- Shaders/Ntd3DB_unity_meta.json
- Docs/Ntd3DB_principle.md

## 端口说明

原始 GLSL 已完整保存。HLSL 保留坐标扭曲、周期图案、20 次迭代、RGB 色差、亮度衰减、模糊衰减和提前退出。GLSL 与 HLSL 的矩阵、mod、atan 双参数和向量比较均按等价语义处理。

## 验证边界

本次完成文件级抓取和静态检查，没有操作 Unity 编辑器或 MCP。
