# 43cBzn Grid Attractor 原理

## 效果定位
这是一个单通道、纯程序化的全屏 SDF 光线步进效果。原始 Shadertoy 只有 Image pass，没有模型、贴图、Buffer 或外部输入；画面中的网格、吸引子运动和红白材质全部由每个像素独立计算。

## 结构
1. scene(p)：把空间折叠到重复的 XZ 网格单元，在每个单元中用 hash 生成轻微的竖直摆动，再与一个随时间运动的球体做最小距离合并。
2. raymarch(ro, rd, side)：沿视线累加 SDF 距离。除了一般的最小距离终止，还用到网格单元边界的步长限制，避免跨过重复结构。
3. getNormal(p)：用中心差分估计 SDF 梯度，得到法线。
4. mainImage：按屏幕坐标建立相机射线，采样距离场，依据法线方向给出红色和白色的分段着色，最后做 gamma 校正。

## 可调参数
- rep = .04：重复网格的单元间距。减小会得到更密的网格。
- sdBox(q, float3(rep*.5, .1, rep*.5))：每个柱状单元的半径和高度。
- sdSphere(p, .075)：运动球体的半径。
- spo：球体随时间的正弦运动，改这里可以控制摆动方向和速度。
- for(int i = 0; i < 128; i++)：光线步进上限；提高质量但增加像素成本。
- ro、ta、getRayDir：相机位置、目标点和射线投影。
- 法线着色中的 dot(n, ...) 分支：决定红白色块的方向分布。

## GLSL 到 Unity HLSL
- vec2/3/4、mat2/3 已转换为 float2/3/4、float2x2/3x3。
- fract 转为 frac；mod 使用显式的 floor 语义辅助函数 st_mod，避免 HLSL % 的整数语义。
- GLSL 的标量向量构造器已展开为合法的 HLSL 多参数构造，避免 D3D11 的 numeric-type constructor 报错。
- 保留原始 XY 轴、相机射线和 Y 方向，不额外翻转坐标。
- 射线循环加了 [loop]，避免 D3D11 对 128 次循环做不必要的过度展开。

## Unity 验收
打开 Scenes/shadertoy-27-43cBzn.unity。Bootstrap 会创建全屏 Quad、设置 _STResolution、时间和帧参数，并使用抓取到的 960x540 分辨率作为默认运行尺寸。
