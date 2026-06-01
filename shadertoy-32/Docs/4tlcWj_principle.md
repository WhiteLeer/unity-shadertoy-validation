# 4tlcWj (Subsurface Scattering Demo) 原理解析

## 1. 效果类型
- 这是一个 SSS（Subsurface Scattering，次表面散射）演示。
- 主体形体由 SDF 过程函数生成，不依赖模型。
- 重点不是复杂材质贴图，而是演示“厚度估计 + 透光光照”的近似做法。

## 2. Pass 结构
- Buffer A：原版是 UI 控件和参数缓存。
- Buffer B：raymarch 场景，输出 GBuffer。
- Buffer C：读取 GBuffer，根据局部厚度做 SSS 光照。
- Image：gamma、暗角和 UI 合成。

Unity 版当前保留真实渲染链路：`BufferA -> BufferB -> BufferC -> Image`。为避免 previz 占位图，Buffer A 先写入默认参数，不依赖 `/media/previz/buffer*.png`。

## 3. Buffer B 的 GBuffer
- R：归一化深度。
- G：局部厚度。
- B：表面 ID，区分主体和发光球。
- A：八面体压缩后的法线。

法线使用 octahedron packing，Unity 版使用 `ARGBFloat` 保存该 buffer，避免 packed normal 在半精度 RT 中丢精度。

## 4. 局部厚度的核心
原理是从表面点沿反法线半球方向做多次随机采样：

1. 先 raymarch 命中 SDF 表面。
2. 计算表面法线。
3. 以 `-normal` 为半球方向生成随机采样向量。
4. 在物体内部附近采样 SDF。
5. 累加 `sampleLength + Scene(samplePos)` 得到局部厚度近似。

厚度越小，表示光更容易穿透，SSS 越亮；厚度越大，表示内部吸收更强。

## 5. SSS 光照
- 非 SSS 模式：普通点光源漫反射。
- SSS 模式：用视线方向、灯光方向、法线扰动和厚度共同决定透光强度。
- `Ambient` 控制基础透光。
- `Distortion` 控制光线绕过表面的程度。
- `Power` 控制透光热点锐度。
- `Scale` 控制整体透光强度。
- `Light Color` 控制透光颜色。

## 6. Unity 迁移注意
- Buffer A 原版包含大量 UI 字符绘制宏；当前 Unity 版先用默认参数缓存替代 UI 交互，主体 SSS 链路完整保留。
- Buffer B 必须用 `ARGBFloat`，否则 packed normal 会丢失。
- Buffer B/C 使用点采样，避免 GBuffer 被线性过滤破坏深度、ID、packed normal。
- ShaderToy 的 previz buffer 只是内部 pass 预览图，不能作为真实输入贴图。
