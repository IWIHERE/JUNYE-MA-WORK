# Moon or Coin? — sound edition

52685 Creative Coding · Processing 4 / Java Mode

## 打开 / Run

解压整个压缩包，打开 `MoonOrCoin/MoonOrCoin.pde` 后运行。
请保留同目录的 `MoonSound.java` 和 `data/audio` 文件夹。
无需安装 Sound 库，也不需要 Python；播放使用 Java 自带的音频功能。

Extract the complete folder and open `MoonOrCoin.pde` in Processing 4 Java Mode.
Keep `MoonSound.java` and `data/audio` alongside it. No additional Processing library is required.

## 操作 / Controls

| 按键 / Input | 功能 / Action |
| --- | --- |
| Click / Space / Enter | 投掷；结果结束后倒放；复原后可再次投掷 / Toss, rewind, repeat |
| M / C | 首次投掷可指定 Moon / Coin，之后同样交替 / Choose the first ending; subsequent tosses alternate |

首次正常投掷以 50% 概率决定 Moon 或 Coin；从第二次开始，每次新投掷必定与上一次相反。
倒放保持当前结果，不算新投掷；动画过程中的重复输入不改变结果。重新运行程序后重新决定首次结果。

The first normal toss is random (50/50). Every subsequent toss switches to the opposite
outcome. Rewind preserves the current result, and input during animation is ignored.
Restarting the sketch starts a new sequence. Results are no longer independent random draws.

固定总音量为 75%，素材本身已做低音量混音，无静音键或音量快捷键。
水声会在启动后柔和进入；关闭窗口时释放音频设备。

## 声音设计 / Sound design

落水声采用 engreitz 的真实硬币入水录音片段，其余四个声音仍是为作品制作的合成音效。
录音来源、修改方式和 CC Sampling+ 1.0 授权见 `AUDIO_CREDITS.md`，分享时请保留署名。
整体克制、低声、带空间感，没有背景旋律或胜利提示音。

| 文件 / File | 对应画面 / Cue |
| --- | --- |
| water.wav | 16 秒连续循环的低声水流 / Seamless quiet water bed |
| toss.wav | 1.65 秒：轻微金属起音与柔和空气流动 / Soft metal release and air |
| impact.wav | 0.62 秒：真实硬币入水录音片段，轻微滤波与音量匹配 / Recorded coin entering water |
| moon.wav | 5.20 秒：水声尾音逐渐融入微弱共鸣 / Water tail and subtle open resonance |
| coin.wav | 5.20 秒：与下沉气泡阶段对应的低声水泡 / Submerged bubbles and low turbulence |

音效由原有状态转换触发，不在每一帧重新播放。倒放时直接反向读取对应音频的立体声帧：
结局 → 入水 → 抛出。背景水声一直正向流动，与持续向右的水线对应。
每轮结束只保留环境声。

Audio is triggered by the existing scene transitions. Rewind reads the exact same
stereo frames backwards, preserving channel order. The ambient bed keeps moving forward.
The audio worker is separate from the drawing thread and joins the current cue if startup is delayed.
Missing assets or unavailable audio output print a console message; the visual sketch continues.

## 修改范围 / Scope

保留所有绘图函数、动画时长、构图、字体、音效和倒放流程。
结果规则改为首次随机、之后交替；M / C 也不能绕过首次投掷后的不重复规则。
只包含 52685 的投掷循环，不含 52717 的人物、采访或书本章节。

## 本次不重复规则验证 / No-repeat update validation

- 从修改后的 PDE 提取状态函数，进行 JavaScript 语法转换后运行 200 轮正放／倒放状态测试，覆盖首次两种结果、忙碌时重复输入及 M / C 输入。
- 检查相邻新投掷不重复，倒放保持结果，音频状态通知使用同一结果。
- 本次未运行完整 Processing 图形窗口；下列编译和音频检查记录来自此前音效版。

## 原音效版验证 / Previous sound-edition validation

- 使用 Processing 4.3.1 core 和 Java 17 完成 Java 编译检查；PDE 通过机械转换为 Java 检查。
- 无窗口状态测试覆盖 Moon 和 Coin 各五次完整正放、倒放和重复投掷。
- 检查全部 WAV 可读取、时长、峰值余量、循环接缝，以及反转时左右声道不交换。
- 检查忙碌时重复点击不会重触发及缺失素材时的降级。
- 本次仅替换入水音效，其他四个 WAV 保持字节一致；反向入水声同步更新。
- 当前验证环境没有实际扬声器试听和完整 Processing 图形窗口运行；最终听感及设备延迟请在本机确认。

Compilation and headless state/audio-data checks passed. This is not a claim of
speaker listening tests or an end-to-end graphical Processing run on your computer.

## 素材可重建 / Rebuilding the sounds

`tools/make_audio.py` contains the synthesis source with fixed random seed 52685
and the processing steps for the bundled recorded coin excerpt.
To regenerate: Python 3 with NumPy and SciPy, then run `python tools/make_audio.py`.
It recreates the five WAVs, a `Sound_Preview.wav` listening sequence,
and an isolated `Impact_Preview.wav` with three repetitions.
The preview plays Moon forward/reverse followed by Coin forward/reverse.
These synthesis dependencies are unnecessary for playing the artwork.

Audio playback API: https://docs.oracle.com/en/java/javase/17/docs/api/java.desktop/javax/sound/sampled/SourceDataLine.html
