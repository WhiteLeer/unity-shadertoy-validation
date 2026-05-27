# 4dXGR4 (Main Sequence Star) 原理解析

## 1. 效果类型
- 单 pass 全屏程序化恒星效果。
- 结合噪声分形、纹理流动、音频驱动亮度，形成“活动日冕 + 星表扰动”。

## 2. 核心结构
1. 从音频通道抽取四段频率能量（freqs）。
2. 用能量调节恒星半径与亮度。
3. 在极坐标空间做多层噪声叠加，构建日冕（corona）细节。
4. 在球面投影坐标上采样纹理并沿时间偏移，构成星表运动。
5. 叠加外围 glow 与暖色调，输出最终颜色。

## 3. 视觉要点
- `snoise + 多频叠加` 决定火焰边界和扰动感。
- `brightness` 由音频驱动，直接影响半径与能量。
- `channel0` 纹理提供星表细节，不是纯噪声云团。

## 4. Unity 对应
- `iResolution -> _ScreenParams.xy`
- `iTime -> _Time.y`
- `iChannel0 -> _Channel0 (Texture2D)`
- `iChannel1 -> _Channel1 (运行时生成音频谱纹理)`

## 5. 说明
- Shadertoy 原版 `iChannel1` 来自音乐分析纹理；Unity 版使用 `AudioSource.GetSpectrumData` 实时生成近似输入。
- 如果不播放音频，会自动退化到时变合成谱，确保效果可运行。
