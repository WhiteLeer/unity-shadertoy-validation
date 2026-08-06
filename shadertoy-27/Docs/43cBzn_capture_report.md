# Shadertoy 43cBzn 抓取报告

- Source: https://www.shadertoy.com/view/43cBzn
- Title: Grid Attractor
- Author: takumifukasawa
- Capture basis: Chrome live page CodeMirror source
- Resolution: 960 x 540
- Passes: 1 Image pass
- Inputs: none
- Buffers: none
- Placeholder assets: none

## 输出
- Shaders/43cBzn_0_image.glsl：原始 Image pass
- Shaders/43cBzn_image_pass.glsl：Image pass 副本
- Shaders/43cBzn_hlsl_port.hlsl：Unity HLSL 函数体
- Shaders/shadertoy-43cBzn.shader：ShaderLab/URP 包装，含 ForwardUnlit 与 DepthOnly
- Scripts/Shadertoy43cBzn_v27Bootstrap.cs：验收场景自动配置
- Scenes/shadertoy-27-43cBzn.unity：独立验收场景
- shadertoy-27-capture.resolution.json：分辨率侧车文件
- Docs/43cBzn_capture.json：抓取元数据和完整源代码

## 边界
此次抓取没有网络响应 JSON 或 Buffer 依赖；页面源代码来自当前 Chrome 标签的实际编辑器内容。Unity 编辑器未被本次流程操作，最终编译仍应在目标 Unity 项目导入后确认。
