# Steam Deals App — 文档

## 打包（所有下载与缓存使用 D 盘）

项目已配置 **D 盘环境**，打包时请用以下方式，确保 Flutter、Pub、Gradle、Android SDK 的下载与缓存都在 D 盘：

| 操作 | 命令（PowerShell 在项目根目录执行） |
|------|-----------------------------------|
| 仅打包 APK | `.\build-with-d.ps1` 或 `.\build-with-d.ps1 build apk` |
| 打包并安装到手机 | `.\build-and-install-with-d.ps1` |

D 盘路径约定：

- **Flutter SDK**: `D:\development\flutter`
- **Pub 缓存**: `D:\dev-config\pub`
- **Gradle**: `D:\dev-config\gradle`
- **Android SDK**: `D:\Android\Sdk`

---

## 架构与最终形态

- **[ARCHITECTURE_FINAL.md](./ARCHITECTURE_FINAL.md)** — 全局系统架构、页面结构、数据流、权限与订阅、算法、登录与多语言、通知与分享、广告与盈利、目录结构、视觉系统与最终产品形态总结。

## 待补全清单

- **[TODO_CHECKLIST.md](./TODO_CHECKLIST.md)** — 尚未实现或可优化的功能与结构、上线前必做、建议实现顺序。

## 快速对照

| 模块       | 文档章节     | 代码位置 |
|------------|--------------|----------|
| 数据流     | 三           | main.dart, CacheService, ApiService, features/home、explore |
| 权限       | 四           | core/access_control.dart, core/storage_service (isPro) |
| 算法       | 五           | core/utils/score_calculator.dart, core/shock_deal_algorithm.dart |
| 多语言     | 六           | l10n/app_localizations.dart, app_*.arb |
| 通知/分享  | 七           | core/notification_service, core/background_task, share_plus, app_links |
| 广告       | 八           | core/interstitial_helper, widgets/ad_banner |
| 视觉       | 十           | core/theme/colors.dart (含 backgroundDark, cardDark) |
