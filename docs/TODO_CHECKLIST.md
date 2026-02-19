# 待补全与优化清单

对照 `ARCHITECTURE_FINAL.md` 与当前实现，以下项尚未完成或可优化。

---

## 一、功能未实现

| 序号 | 项 | 说明 | 优先级 |
|-----|---|------|--------|
| 1 | **登录（Google Sign-In）** | ✅ 已实现：`AuthService`（client_id 来自 google秘钥）、Profile 登录/登出与用户信息、Wishlist 未登录时展示 LoginGate。Android 需在 Google Cloud Console 为应用包名 + SHA-1 创建 OAuth 客户端。 | - |
| 2 | **愿望单数量限制（Free）** | 文档：`canAddWishlist(count)`，Free 用户最多 5 个。当前未限制。需在 `AccessControl` 增加 `canAddWishlist(count)`，在加愿望单前校验并引导订阅。 | 中 |
| 3 | **DeepLink 游戏详情** | 文档：`yourapp://game/{id}` 打开 App 直接进详情。当前仅处理了 `ref` 拉新。需在 AndroidManifest 增加 scheme、在 app 内解析 path 跳转 DetailPage。 | 中 |
| 4 | **Explore FilterBar** | 文档：Explore 含 SearchBar + FilterBar + ResultList。当前无 FilterBar（如按标签、价格筛选）。可按需加简单筛选栏。 | 低 |

---

## 二、模块/结构对齐（可选重构）

| 序号 | 项 | 说明 |
|-----|---|------|
| 5 | **algorithm_service.dart** | 文档期望统一入口。当前为 `score_calculator.dart` + `shock_deal_algorithm.dart`。可新增 `algorithm_service.dart` 封装 calculateScore / sortGames / 分类，内部调现有实现。 |
| 6 | **ad_service.dart** | 文档：集中「if (!AccessControl.canRemoveAds()) loadBanner()」。当前逻辑在 InterstitialHelper 与各页。可抽成 ad_service 统一判断与加载。 |
| 7 | **share_service.dart** | 文档：独立 share_service。当前分享在 Profile 内。可抽成 ShareService.shareApp() / shareGame(game)。 |
| 8 | **目录结构** | 文档目标：`services/`、`storage/`、`utils/`、`pages/`。当前为 `core/`、`data/`、`features/`、`screens/`。可按迭代逐步重命名/迁移，非必须。 |

---

## 三、视觉与主题

| 序号 | 项 | 说明 |
|-----|---|------|
| 9 | **深色主题切换** | 文档锁定背景 `#0B141B`、卡片 `#152533`。已加 `AppColors.backgroundDark` / `cardDark`，当前 App 仍用浅色。可做主题切换或默认改为深色。 |
| 10 | **字体层级** | 文档：Hero 24 / 模块标题 20 / 卡片 16 / 标签 12。当前 theme 已部分统一，可全局检查替换。 |

---

## 四、多语言

| 序号 | 项 | 说明 |
|-----|---|------|
| 11 | **硬编码文案替换** | Onboarding、Explore 区块标题、部分按钮仍为英文硬编码。可改为 `l10n.get('key')` 或 ARB。 |
| 12 | **localeResolutionCallback** | 文档：显式 `localeResolutionCallback: (locale, supported) => locale`。当前依赖默认行为，可显式写一遍保证跟随系统。 |

---

## 五、上线前必做

| 序号 | 项 | 说明 |
|-----|---|------|
| 13 | **Google Play 订阅商品** | 在 Play Console 创建订阅商品，ID 与代码一致：`steam_pro_month`、`steam_pro_year`。 |
| 14 | **正式广告位** | 当前为测试 ID（`ca-app-pub-3940256099942544/...`）。上线前在 AdMob 创建正式 Banner/插屏并替换 `ad_banner.dart` 与插屏调用处。 |
| 15 | **DeepLink 正式域名** | 分享链接当前为 `https://steamdeals.app/invite?ref=xxx`。若用自有域名，需配置 App Links / Associated Domains 与后端校验。 |

---

## 六、体验与稳定性

| 序号 | 项 | 说明 |
|-----|---|------|
| 16 | **订阅页无产品时的提示** | 若 Google Play 未配置或网络异常，`loadProducts()` 为空。可加「暂不可用，请稍后再试」或重试按钮。 |
| 17 | **首次启动超时** | `FirstLaunchWrapper` 若 `isFirstLaunch()` 异常会走 catch 显示引导。可加 2 秒超时兜底，避免永远 loading。 |
| 18 | **通知点击跳转** | 当前点击通知用 `pushNamedAndRemoveUntil('/main', ...)`，若路由未注册可能异常。确认实际路由名与 DetailScreen 跳转一致。 |

---

## 七、建议实现顺序

1. **上线必做**：13（订阅商品）、14（正式广告）、15（DeepLink 域名若需要）。
2. **体验**：16（订阅空状态）、17（首启超时）。
3. **权限与变现**：2（愿望单 5 条限制）、9（深色主题可选）。
4. **功能扩展**：1（登录）、3（DeepLink 详情）。
5. **结构与多语言**：5–8（服务封装）、11（文案 l10n）。

完成一项可在本文件中打勾或删行，便于跟踪进度。
