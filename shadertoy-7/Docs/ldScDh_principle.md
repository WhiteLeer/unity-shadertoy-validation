# ldScDh (Greek Temple) 原理解析

## 1. 效果类型
- 这是一个 **两阶段多 pass** 的 Shadertoy 场景：`Buffer A -> Image`。
- `Buffer A` 负责完整场景的 SDF 光线步进与着色，`Image` 负责最终取样与暗角后处理。

## 2. 主体流程
1. `Buffer A` 中构建 temple/terrain 的距离场（SDF），执行主光线步进得到命中点与材质。
2. 计算法线、阴影、AO、天空与雾化，并把结果写入 buffer 纹理。
3. `Image` pass 只做一层屏幕读取（`iChannel0`）与 vignette（暗角）调制输出。
4. 输入纹理（噪声/地形贴图）在 `Buffer A` 中参与地形细节与材质变化。

## 3. 关键公式直觉
- `texelFetch(iChannel0, p, 0)`：Image pass 逐像素取 Buffer A 结果。
- `16*q.x*q.y*(1-q.x)*(1-q.y)`：经典屏幕边缘衰减核，用于暗角。
- `map()/intersect()`：SDF 场定义 + sphere tracing。
- `calcNormal/calcShadow/calcOcclusion`：法线、软阴影、AO 形成体积与空间层次。

## 4. 为什么 Unity 里容易“不像原版”
- 原版核心在 `Buffer A` 的完整 raymarch 逻辑，Image pass 只是最后一层合成。
- 如果只复现 Image 或用静态 buffer 贴图，得到的是“截图级近似”，不是实时完整还原。

## 5. 当前工程状态（shadertoy-7）
- 已按原版 Image pass 逻辑改为：`_Channel0 + vignette`。
- 目前 `channel0` 使用抓取得到的 `buffer00.png`，因此能对齐构图/色调框架，但不是实时 Buffer A 重建。

## 6. 下一步完整还原路径
- 将 `ldScDh_1_buffer.glsl` 逐段翻译为 HLSL（含噪声/SDF/步进/阴影/AO）。
- 在 Unity 中建立 Buffer RT 管线：先渲染 Buffer A 到 RT，再由 Image pass 采样 RT 输出。
- 这样才能达到接近 Shadertoy 的动态与细节一致性。
