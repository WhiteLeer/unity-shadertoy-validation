# wc23Wc Grok [111] 原理

## 效果定位
这是一个极短的纯数学 Image shader。它没有模型、贴图、Buffer 或外部输入，只对当前像素坐标做归一化和距离计算。

## 核心公式
1. 将像素坐标 I 映射到以屏幕中心为原点的坐标 p，并用屏幕高度 r.y 保持纵横比例。
2. length(p) - 0.5 形成一个圆形距离边界。
3. p.xxxx - p.y 将二维坐标的 y 分量广播到四个通道，构成四个分母分量。
4. 0.01 除以这个分母会在 x 接近 y 的对角线附近产生高亮/尖锐结构。
5. 再对整体取绝对值并用 0.1 除，得到高亮的环状与对角线组合。

## 可调参数
- 0.5：圆形边界半径。
- 0.01：对角线奇异项的强度和宽度。
- 0.1：整体亮度缩放。
- r.y：坐标归一化基准；改为 min(r.x, r.y) 会改变非 1:1 画布上的形状比例。

## GLSL 到 Unity HLSL
- vec2/vec4 已转换为 float2/float4。
- GLSL 的 p.y 隐式广播改成显式 float4(p.y, p.y, p.y, p.y)，避免 D3D11 numeric-type constructor 错误。
- iResolution 改为 _STResolution，保留原始 XY 坐标方向，不翻转 Y。
- ShaderLab 使用 ForwardUnlit，并追加项目统一的 DepthOnly pass。
