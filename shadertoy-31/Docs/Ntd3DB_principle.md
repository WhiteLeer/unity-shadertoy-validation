# Ntd3DB black holes - acid 原理

## 效果目标

这个效果是一个屏幕空间的抽象视觉实验。它把归一化屏幕坐标不断进行旋转、缩放和非线性扭曲，然后在多个尺度上重复绘制圆形图案，并用 RGB 三个通道的微小偏移制造色差。

## 核心结构

1. **坐标归一化**
   - 使用 min(iResolution.x, iResolution.y) 归一化，保证图案在不同宽高比下保持一致。
   - 先做时间驱动的旋转和缩放，再用 sin、cos、length、log 组合出非线性坐标场。

2. **周期图案**
   - getColorComponent 将坐标用 modScale 周期重复。
   - 距离中心的长度经过 smoothstep，得到柔和的圆形图案。
   - angle 虽然被计算，但当前版本没有参与最终颜色，这是原始源码的保留逻辑。

3. **迭代与景深感**
   - 每次迭代都把坐标扩大 1.1 倍并再次旋转。
   - luma 每轮乘 0.8，blur 每轮乘 0.63，后续图层更暗、更锐利。
   - 颜色累积到 1 后提前退出，控制最多 20 层的成本。

4. **色差**
   - 红色采样使用 center - st * 0.02。
   - 绿色使用未偏移的 center。
   - 蓝色使用 center + st * 0.02。
   - 这类 RGB 空间错位会产生类似镜头色差和酸性霓虹边缘的效果。

## GLSL 到 HLSL 的移植要点

- vec2、vec3、vec4、mat2 显式转换为 float2、float3、float4、float2x2。
- GLSL 的 vec2 * mat2 使用 HLSL mul，保持原始行向量乘法方向。
- GLSL mod 转为 floor 语义的 ST_Mod。
- GLSL atan(x,y) 双参数形式转为 HLSL atan2(x,y)，保持参数顺序。
- GLSL 向量相等判断转为 HLSL all。
- 浮点 20 次循环改为明确的整数循环，并用 iteration 恢复原始浮点 i 值。
- 保留原始 Y 轴方向，不额外翻转。
- ShaderLab 保留 ForwardUnlit 和统一的 DepthOnly pass。

## 可调参数

- ST_CHROMATIC_ABERRATION：RGB 色差强度。
- ST_ITERATIONS：最大迭代层数。
- ST_INITIAL_LUMA：初始亮度。
- 1.1：每层坐标放大倍数。
- 0.63：每层 blur 衰减。
- 时间系数：控制旋转、缩放和中心偏移速度。

## 限制

这是纯逐像素效果，不产生真实几何、碰撞或深度结构。质量主要取决于迭代次数、屏幕分辨率和 Shader ALU 成本。
