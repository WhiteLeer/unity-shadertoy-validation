# 7sscW4 (More Fractal Ropes) 原理解析

## 1. 效果类型
- 单 pass 反射材质的 SDF 光线步进。
- 核心造型来自对 xz 平面的迭代折叠+旋转，形成分形“绳索”截面。

## 2. 主要流程
1. `GetDist`：定义场函数（迭代变换后的到截面距离）。
2. `RayMarch`：沿射线步进到表面。
3. `GetNormal`：数值差分法线。
4. 漫反射 + cubemap 反射上色。
5. 调色函数 `pal` 与 gamma 校正。

## 3. 输入
- `iChannel0`：cubemap（反射环境）
- `iMouse`：可用于交互视角（Unity 脚本已注入）

## 4. 备注
- 该 shader 含 common + image 两段，Unity 版已合并。
- 若 cubemap 导入类型不正确，会出现反射颜色偏差。
