#!/bin/bash
#
# DIY 脚本 Part 1（feeds update 之前执行）
# 只负责往 package/ 里放额外的源码，不要在这里改 .config
#

# UA2F（可选，配合 doc/config/ua2f.config 使用）
git clone --depth 1 https://github.com/Zxilly/UA2F package/UA2F

# 需要更多第三方软件源时，在这里追加 feed，例如：
# echo 'src-git smpackage https://github.com/kenzok8/small-package' >> feeds.conf.default
# 注意：第三方 feed 容易与官方包重名冲突，非必要不添加。
