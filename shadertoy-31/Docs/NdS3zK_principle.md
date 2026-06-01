# NdS3zK (OCEAN ELEMENTAL) 原理解析

## 1. 效果类型
- 这是一个程序化水元素角色：主体不是模型，而是 SDF 距离场拼出的头、身体、手臂和底部水柱。
- 视觉重点是透明水体材质：折射、环境反射、Beer's law 吸收、相函数散射、波纹扰动和泡沫高光。
- 原始 Shadertoy 使用 4 个 pass：Common、Buffer A、Buffer B、Image。

## 2. Pass 结构
- Common：定义 `PI`、gamma、`dot_c` 等公共函数。
- Buffer A：只写前 4 个像素，用作状态缓存。
- Buffer B：生成水面细节纹理，R 通道是周期 Perlin/FBM 波纹，G 通道是 Worley 噪声，用于错开流动贴图切换。
- Image：读取 Buffer A 的相机位置、Buffer B 的扰动纹理和 cubemap，完成 SDF 光线步进与水体着色。

## 3. Buffer A 做什么
- 第 0 个像素保存鼠标累计旋转。
- 第 1 个像素保存由鼠标角度换算出的相机位置。
- 第 2 个像素保存分辨率变化标记。
- 第 3 个像素保存鼠标按下状态。

Unity 版保留了这个反馈结构，使用双 RenderTexture ping-pong，避免把 `/media/previz/buffer00.png` 当成真实贴图。

## 4. Buffer B 做什么
- 首帧或分辨率变化时重新生成一张无缝噪声图。
- R 通道控制细节高度和流动扰动。
- G 通道控制两个流动采样状态的混合节奏，避免动画从 1 跳回 0 时出现明显跳变。
- 后续帧直接反馈上一帧结果，对应 Shadertoy 的 buffer 输入链。

## 5. 主体形体
- `sphereSDF` 负责圆形体块。
- `sdRoundCone` 负责水柱、肩膀、手臂、拳头这类圆锥/胶囊过渡形体。
- `smoothMin` 把多个 SDF 柔和融合成水体生物。
- `opSmoothSub` 从底部减去一个球形区域，形成展开的水柱底座。
- `opDisplace` 用三角函数扰动距离场，让表面有流动波浪。

## 6. 水体材质
- 进入水体后，通过反向 SDF 步进找到远端交点，估算水内路径长度。
- 使用 `exp(-density * depth * (1 - waterColor))` 做 Beer's law 吸收，路径越长越偏蓝绿、越暗。
- 使用双叶 Henyey-Greenstein 相函数模拟水中颗粒散射。
- 使用 cubemap 提供环境反射/折射来源。
- 使用 Fresnel 在视角掠射处增强反射。

## 7. Unity 迁移注意
- `mat3(xaxis, yaxis, -zaxis)` 在 GLSL 中是列主构造；Unity HLSL 版的 `LookAt` 返回时做了 `transpose` 对齐。
- Buffer A 的状态像素必须用点采样和 clamp。
- Buffer B 作为流动纹理应使用双线性采样和 repeat。
- Image pass 的 `_Channel0/_Channel1/_Channel2` 分别对应 Buffer A、Buffer B、cubemap。

## 8. 可调参数
- 角色大小：主要调 `CAMERA_DIST`、`MAX_DIST` 和各个 `sphereSDF/sdRoundCone` 半径。
- 水波强度：调 `DETAIL_HEIGHT`、`opDisplace` 的振幅和 `getDistortedTexture` 里的 `strength`。
- 透明度/浑浊度：调 `CLARITY`、`DENSITY`、`waterColour`。
- 反射强度：调 `F0`、roughness、Fresnel 混合。
- 太阳方向：调 `sunLocation` 和 `sunHeight`。
