# TestFlight 发布手册（Windows 全程可操作，无需 Mac）

仓库已内置 `.github/workflows/release-testflight.yml`：手动触发后，云跑机自动签名并把
构建直传 App Store Connect。你只需在 Apple 与 GitHub 两侧做一次性配置（约 20 分钟）。

> **前置条件**：Apple Developer Program 已激活（$99/年，注册审核通常 1–2 天）。

---

## A. 注册 Bundle ID（developer.apple.com）

1. 打开 [developer.apple.com/account](https://developer.apple.com/account) →
   **Certificates, Identifiers & Profiles** → **Identifiers** → `+`。
2. 选 **App IDs** → **App** → Description 随意填（如 `GTO Academy`），
   Bundle ID 选 **Explicit**，填你的反向域名，建议：`com.rongpengyang.gtoacademy`。
3. Capabilities 全部保持默认，直接 **Register**（本 App 无推送、无 iCloud、无任何特殊能力）。

## B. 创建 App 记录（appstoreconnect.apple.com）

1. 打开 [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **我的 App** → `+` → **新建 App**。
2. 平台 **iOS**；名称可参考 `Docs/AppStore.md`（App 名称全球唯一，被占用就加后缀）；
   主要语言 **简体中文**；Bundle ID 选 A 步注册的那个；SKU 随意（如 `gtoacademy-001`）。

## C. 生成 App Store Connect API 密钥

1. App Store Connect → **用户和访问** → **集成** → **App Store Connect API** → **团队密钥** → `+`。
2. 名称随意，访问权限选 **App 管理**（App Manager，权限不足是首跑失败的头号原因）。
3. 记下页面上的 **Issuer ID**（顶部）与该密钥的 **Key ID**，并**下载 .p8 文件**——
   ⚠️ 只能下载一次，妥善保存。

## D. 找到 Team ID

[developer.apple.com/account](https://developer.apple.com/account) → **Membership details**（成员资格），
**Team ID** 是一串 10 位字符。

## E. 配置 GitHub Secrets（共 5 个）

仓库页 → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**：

| Secret 名 | 内容 |
| --- | --- |
| `ASC_KEY_ID` | C 步的 Key ID |
| `ASC_ISSUER_ID` | C 步的 Issuer ID |
| `ASC_API_KEY_P8` | .p8 文件**全文**（记事本打开整段复制，含 `-----BEGIN/END PRIVATE KEY-----` 两行） |
| `APPLE_TEAM_ID` | D 步的 Team ID |
| `BUNDLE_ID` | A 步的 Bundle ID（与 App 记录严格一致） |

## F. 触发发布

仓库页 → **Actions** → 左侧 **Release · TestFlight** → **Run workflow** →
填营销版本号（如 `1.1.0`）→ 绿色按钮。
流水线两段：Ubuntu 内容校验（秒级）→ macOS 签名构建并上传（约 10–20 分钟）。

## G. 安装到 iPhone

1. App Store Connect → 我的 App → GTO Academy → **TestFlight** 标签，等构建从
   「正在处理」变为可用（出口合规已在工程内声明 `ITSAppUsesNonExemptEncryption=NO`，
   无需逐 build 作答）。
2. **内部测试** → `+` 新建内部组 → 添加测试员（你自己；该 Apple ID 需先存在于
   「用户和访问」中，内部测试员上限 100 人，**无需 Apple 审核**即可装）。
3. iPhone 安装 **TestFlight** App → 收到邀请邮件 → 接受 → 安装运行。

---

## 版本与构建号策略

- **营销版本**（1.1.0）：每次 Run workflow 时手填。
- **构建号**：自动 = 工作流 run number，单调递增——同一版本号反复重跑不会撞构建号。

## 排障速查

| 现象 | 处置 |
| --- | --- |
| `No suitable application records were found` | B 步 App 记录未建，或 `BUNDLE_ID` secret 与 ASC 里的 Bundle ID 不一致 |
| `Cloud signing permission error` / not allowed | API 密钥角色不足（须 **App 管理**），或开发者协议未签——登录 developer.apple.com 首页把待签协议点掉 |
| `Authentication credentials are missing or invalid` | 三个 `ASC_*` secret 有误；重点检查 .p8 是否整段复制（含首尾行） |
| archive 报 `No profiles for …` | A 步 Bundle ID 未注册或拼写与 secret 不一致（`-allowProvisioningUpdates` 会自动建描述文件，但 App ID 必须存在） |
| TestFlight「正在处理」卡 30 分钟以上 | Apple 侧排队，常见，耐心等；超过数小时会收到具体原因邮件，贴回来即可 |
| 担心要付费协议 | 不需要。TestFlight 内部测试免 Paid Apps 协议，正式上架收费才涉及 |

首跑失败不要慌：失败时工作流会把 `archive.log` / `export.log` 作为 artifact 上传，
Windows 下载后把报错段落贴给 Claude 即可定位。
