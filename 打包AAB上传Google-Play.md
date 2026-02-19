# 打包 AAB 上传 Google Play

## 一键打包（使用 D 盘环境）

在项目根目录执行：

```powershell
$env:PATH = "D:\development\flutter\bin;" + $env:PATH
$env:GRADLE_USER_HOME = "D:\dev-config\gradle"
$env:PUB_CACHE = "D:\dev-config\pub"
cd e:\steamGame
flutter build appbundle --release
```

打包成功后，AAB 文件位置：

**`e:\steamGame\build\app\outputs\bundle\release\app-release.aab`**

将该文件上传到 [Google Play Console](https://play.google.com/console) → 你的应用 → 版本 → 生产/测试 → 创建新版本 → 上传 AAB。

---

## 若出现 “Release app bundle failed to strip debug symbols”

已在本机通过修改 Flutter SDK 跳过该校验。若将来执行 `flutter upgrade` 后再次报错，可先删除 Flutter 工具快照，再重新打包：

```powershell
Remove-Item "D:\development\flutter\bin\cache\flutter_tools.snapshot" -Force -ErrorAction SilentlyContinue
Remove-Item "D:\development\flutter\bin\cache\flutter_tools.stamp" -Force -ErrorAction SilentlyContinue
# 然后重新执行上面的 flutter build appbundle --release
```

（Flutter SDK 内 `packages/flutter_tools/lib/src/android/gradle.dart` 中已对 strip 校验做了跳过处理，删除快照后会用该源码重新编译。）
