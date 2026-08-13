# XdyXz3 Noise Holes 原理

## 效果目标

这个效果把屏幕看成一张彩色纸面，并用程序噪声生成类似地形等高线的凹洞。每个像素都独立计算，不需要模型，也不需要实际的几何位移。

## 核心结构

1. **Ashima 3D simplex noise**
   - mod289、permute、taylorInvSqrt 和 snoise 构成无贴图的 3D simplex noise。
   - getNoise 叠加两层频率：基础频率 2.0，细节频率 6.0，第二层权重为 0.2。
   - 时间只作用于噪声输入，使洞的形状缓慢变化。

2. **阈值切洞**
   - CUTOFF = 0.65。
   - 噪声低于阈值时输出白色，形成纸张切口的内壁。
   - 高于阈值时将剩余范围量化为 ST_STEPS = 8 层，得到明显的分层深度。

3. **颜色与深度**
   - 深度值映射到 HSV 色相，形成彩色纸层。
   - 深度越深，亮度越低。
   - 当前像素与偏移位置 OFFSET = (0.004, 0.004) 的深度差用于模拟洞口边缘的 bevel/drop shadow。

4. **后处理**
   - 按屏幕 Y 坐标乘以 0.7 .. 1.0 的垂直渐变。
   - 原始代码最后还读取 iChannel0 作为微弱噪声纹理；当前页面没有绑定该输入，所以 Unity 端按真实状态使用 0.0，不会伪造贴图。

## 可调参数

- ST_STEPS：纸层数量，越大越细。
- ST_CUTOFF：洞的覆盖比例，越高则白色内壁区域越多。
- ST_OFFSET：边缘阴影采样偏移，影响 bevel 宽度与方向。
- SCALE：两层噪声频率，影响洞的尺度与细节。
- t = _STTime * 0.3：动画速度。

## GLSL 到 HLSL 的移植要点

- vec2/vec3/vec4 显式转换为 float2/float3/float4。
- fract 转为 frac，mix 转为 lerp。
- 保留 GLSL 的屏幕坐标定义：fragCoord / iResolution.x，不额外翻转 Y。
- 所有单参数向量构造改为显式分量，避免 D3D11 numeric-type constructor 报错。
- iResolution/iTime/iMouse 映射到 _STResolution/_STTime/_STMouse。
- iChannel0 未绑定，因此其最后的纹理贡献被安全地替换为黑色采样值。
- ShaderLab 同时保留 ForwardUnlit 和项目统一的 DepthOnly pass。

## 限制

这是逐像素的程序纹理效果，不会产生真实几何洞口、碰撞或阴影。若需要和场景物体交互，应把它作为屏幕后处理或材质效果，再由 C# 或 VFX 系统提供交互参数。
