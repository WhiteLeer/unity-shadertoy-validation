# 7sscW4 (More Fractal Ropes) 原理解析

## 1. 效果类型
- 这是一个 **两 pass（Common + Image）** 的程序化 raymarch 效果。
- 主要视觉是分形绳状体 + 环境反射，不依赖模型网格。

## 2. 主体流程
1. 在 `Common` 中定义公用函数与几何距离场逻辑。
2. `Image` pass 根据屏幕坐标构建射线，执行空间步进（raymarch）。
3. 命中后通过法线近似、反射向量与环境贴图采样组合出主体色彩。
4. 使用时间变量驱动相机/形体参数，形成动态流动的立体效果。
5. 最后做 gamma 处理输出。

## 3. 关键公式直觉
- `GetDist`：定义“绳状分形结构”的距离场，是形体来源。
- `RayMarch`：沿视线累计前进，直到命中表面或超出最大距离。
- `GetNormal`：用邻域差分估算法线，提供光照与反射方向。
- `texture(iChannel0, reflectDir)`：用 cubemap 提供材质与空间氛围。

## 4. Unity 对应
- `iResolution -> _ScreenParams.xy`
- `iTime -> _Time.y`
- `iMouse -> _Mouse`
- `iChannel0 -> _Channel0 (Cubemap)`

## 5. 说明
- 本效果在 Unity 中为纯 shader 计算，不使用模型几何细节。
- 构图一致性主要依赖分辨率与全屏铺满策略，已由 capture 分辨率驱动。
