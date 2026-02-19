# Google 登录：代码侧配置与排查清单

## 一、代码里实际用到的配置（唯一入口）

| 用途 | 值 | 代码位置 | 必须？ |
|------|-----|----------|--------|
| **Web 客户端 ID**（serverClientId） | `341972414995-q37tpdspsf6a6r47jcg2tdvd1st0slva.apps.googleusercontent.com` | `lib/core/constants.dart` → `googleSignInClientId` | **是** |
| Android 客户端 ID | （无） | 代码中**不出现** | 否 |
| client_secret / JSON 文件 | （无） | 代码中**不读取** | 否 |

- **AuthService** 只使用 `AppConstants.googleSignInClientId` 作为 `GoogleSignIn(serverClientId: ...)`。
- **Android 客户端**的 Client ID（如 fi2a4icbdq...、4209743m5vq3fe8f4lqjmles7r95urp5）**不需要也不应**写进 App；由 Google Play 服务根据**包名 + 当前 APK 的 SHA-1** 自动匹配同项目下的 Android 客户端。

---

## 二、你手里的文件 / 控制台里的 ID 是否要用？

| 名称 | 是否在代码里使用 | 说明 |
|------|------------------|------|
| `google秘钥/Client ID.txt` 或 Web 客户端 ID `341972414995-q37tpdspsf6a6r47jcg2tdvd1st0slva...` | **是** | 已写在 `constants.dart`，必须与 Cloud 里 **Web 应用** 类型 OAuth 客户端的 Client ID 一致。 |
| `client_secret_341972414995-q37tpdspsf6a6r47jcg2tdvd1st0slva.apps.googleusercontent.com.json` | **否** | 仅后端用（拿 code 换 token 等）。**纯 App 内登录不需要**，代码未引用。 |
| `client_secret_341972414995-fi2a4icbdq77oa6b1hejn7bjfpm57jt8.apps.googleusercontent.com.json` | **否** | 对应 **Android** 客户端（Local）的 client，App 内登录**不读**此文件，不参与当前登录流程。 |
| 「Steam Deal Alert Android Local」的 Client ID（fi2a4icbdq...） | **否** | Android 客户端仅凭 包名 + SHA-1 匹配，Client ID 不写进 App。 |
| 「Steam Deal Alert Android Play」的 Client ID（4209743m5vq3fe8f4lqjmles7r95urp5） | **否** | 同上。 |

结论：**代码层面只需要一个值——Web 客户端 ID（q37tpdspsf6a6r47jcg2tdvd1st0slva...）。**  
client_secret、两个 JSON 文件、两个 Android 客户端的 Client ID 都**不需要**在 App 里配置或读取。

---

## 三、配置与校验路径（从代码到 Cloud）

```
1. App 启动 / 用户点「Sign in with Google」
   → AuthService._google.signIn()
   → 使用 serverClientId = AppConstants.googleSignInClientId
     即 341972414995-q37tpdspsf6a6r47jcg2tdvd1st0slva.apps.googleusercontent.com

2. Google Play 服务（设备上）
   → 读取当前 App 的 包名（com.steamdeal.alert）和 签名 SHA-1
   → 在「与 serverClientId 同一项目」的凭据里查找：
      类型 = Android、包名 = com.steamdeal.alert、SHA-1 = 当前包签名的 SHA-1
   → 若找到 → 继续登录；若找不到 → 返回 ApiException: 10
```

因此：

- **Web 客户端**（q37tpdspsf6a6r47jcg2tdvd1st0slva）必须在 **Google Cloud 项目 341972414995** 里存在且类型为 **Web 应用**（或可做 serverClientId 的类型）。
- **Android 客户端** 必须在**同一项目**里，且至少有一个的 **包名 = com.steamdeal.alert**、**SHA-1 = 当前安装包的真实签名**（本机调试用 debug SHA-1，Play 安装用应用签名密钥的 SHA-1）。

---

## 四、逐项排查清单（错误码 10 时按顺序查）

- [ ] **1. 代码里的 Web Client ID**  
  `lib/core/constants.dart` 中 `googleSignInClientId` 是否为：  
  `341972414995-q37tpdspsf6a6r47jcg2tdvd1st0slva.apps.googleusercontent.com`  
  （与 Cloud 里 Web 客户端的 Client ID 完全一致。）

- [ ] **2. 当前安装包来源**  
  - 若从 **Play 封闭测试** 安装 → 设备上的签名 = **应用签名密钥**的 SHA-1（2B:EB:13:9C:...）。  
  - 若用 **flutter run** 或本机 APK 安装 → 设备上的签名 = **本机 debug** 的 SHA-1（2D:F3:CF:5C:...）。

- [ ] **3. Cloud 里 Android 客户端是否成对**  
  - **本机/调试**：存在一个 Android 客户端，包名 `com.steamdeal.alert`，SHA-1 = 本机 `signingReport` 的 **debug** SHA-1。  
  - **Play 安装**：存在一个 Android 客户端，包名 `com.steamdeal.alert`，SHA-1 = Play 控制台 **应用签名密钥证书** 的 SHA-1（2B:EB:13:9C:...）。

- [ ] **4. 同一项目**  
  上述 Web 客户端与两个 Android 客户端均在 **Google Cloud 项目 341972414995**（emailAi）下。

- [ ] **5. SHA-1 无 typo**  
  从 Play 或 signingReport 复制的 SHA-1 与 Cloud 中对应客户端**逐字一致**（含冒号、大小写、无首尾空格）。

- [ ] **6. 已卸载后重装（Play 包）**  
  若之前用本机装过同包名 App，已**完全卸载**后，再**仅从 Play 封闭测试**安装一次，避免残留旧签名。

- [ ] **7. 生效与缓存**  
  改 Cloud 后等 10–30 分钟；仍不行可试：清除「Google Play 服务」缓存、或重启手机后再试登录。

- [ ] **8. OAuth 同意屏幕（仅未上架时）**  
  若项目 OAuth 同意屏幕处于「测试」状态，只有已添加为**测试用户**的 Google 账号能登录。  
  Cloud Console → **API 和服务** → **OAuth 同意屏幕** → 若有「测试用户」列表，请把要用来登录的账号加进去。

---

## 五、Debug 时如何确认 App 用的 Web Client ID（可选）

在 `AuthService` 中，Debug 模式下**首次触发登录**（例如点击「Sign in with Google」）时，会在控制台打印当前使用的 `serverClientId` 前 30 字符，便于确认与 Cloud 一致。  
用 `flutter run` 或 Android Studio 运行后，在 Run/控制台里搜 `serverClientId` 即可看到，应为：`341972414995-q37tpdspsf6a6r47jcg...`。

---

## 六、总结表

| 配置项 | 代码/资源位置 | Cloud/Play 要求 |
|--------|----------------|------------------|
| Web Client ID | `lib/core/constants.dart` → `googleSignInClientId` | 项目 341972414995 内存在对应 Web 客户端 |
| 包名 | `android/app/build.gradle` → applicationId | 与 Cloud 中 Android 客户端包名一致：`com.steamdeal.alert` |
| Debug SHA-1 | 本机 `./gradlew signingReport` → debug | 填到「Steam Deal Alert Android Local」 |
| Play 应用签名 SHA-1 | Play 控制台 → 应用完整性 → 应用签名密钥证书 | 填到「Steam Deal Alert Android Play」 |
| client_secret / JSON | 未使用 | 不需要在 App 中配置 |
