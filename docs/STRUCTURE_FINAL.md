# 最终稳定结构（Flutter 3.41+ / Dart 3.11 适配）

- **Home** = 算法推荐（GameService + AlgorithmService，不重复 Explore）
- **Explore** = 搜索 + 分类 + 排序
- **Wishlist** = 本地数据（CacheService.getWishlist）+ Pro 入口
- **Profile** = 语言 + 订阅（SubscriptionService）+ 通知
- 支持后续插入 AdMob / Billing / 本地缓存

## 项目结构

```
lib/
 ├── main.dart
 ├── app.dart
 ├── core/
 │    ├── models/game.dart          # 导出 GameModel
 │    ├── services/game_service.dart
 │    ├── services/algorithm_service.dart
 │    ├── services/cache_service.dart
 │    ├── services/subscription_service.dart
 │    └── services/notification_service.dart
 ├── features/
 │    ├── home/home_page.dart
 │    ├── explore/explore_page.dart
 │    ├── wishlist/wishlist_page.dart
 │    └── profile/profile_page.dart
 └── widgets/
      ├── game_card.dart
      ├── section_header.dart
      └── discount_badge.dart
```

## 服务用法

- **GameService()**：`fetchGames()`、`fetchGameById()`、`searchGames()`
- **AlgorithmService()**：`calculateScore(g)`、`sortByScore(list)`、`topByScore(list, limit: n)`
- **CacheService()**：`getWishlist()`、`getCachedGames()`、`saveGames()`、`getLastCheckTime()`
- **SubscriptionService()**：`isPro`、`loadProducts()`、`purchaseMonthly()`、`purchaseYearly()`、`restorePurchases()`

## 主题

- `scaffoldBackgroundColor`: `0xFF0E1116`
- `bottomNavigationBar.backgroundColor`: `0xFF151A22`
- 深色商业风，主色 ≤ 3 种
