# XdB3DG (Anisotropic Highlights) 原理解析

## 1. 效果类型
- 单 `Image` pass。
- 用 raymarch 渲染一个超二次体，并在表面叠加各向异性高光。

## 2. 主体流程
1. 通过距离场 `DistanceField()` 定义物体形状。
2. `Trace()` 沿视线步进找到表面交点。
3. `Normal()` 用距离场梯度求法线。
4. `Shade()` 构造一个切线方向噪声，模拟拉丝/纤维方向，再做各向异性 specular。
5. 最后叠加天空反射、镜头 flare、暗角和胶片颗粒。

## 3. 关键直觉
- 普通高光只看法线和半角向量夹角。
- 这里额外引入 `aniso` 方向，只有半角向量与拉丝方向关系合适时，高光才会被拉长并变亮。
- 所以视觉重点不是几何本身，而是“表面微结构方向性”。

## 4. Unity 对应
- `iResolution -> _STResolution.xy`
- `iTime -> _STTime`
- `iMouse -> _STMouse`
- `iChannel0 -> _Channel0` 噪声/胶片颗粒
- `iChannel1 -> _Channel1` dirt / flare 贴图
