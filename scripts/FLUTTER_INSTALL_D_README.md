# Flutter 安装到 D 盘说明

## 目录结构（已创建）

- `D:\development\`  
- `D:\development\flutter\`  ← Flutter SDK 放这里（克隆或解压后应看到 `bin\`、`packages\` 等）

## 方式一：Git 克隆（当前正在执行）

若已在后台执行：

```bat
git -c "url.https://github.com/.insteadOf=https://github.com/" clone --depth 1 https://github.com/flutter/flutter.git -b stable D:\development\flutter
```

- 等待克隆完成（仓库较大，可能需几分钟）。
- 完成后在项目根目录运行：`scripts\use_flutter_d.bat`，再执行 `flutter doctor`。

## 方式二：手动下载（推荐，若克隆过慢或失败）

1. **下载 Stable 压缩包**（任选其一）：
   - 官方（需可访问 Google）：  
     `https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip`  
     或到 <https://docs.flutter.dev/release/archive> 选最新 stable 的 Windows zip。
   - 国内镜像（可先试）：  
     <https://fast-mirror.isrc.ac.cn/flutter/flutter_infra/releases/stable/windows/>  
     进入后下载同名 `flutter_windows_*.*.*-stable.zip`。
2. **解压到 D 盘**：解压到 **`D:\development\`**，使最终路径为：  
   `D:\development\flutter\bin\flutter.bat`（解压后若得到的是带版本号的文件夹，请改名为 `flutter` 或把其内容移到 `D:\development\flutter`）。
3. **使用**：将 `D:\development\flutter\bin` 加入系统 PATH，或每次开发前运行：  
   `e:\steamGame\scripts\use_flutter_d.bat`。

## 使用 D 盘 Flutter 开发本项目

1. 打开新的 CMD 或 PowerShell。
2. 执行（在项目根目录或任意目录均可）：  
   `e:\steamGame\scripts\use_flutter_d.bat`
3. 然后执行：
   - `flutter doctor`
   - `cd /d e:\steamGame`
   - `flutter pub get`
   - `flutter build apk` 或 `flutter run`

## 环境变量（可选，长期使用）

若希望不用每次运行 `use_flutter_d.bat`，可把 D 盘 Flutter 加入系统 PATH：

- 变量名：`Path`
- 追加：`D:\development\flutter\bin`

并设置（若尚未设置）：

- `JAVA_HOME` = `E:\java\jdk-17`
- `ANDROID_HOME` = `D:\Android\Sdk`
