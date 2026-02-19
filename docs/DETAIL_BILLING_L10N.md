# 详情页 + Billing + 8 语言 l10n 结构说明

## 一、Game 详情页（商业版）

- **文件**：`lib/features/detail/game_detail_page.dart`
- **能力**：多图轮播（SliverAppBar + PageView）、折扣标签、AI 评分、Steam 跳转、分享（带 storeUrl）、加入/移出愿望单、倒计时（saleEndTime / lastChange）
- **入口**：Home / Explore 列表点击 → `GameDetailPage(game: game)`；仅 dealId 时仍走 `DetailPage(appId:)` → DetailScreen
- **依赖**：`core/models/game.dart`（导出 GameModel）、`AlgorithmService`、`WishlistService`、`AppLocalizations.get('add_to_wishlist'|'share'|'view_on_steam')`

## 二、WishlistService

- **文件**：`lib/core/services/wishlist_service.dart`
- **方法**：`add(GameModel)`、`remove(appId)`、`isInWishlist(appId)`、`getWishlist()`，内部委托 `StorageService`

## 三、Google Play Billing 产品 ID

- **当前 ID**（与文档一致）：
  - `pro_week_099` — 7 天 $0.99
  - `pro_month_299` — 月订 $2.99
  - `pro_year_1699` — 年订 $16.99
- **配置**：`lib/core/services/billing_service.dart`；订阅页展示文案见 `subscription_page.dart` 的 `_productLabel`（兼容旧 ID）

## 四、多语言 l10n（8 种）

- **支持语言**：en, zh, ja, ko, fr, ru, de, es
- **实现**：`lib/l10n/app_localizations.dart`（手动 Map + `get(key)`），`supportedLocales` 与 `isSupported` 已包含 ru / es
- **arb**：`lib/l10n/app_*.arb`（en, zh, ja, ko, fr, ru, de, es），含 home / explore / wishlist / add_to_wishlist / share / upgrade_to_pro 等
- **跟随系统**：`MaterialApp` 未写死 `locale`，即跟随系统语言

## 五、分享与 Deep Link

- **分享文案**：`Check this deal: ${game.name} 🔥\n$price\n$storeUrl`（storeUrl = Steam 商店链接）
- **Deep Link**：项目已使用 `app_links`；若需「打开 app 并跳转详情」，在路由中解析 `uri.queryParameters['id']` 后 `Navigator.push(GameDetailPage(game: game))` 或 `DetailPage(appId: id)` 即可
