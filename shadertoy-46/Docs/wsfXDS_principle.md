# wsfXDS ([TWITCH] Sous l'ocean) 原理解析

## 1. 效果类型
- 单 `Image` pass，纯程序化。
- 画面由 Voronoi 线网、遮罩和旋转切分组合成海底插画感图案。

## 2. 主体流程
1. `voro()` 生成动态 Voronoi 细胞边界。
2. `blue/green/red/magenta_grid()` 用不同配色包装同一套 Voronoi 线网。
3. `ground/seaweed/sun/sky` 用一组几何遮罩拆分画面元素。
4. 最后把这些分层相加，组成完整海底构图。

## 3. 关键直觉
- 主要不是 raymarch，而是“程序化平面设计”。
- Voronoi 决定内部纹理，mask 决定大形体轮廓。
- 海草和太阳的动态来自时间驱动的正弦位移和旋转。

## 4. Unity 对应
- `iResolution -> _STResolution.xy`
- `iTime -> _STTime`
