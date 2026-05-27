# XlBSRz (VolumetricIntegration) 原理解析

## 1. 效果类型
- 单 pass 体积渲染演示，重点是介质积分与体积阴影。
- 通过 raymarch 在参与介质中积分单次散射和透过率。

## 2. 核心流程
1. 定义密度场（高度雾 + 球体局部浓雾 + 噪声扰动）。
2. 沿视线分步前进，累计散射并衰减透过率。
3. 每个步长向光源方向做次级 march，估计体积阴影（transmittance）。
4. 使用改进积分公式减少强散射情况下的能量误差。
5. 合成背景色并做 tone mapping。

## 3. 与原版关系
- 当前 Unity shader 为可运行 HLSL 适配版，保留了“体积分 + 阴影 + 改进积分”主思路。
- 原始 GLSL 完整源码已保存在同目录，作为后续逐段对齐依据。

## 4. 输入
- `iChannel0` 噪声纹理 -> `_Channel0`
- 分辨率由 `shadertoy-4-capture.resolution.json` 自动驱动

