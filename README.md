# MiniCam (macOS Mini 相机应用)

一个专为 macOS 设计的原生轻巧 **Mini 悬浮相机应用**，支持实时预览、拍照、高清视频录制、分辨率切换与窗口置顶。

## ✨ 特性一览

- 📸 **照片拍摄**：高画质抓拍，自带快门闪光动效与快门声音。
- 🎥 **视频录制**：支持音视频同步录制，带录制计时与呼吸边框提示，保存为 MP4/MOV。
- ⚙️ **分辨率切换**：支持 **4K (2160p)**、**1080p (FHD)**、**720p (HD)**、**480p (SD)** 及 Auto High 多档分辨率无缝切换。
- 🪟 **Mini 悬浮视窗**：
  - 支持 **窗口置顶 (Always on Top)**，适合做推流/网课/录屏画中画。
  - 无边框圆角沉浸式设计，支持窗口全区域随心拖动。
  - 鼠标移出自动淡出控制条，移入自动显示。
- 🔄 **镜像翻转**：支持一键画面水平镜像翻转（支持自拍视角与正常视角切换）。
- 🎙️ **多设备热插拔**：支持内置摄像头、外接 USB 摄像头、内置与外接麦克风热切换。
- 🖼️ **图库直达**：快速预览最近拍摄的缩略图，一键在访达 (Finder) 中打开 `~/Pictures/MiniCam` 与 `~/Movies/MiniCam`。
- 🎨 **精美 Logo**：内置专属 macOS 现代金属质感镜头 App 图标。

## ⌨️ 快捷键

- `⌘ + S`：拍照 (Take Photo)
- `⌘ + R`：开始/停止录制视频 (Toggle Recording)

## 🛠️ 打包与构建

在项目根目录下直接运行打包脚本：

```bash
cd /Users/jackson-hao/code/MiniCam
./scripts/build.sh
```

构建成功后，将在 `build/MiniCam.app` 生成独立的 `.app` 应用程序包。

## 🚀 运行

通过命令行启动：
```bash
open /Users/jackson-hao/code/MiniCam/build/MiniCam.app
```
或者在 Finder 中双击 `build/MiniCam.app`，亦可直接将其拖入 `/Applications` 文件夹常驻使用。
