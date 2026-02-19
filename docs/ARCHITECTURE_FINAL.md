# Steam Deals App — 最终形态架构文档

## 一、全局系统架构图（逻辑层）

```
                ┌─────────────────────┐
                │      Steam API      │
                └──────────┬──────────┘
                           ↓
                    ApiService
                           ↓
                    LocalCache(DB)
                           ↓
                   AlgorithmService
                           ↓
                    UI State Layer
                           ↓
                     Flutter Pages
```

**核心原则：**
- UI 不直接调用 API
- 所有数据必须先进入缓存
- 所有排序在本地完成
- 所有权限统一由 AccessControl 控制

---

## 二、完整页面结构图（最终稳定，防白屏）

**唯一根：MainPage（IndexedStack + 4 Tab）**

```
MainPage (根，从不替换)
 ├── Home
 ├── Explore
 ├── Wishlist
 └── Profile
        └── Navigator.push → SubscriptionPage  （仅此一层跳转）
        └── 首日 Navigator.push → OnboardingPage → 结束 pop，可选再 push(SubscriptionPage)
```

- **禁止**：pushReplacement、pushAndRemoveUntil、清栈；禁止在根上切换不同 Widget。
- **订阅**：仅 `Navigator.push(context, SubscriptionPage())`，购买后或「Maybe Later」`Navigator.pop(context)`。
- **引导**：首日在 MainPage 上 `push(OnboardingPage)`，Skip 则 `pop`，Unlock Pro 则 `pop` 再 `push(SubscriptionPage)`。

```
MainPage (IndexedStack)
├── Home   — HeroSection、TopDealBanner、HotDealsSection、AdBanner(Free)
├── Explore — SearchBar、四横滑、限制时引导去订阅
├── Wishlist — 未登录 LoginGate / 登录后 WishlistList
└── Profile — 用户信息、订阅、分享、App guide、Rate us
```

**独立页（仅 push，不替换根）：**
- `OnboardingPage` — 首日引导，结束必 `pop`
- `SubscriptionPage` — 订阅，带「Maybe Later」与 `pop`

---

## 三、数据流设计（稳定版）

**启动流程：**
```
App 启动
  → main: StorageService.init, CacheService.init, BillingService.init, NotificationService.init
  → 读取本地缓存 (Hive + SharedPreferences)
  → FirstLaunchWrapper: isFirstLaunch? → Onboarding 或 MainNavigation
  → MainNavigation: 各 Tab 展示 UI（秒开，用 CacheService.loadGames()）
  → 后台刷新 API (ApiService.fetchDeals)
  → 更新缓存 (CacheService.saveGames)
  → 去重 + 算法 (deduplicateDeals, topDealsByScore / ShockDealAlgorithm)
  → setState 刷新 UI
```

**禁止：** 等 API 再显示页面；UI 直接调 API 不经过缓存。

---

## 四、权限与订阅控制逻辑

**文件：** `lib/core/access_control.dart`

**职责：**
- `canUseUnlimitedSearch()` → isPro
- `canUseWishlistNotification()` → isPro
- `canRemoveAds()` → isPro
- `canSearchToday()` → isPro 或 今日次数 < 3

**使用处：**
- Home / Explore 拉取前检查 `canSearchToday()`，用尽则展示「Unlock unlimited」并跳 SubscriptionPage
- 插屏 / Banner：`InterstitialHelper`、Home 根据 `isPro` 决定是否展示
- 愿望单降价通知：`background_task` 仅 isPro 发送

**数据来源：** `StorageService.isPro()`（含付费 Pro + 分享奖励的 pro_free_until）

---

## 五、算法模块结构

**现有文件：**
- `lib/core/utils/score_calculator.dart` — `deduplicateDeals`, `topDealsByScore`（按得分 Top N）
- `lib/core/shock_deal_algorithm.dart` — 去重、分类 (NewRelease, Trending, HiddenGems, TodayHot)、主推/统计

**逻辑对应：**
- **Hot** = Top 10 by score (`topDealsByScore`)
- **New** = 30 天内 (`ShockDealAlgorithm` 分类)
- **Trending** = review 增长高
- **Wishlist** = 用户收藏且降价（后台任务 + 本地缓存价格对比）

**得分维度：** 折扣、评价量、增长、历史低价等（见 `score_calculator` / `shock_deal_algorithm`）。

---

## 六、登录与多语言

**登录（规划）：**
- 使用 `google_sign_in`（当前未接入）
- 逻辑：未登录 → 仅浏览；登录 → 可收藏；Pro → 解锁全部
- 存储：user_id, email, photo_url
- 不强制登录

**多语言：**
- `flutter_localizations` + 手动 `lib/l10n/app_localizations.dart`（en/zh/ja/ko/de/fr）
- ARB 结构：`lib/l10n/app_*.arb`
- MaterialApp：`localizationsDelegates`, `supportedLocales`，默认跟随系统

---

## 七、通知与分享

**通知（notification_service + background_task）：**
- 每日 9:00 本地预约提醒（`zonedSchedule`）
- 愿望单降价：WorkManager 每日跑，对比缓存价格，仅 Pro 发本地通知
- 3 天未打开：每日任务中检查 `last_open_date`，发召回通知

**分享：**
- `share_plus`：Profile「Share app」带 `ref=userId` 链接
- 分享次数累计，满 3 次送 1 天 Pro（本地）

**DeepLink：**
- `app_links`：启动时 `getInitialLink()`，解析 `ref` 存 `referrerId`
- 可扩展：`yourapp://game/{id}` 打开 App 跳详情页

---

## 八、广告与盈利控制

**规则：**
- 免费用户：Banner 常驻（Home 第 3 位 + 底部）；每 3 次打开 / 加愿望单 / 每 5 次详情 → 插屏（每日上限 2 次）
- Pro：不加载插屏、不展示 Banner

**实现：**
- `InterstitialHelper`：各触发点前 `if (await storage.isPro()) return false;`
- Home：`if (!_isPro)` 才插入 `AdBanner`
- 统一通过 `AccessControl.canRemoveAds()` / `StorageService.isPro()` 判断

---

## 九、最终目录结构（目标）

```
lib/
├── main.dart
├── app.dart
├── models/
│     game_model.dart
│     wishlist_model.dart
├── core/
│     constants.dart
│     theme/
│     utils/           # score_calculator, format_util, ...
│     access_control.dart
│     storage_service.dart
│     services/
│       billing_service.dart
│       review_service.dart
├── data/
│     services/
│       api_service.dart
│       cache_service.dart
│       wishlist_service.dart
├── features/          # 或 pages/
│     home/
│     explore/
│     wishlist/
│     profile/
│     detail/
│     subscription/
│     onboarding/
├── widgets/
├── screens/           # 部分详情/搜索等
├── l10n/
└── services/          # steam_api_service, notification_service 等
```

（当前项目已基本按此分层，部分在 `core/`、`data/`、`features/` 混合。）

---

## 十、视觉系统（锁定）

| 用途     | 色值 / 说明        |
|----------|--------------------|
| 背景     | `#0B141B`（可逐步替换现有 background） |
| 卡片     | `#152533`          |
| 折扣/红  | 强调色             |
| 热度/橙  | 强调色             |
| 新游/蓝  | 强调色             |
| Pro/绿   | successGreen       |

**字体层级：** Hero 24 / 模块标题 20 / 卡片标题 16 / 标签 12。

---

## 十一、最终产品形态总结

- 有算法（得分、去重、分类）
- 有缓存（Hive + SharedPreferences，秒开）
- 有订阅（BillingService + SubscriptionPage）
- 有广告（Banner + 插屏，Pro 关闭）
- 有通知（每日、愿望单降价、召回）
- 有分享 + ref 拉新（本地奖励）
- 有多语言（l10n）
- 有权限控制（AccessControl + StorageService.isPro）
- 有首日引导与评分（Onboarding + ReviewService）

以上为当前实现的「最终形态」架构与对应关系。
