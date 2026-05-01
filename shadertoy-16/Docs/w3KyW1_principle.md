# w3KyW1 (Ocean Water Test) 原理解析

## 1. 效果类型
- 这是一个 Shadertoy 程序化效果（pass 数：3）。
- 作者：foodi
- 目标分辨率：512x288

## 2. 主体流程
1. 以 image/common/buffer pass 结构组织绘制顺序（若存在多 pass 则先算中间结果，再合成最终图像）。
2. 使用分辨率、时间、鼠标与输入通道驱动画面变化。
3. 在片元阶段完成主要视觉计算（距离场/噪声/步进/反射等，以实际代码为准）。
4. 输出阶段做必要的色调与 gamma 处理，得到最终颜色。

## 3. 关键公式直觉
- 坐标归一化与宽高比修正决定构图稳定性。
- 距离场/噪声/步进函数决定形体与体积层次。
- 输入贴图常用于环境细节、扰动或反射，不直接替代主体结构。

## 4. Unity 对应
- iResolution -> _ScreenParams.xy
- iTime -> _Time.y
- iMouse -> _Mouse
- iChannelN -> _ChannelN

## 5. 输入通道
- pass0 channel0: cubemap /media/a/0681c014f6c88c356cf9c0394ffe015acc94ec1474924855f45d22c3e70b5785.png
- pass0 channel1: buffer /media/previz/buffer00.png
- pass2 channel0: buffer /media/previz/buffer00.png

## 6. 说明
- 本文档是统一模板总结，便于快速对齐实现思路。
- 若要做到 1:1 复刻，需要进一步做逐函数级 GLSL->HLSL 对照翻译。
