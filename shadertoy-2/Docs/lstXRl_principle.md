# lstXRl (Ray Marching Experiment 43) 原理解析

## 1. 效果类型
- 单 pass 体渲染风格 raymarch。
- 依赖两个输入：
  - `iChannel0`：环境 cubemap（反射/折射/背景）
  - `iChannel1`：位移噪声纹理（驱动壳层扰动）

## 2. 核心思路
1. 用 `map()` 定义场函数：以球壳为基础，叠加两层纹理位移。
2. 在射线行进中用增强步进（基于前后步长关系）提升效率。
3. 命中后计算法线/AO/软阴影，叠加反射与折射颜色。
4. 用 BRDF 近似项（diffuse/spec/fresnel/back/ambient）组合材质表现。
5. 与天空色和场颜色做混合，形成发光玻璃体积感。

## 3. 视觉来源拆解
- 形体感：`map()` 的壳层距离场 + displacement。
- 通透感：`reflect/refract` 采样 cubemap。
- 深度感：AO + softshadow。
- 氛围色：远距离雾化混色与位移场自身颜色插值。

## 4. Unity 复现要点
- `iResolution -> _ScreenParams.xy`
- `iTime -> _Time.y`
- `iMouse` 默认置 0（可后续接入鼠标驱动）
- 必须正确绑定 `_Channel0` (Cubemap) 与 `_Channel1` (Texture2D)
- 分辨率由 `shadertoy-2-capture.resolution.json` 自动驱动
