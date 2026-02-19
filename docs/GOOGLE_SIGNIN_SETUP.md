# Google 登录配置说明

---

## ⚠️ 之前能登录、现在不能了？（常见原因）

**若你之前用「调试安装」能登录，现在用「打包安装的 release APK」不能登录**，是因为：

- **Debug 安装**：用的是 **Debug 签名的 SHA-1**
- **Release 安装**（`flutter build apk` / `flutter install --release`）：用的是 **Release/Upload 签名的 SHA-1**

Google 只认「当前安装包」的签名。所以用 release 包时，必须在 Google Cloud 里为 **同一个 Android 客户端** 再添加 **Release 的 SHA-1**，或新建一个 Android 客户端填 **包名 + Release SHA-1**。

**快速修复**：

1. 打开 [Google Cloud Console](https://console.cloud.google.com/) → 你的项目 → **API 和服务** → **凭据**。
2. 找到类型为 **Android** 的 OAuth 客户端（包名 `com.steamdeal.alert`）。
3. 编辑该客户端，在 **SHA-1 证书指纹** 里**新增一行**，填入你本机 **Release** 的 SHA-1（见下文「本机已跑出的 SHA-1」里 **Upload** 那一行的值，或运行 `cd android; .\gradlew.bat signingReport` 看 **Variant: release** 的 SHA1）。
4. 保存后等几分钟再在手机上重试登录。

---

当前使用的 **Web 客户端 ID**（`serverClientId`）在代码里：`lib/core/constants.dart` → `googleSignInClientId`。  
必须与 Google Cloud 里 **同一项目** 下的 **Web 应用** OAuth 客户端 ID 完全一致。

**重要**：能弹出 Google 登录界面但点完账号后无法登录到 App，多半是 **未配置或配错 Android 客户端**（包名 + SHA-1），或 **Web Client ID 与 Cloud 不一致**。必须同时满足：
- 已有 **Web 应用** 类型的 OAuth 客户端（用于代码里的 `serverClientId`）；
- 同一项目下还有 **Android** 类型的 OAuth 客户端，包名 + 当前安装包签名的 SHA-1 一致。

---

## 如何创建正确的 Web Client ID（serverClientId）

若怀疑当前 Web Client ID 不对，或项目里还没有 Web 应用类型的客户端，按下面新建一个，再把代码里的值改成新 ID。

1. 打开 [Google Cloud Console](https://console.cloud.google.com/)。
2. 左上角 **选择项目**：选你的项目（例如 **emailAi** / **emailai-450716**，项目号 341972414995）。**Web 和 Android 客户端必须在同一项目。**
3. 左侧 **「API 和服务」→「凭据」**（Credentials）。
4. 若需先配置 OAuth 同意屏幕：
   - 若提示「配置 OAuth 同意屏幕」，先点进去，**用户类型**选「外部」（或内部测试用选「内部」），填应用名称、用户支持邮箱等必填项，保存。
5. 创建 Web 客户端：
   - 点击 **「+ 创建凭据」→「OAuth 客户端 ID」**。
   - **应用类型** 选 **「Web 应用」**（Web application），不要选 Android / 桌面应用。
   - **名称** 填例如：`Steam Deal Alert Web`。
   - **已授权的 JavaScript 来源**、**已授权的重定向 URI**：仅给 App 当 serverClientId 用时可以**先不填**，直接点「创建」。
   - 创建完成后会弹出或列表里出现一条 **客户端 ID**，格式类似：  
     `341972414995-xxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com`
6. **复制该客户端 ID**（整串），然后：
   - 打开项目里的 `lib/core/constants.dart`；
   - 找到 `googleSignInClientId`，把原来的字符串**整体替换**为刚复制的 Web 客户端 ID；
   - 保存并重新打包/运行 App。

这样代码里的 Web Client ID 就与 Cloud 里新建的 Web 应用一致，再配合同项目下的 Android 客户端（包名 + SHA-1），登录即可使用。

---

## 无法登录时请先做（Android 客户端）

1. 打开 [Google Cloud Console](https://console.cloud.google.com/) → 选择项目 → **API 和服务** → **凭据**。
2. 点击 **「创建凭据」→「OAuth 客户端 ID」**。
3. 应用类型选 **Android**（不是“Web 应用”）：
   - **名称**：随意，如 `Steam Deal Alert Android`；
   - **包名**：`com.steamdeal.alert`（必须与 `android/app/build.gradle` 里 `applicationId` 一致）；
   - **SHA-1 证书指纹**：见下表（调试安装用 Debug，商店包用 Release）。
4. 保存。**调试安装**请务必添加 **Debug** 的 SHA-1，否则会出现“能选账号但登录失败”。

---

## 本机已跑出的 SHA-1（可直接复制到 Google Console）

| 用途 | SHA-1 | 说明 |
|------|--------|------|
| **Debug**（`flutter run` / 真机调试） | `2D:F3:CF:5C:6D:A4:1C:1F:CC:0E:A7:B0:67:D5:D3:CA:AD:D4:AB:E3` | 本机 debug 密钥，用于「Steam Deal Alert Android Local」 |
| **Upload**（你本机打的 AAB 签名） | `D8:ED:C5:5E:F5:9A:CA:3F:39:C0:80:1F:52:B4:2A:97:FB:D7:D1:29` | 仅上传时用，**用户从 Play 下载的包不是用这个签的** |
| **Play 应用签名**（封闭测试/正式版从商店安装） | 见下方「从 Play 下载的包」 | 必须在 **Play 控制台** 复制，用于「Steam Deal Alert Android Play」 |

---

## 自己获取 SHA-1（可选）

在项目根目录执行（PowerShell）：

```powershell
cd e:\steamGame\android; .\gradlew.bat signingReport
```

在输出里找到 **:app:signingReport** 下的 **Variant: debug** / **Variant: release**，复制对应的 **SHA1** 行。

---

---

## 如何确认配置已生效

按下面顺序自查，可确认是否生效、以及哪里不一致。

### 1. 看 App 内错误码

登录失败时，SnackBar 会提示「错误码 10」或「错误码 7」等：

- **错误码 10**：Google 认为“开发者配置错误”——当前安装包的 **包名** 或 **签名 SHA-1** 与控制台里任一 Android 客户端不一致。需要做下面 2、3 步核对。
- **错误码 7**：网络或 Google Play 服务异常，与配置无关。

若一直是 **10**，说明控制台里的 Android 客户端和“当前手机上的安装包”对不上。

### 2. 核对本机当前 SHA-1（必须与控制台完全一致）

**当前安装包**是用哪台电脑、用 debug 还是 release 打的，就用那台电脑跑一次：

```powershell
cd e:\steamGame\android
.\gradlew.bat signingReport
```

在输出里找到 **Variant: debug**（用 `flutter run` 装的就是 debug）或 **Variant: release**，复制 **SHA1** 那一行的整串（含冒号、大写字母），例如：

```
SHA1: 2D:F3:CF:5C:6D:A4:1C:1F:CC:0E:A7:B0:67:D5:D3:CA:AD:D4:AB:E3
```

和 Google 控制台里该 Android 客户端的 **SHA-1 证书指纹** 逐字对比（包括大小写、冒号）。若**有任何不同**（例如换过电脑、重装过 Android Studio，debug 密钥会变），就在**同一项目**里再建一个 Android 客户端，包名仍填 `com.steamdeal.alert`，SHA-1 填这次 signingReport 出来的值，保存后再试登录。

### 3. 确认“同一项目”

- 代码里用的 Web 客户端 ID 是：`341972414995-q37tpdspsf6a6r47jcg2tdvd1st0slva.apps.googleusercontent.com`（项目号 **341972414995**）。
- Android 客户端必须在 **同一个** 项目（凭据列表里能看到同一个项目名 / 项目号）里创建。若 Android 客户端在别的项目（例如 8034…），登录会一直失败。

### 4. 生效时间

控制台保存后，通常 5 分钟～几小时内生效。若已等很久且 2、3 都确认无误，可尝试：手机关机重启、或清除「Google Play 服务」的缓存后再试一次登录。

### 5. 从 Google Play（含封闭测试）下载的包也报错误码 10 / 配置了“Play 证书”仍验证不生效

**原因**：从 Play 安装的包是由 **Google 应用签名密钥** 重签的，设备看到的 SHA-1 是 **「应用签名密钥证书」**，不是 **「上传密钥证书」**。

- **上传密钥证书（Upload key certificate）**：你用来给 AAB 签名的密钥，仅在上传时用；**用户/测试员下载到的 APK 不是用这个签的**。若把它的 SHA-1 填进「Steam Deal Alert Android Play」，从 Play 安装的包会报错误码 10，验证不生效。
- **应用签名密钥证书（App signing key certificate）**：Google 用来签发给用户/测试员的 APK 的密钥。**必须**把它的 SHA-1 填进「Steam Deal Alert Android Play」。

**正确做法**：

1. 打开 [Google Play 控制台](https://play.google.com/console/) → 选择应用 → **设置** → **应用完整性**（App integrity）。
2. 同一页「应用签名」里通常有**两个**证书区域：
   - **上传密钥证书**（Upload key certificate）— 不要用这个做 Google 登录的 Android 客户端。
   - **应用签名密钥证书**（App signing key certificate）— 在**下方或另一块**，复制这里的 **SHA-1 证书指纹**。
3. 打开 [Google Cloud Console](https://console.cloud.google.com/) → 项目 **341972414995** → **凭据** → 编辑「Steam Deal Alert Android Play」。
4. 将 **SHA-1 证书指纹** 改为上一步复制的 **应用签名密钥证书** 的 SHA-1（不是上传密钥的 `D8:ED:C5:5E:...`），保存。
5. 等待约 5～10 分钟后再用从 Play 安装的 App 尝试 Google 登录。

若当前「Steam Deal Alert Android Play」里填的是 `D8:ED:C5:5E:F5:9A:CA:3F:39:C0:80:1F:52:B4:2A:97:FB:D7:D1:29`，那是上传密钥，必须改成应用签名密钥证书的 SHA-1。

### 6. “本机 SHA-1 和 Google 里填的不一样 / 感觉本机没生效”

- **控制台里「Steam Deal Alert Android Local」的 SHA-1**（`2D:F3:CF:5C:...`）和本机执行 `signingReport` 得到的 **Variant: debug** 的 SHA1 **应是同一串**。若完全一致，说明本机 debug 已正确配置。
- **“无法验证应用所有权 / not applicable to verify ownership”**：这是针对「未上架 Play 的客户端」的提示，不影响登录。本地调试用客户端不需要验证所有权，登录只看包名 + SHA-1。
- 若你**换过电脑**或用**另一台电脑**给手机装过 App，那一台电脑的 debug 密钥不同，SHA-1 也会不同。解决：在**当前用来给手机安装**的那台电脑上运行 `signingReport`，把得到的 **debug SHA1** 复制到控制台，或新建一个 Android 客户端填这个 SHA-1（包名仍为 `com.steamdeal.alert`）。

---

## 行为说明

- **未登录**：仅浏览 Home/Explore；Wishlist 显示「Sign in to use Wishlist」。
- **登录后**：Profile 显示头像/邮箱与「Sign out」；Wishlist 正常使用（本地列表）。
- 不强制登录，未登录也可使用除愿望单外的功能。
- 若登录失败，App 内会弹出 SnackBar 提示；根据错误码（10 / 7）按上文排查。
