# immortalwrt-FUR-602

用 GitHub Actions 在线编译 **HONOR FUR-602**（MT7981 / AX3000）的 ImmortalWrt 固件。

仓库本身不含 OpenWrt 源码，只有三样东西：编译工作流、`.config` 配置、DIY 定制脚本。
编译时由 GitHub 的 runner 现场拉取上游源码。

| 项目 | 值 |
| --- | --- |
| 机型 | HONOR FUR-602（`honor_fur-602`） |
| 上游源码 | `bbb0bbb0bbb/immortalwrt-mt798x-24.10` @ 分支 `2410` |
| 驱动方案 | MTK 闭源无线（mt_wifi）+ WARP v2 / WED 硬件加速 + hnat |
| 默认网关 | 192.168.50.1 |
| 默认密码 | password（**首次登录后请立即修改**） |

## 目录结构

```
├── .github/workflows
│   ├── FUR-602.yml          编译并发布固件（手动触发 / repository_dispatch）
│   └── update-checker.yml   定时检查上游源码更新（周二四六 18:00 UTC）
├── doc/config
│   ├── mt7981-honor_fur-602.config   主配置：机型 + 内核 + 软件包
│   └── ua2f.config                   可选功能：UA2F（不需要就注释掉）
├── doc/diy
│   ├── diy-part1.sh         feeds 更新前执行：放置额外源码
│   └── diy-part2.sh         feeds 安装后执行：改默认 IP、替换第三方包
├── LICENSE
└── README.md
```

## 使用步骤

1. **Fork** 本仓库。
2. 进入 fork 后的仓库 → `Settings` → `Actions` → `General`：
   - Workflow permissions 选 **Read and write permissions**（发布 Release 需要）
   - Actions permissions 选 **Allow all actions**
3. 打开 `Actions` → 选 **FUR-602** → `Run workflow` → 开始编译。
   - 参数 `clean`：设为 `true` 会清空 ccache，上游内核/工具链大版本变动后编译报错时用。
4. 编译完成后产物出现在 `Releases`，只保留最近 3 个版本。

### 可选：源码更新后自动提醒

`update-checker.yml` 默认每两周检查一次（周二/四/六 UTC 18:00）上游是否有新提交。
若要邮件通知，在 `Settings → Secrets` 添加三个变量：

| Secret | 说明 |
| --- | --- |
| `MAILUSERNAME` | 发件邮箱（示例用 163 SMTP） |
| `MAILPASSWORD` | SMTP 授权码 |
| `MAIL` | 收件邮箱 |

配置齐全才发信，没配置就只记录 commit hash，不会报错。
想让更新自动触发编译，再添加 `ACTIONS_TRIGGER_PAT`（具备 `repo` 权限的 PAT），
然后把 `update-checker.yml` 里 `Trigger build` 那一段的注释去掉。

## 定制

### 增删软件包

改 `doc/config/mt7981-honor_fur-602.config`：

```
CONFIG_PACKAGE_xxx=y      # 编进固件
# CONFIG_PACKAGE_xxx is not set   # 不编
```

不确定的符号名可以在本地 `make menuconfig` 选好后，从生成的 `.config` 里复制。
**源码里不存在的符号会被 `make defconfig` 静默丢弃**——改完记得看 Release 里的
`config.buildinfo`，确认你要的包真的进去了。

### 增加其他机型

现在只编 FUR-602 一个机型。要同时编多个，在主 config 里加：

```
CONFIG_TARGET_MULTI_PROFILE=y
CONFIG_TARGET_PER_DEVICE_ROOTFS=y
CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_honor_fur-602=y
CONFIG_TARGET_DEVICE_PACKAGES_mediatek_mt7981_DEVICE_honor_fur-602=""
CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_cmcc_rax3000m=y
CONFIG_TARGET_DEVICE_PACKAGES_mediatek_mt7981_DEVICE_cmcc_rax3000m=""
```

机型名以上游 `target/linux/mediatek/mt7981/base-files/lib/upgrade/platform.sh`
和 `target/linux/mediatek/image/mt7981.mk` 中的定义为准。

### 预置配置文件

在仓库根目录放一个 `files/` 目录，编译流程会自动 `mv files openwrt/files`，
其下的内容会按路径覆盖进固件的根文件系统（例如 `files/etc/config/network`）。

## 刷机前必读

1. **先备份无线校准数据。** MT7981 的 eeprom / factory 分区存着 WiFi 校准参数，
   刷错分区或整片擦除会导致信号严重劣化且难以恢复。刷机前先：

   ```
   cat /proc/mtd            # 确认分区名
   dd if=/dev/mtdX of=/tmp/factory.bin   # X 换成 factory / eeprom 分区号
   ```

   同时备份原厂固件，并确认该机型的救砖方式（UART / 编程器 / U-Boot）。

2. **factory 与 sysupgrade 别选错。** 从原厂固件首次刷入用 `-factory.bin`，
   已经在 OpenWrt 体系内升级用 `-sysupgrade.bin`。

3. **校验产物。** Release 中保留了 `sha256sums`，下载后先核对再刷。
   固件由第三方自动化流水线产出，没有官方签名。

4. **改默认密码。** 默认 `password` 是公开的，任何有端口映射或暴露在公网的
   设备都应第一时间修改。

## 与上游模板相比改了什么

本仓库由 `guorong697/immortalwrt-mtk7981-HONOR-FUR-602` 改写，主要修正：

- Release 名 / tag / ccache key 统一为 `fur602-*` 前缀（原仓库仍写死 `360T7-padavanonly`）
- 只保留与主工作流配套的一份 config，不再让 21.02 与 24.10 两套源码树共用一份配置
- `update-checker` 检测的源与实际编译的源保持一致（原仓库两者不同）
- 修好 `ua2f.config`（原文件四行全是注释，UA2F 实际从未编入）
- Release 说明与实际产物一致，不再写不存在的组件
- 保留 `sha256sums` / `config.buildinfo`，便于校验与回溯
- 移除浮动 tag 中的 `@main`（checkout / upload-artifact 已锁大版本）
- 增加 `concurrency` 防止重复构建互相踩踏

## 安全建议

工作流引用了多个第三方 action（`cachewrtbuild`、`delete-older-releases`、
`delete-workflow-runs` 等），它们运行在持有 `contents: write` 权限的环境里。
用于生产环境前建议把它们固定到具体的 commit SHA：

```
uses: klever1988/cachewrtbuild@<commit-sha>
```

`doc/diy/diy-part2.sh` 里的 `UPDATE_PACKAGE` 会用 GitHub 上的版本**替换 feeds 中的同名包**，
属于上游投毒可直接进入固件的路径，加入新仓库前请确认其可信度。

## 许可

MIT。固件内含大量 GPL / 专有驱动组件，使用与再分发请遵守各自许可，
MTK 闭源无线驱动部分尤其注意不可分发源码。
