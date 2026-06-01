# ttXSzl (simple npr experiments) 原理解析

## 1. 结构总览
- Pass A (`Buffer A`)：程序化光线求交，写入 `normal + id/shadow` 编码。
- Pass B (`Image`)：读取 Buffer A，做邻域比较得到轮廓，再按规则做 NPR 明暗与网点化。

## 2. Buffer A 在做什么
1. 相机绕场景旋转，构造射线 `Ray(o,d)`。
2. 对 3x3x3 的体素阵列依次求交：
- 球体 (`intersectSphere`)
- 圆柱 (`intersectCylinder`)
- 立方体 (`intersectCube`)
3. 再与地面平面求交，取最近命中。
4. 从点光源方向再次投射阴影射线，得到 `inShadow`。
5. 输出编码：
- `rgb = normal`
- `a = objectId + fract(diffuse)`

## 3. Image 在做什么
1. 取当前像素和右/上/右上邻域 4 点。
2. 若 `id` 不一致或法线变化过大，则判定为边线（黑线）。
3. 若为内部区域：
- 用 `objectId` 生成离散底色。
- 用 `diffuse` 控制明暗分层。
- 按时间在 6 种 NPR 模式轮播（普通、轮廓、二值明暗、栅格阴影等）。

## 4. Unity 对应实现
- Shader: `Shadertoy/ttXSzl_BufferA` + `Shadertoy/ttXSzl_Image`
- Bootstrap: `ShadertoyttXSzl_v14Bootstrap.cs`
- 渲染链：`Graphics.Blit(null -> BufferA RT) -> _Channel0 -> Image`
- 分辨率：从 `shadertoy-14-capture.resolution.json` 自动读取 `512x288`

## 5. 可调参数建议
- 转速：`BufferA` 的 `ww`。
- 物体大小：各求交函数半径/半长 (`0.45`)。
- 轮廓强度：Image 中 `noLine` 判据阈值（`dot` 和 `0.1`）。
- 栅格颗粒：`rasterSize`。
