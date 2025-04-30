#!/bin/bash

# =========================================
# Gensyn Node CPU-Only Mode Setup Script
# Author: ChatGPT (2025-04)
# =========================================

# 1. 基本パッケージのインストール
sudo apt update && sudo apt install -y \
  git python3 python3-pip python3-venv curl tmux build-essential \
  nodejs

# Node.js（v20系）をインストール
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v

# 2. Cloudflared のインストール（GUIログインのために必要）
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/
cloudflared --version

# 3. Swap の作成（初回のみでOK）
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 4. bashrc 設定の最適化（tmux等の互換性対応）
sed -i 's/^[[:space:]]*PS1=/export PS1=/' ~/.bashrc
sed -i 's/\\[ -z \\\"\\$PS1\\\" \\]/[ -z \"${PS1-}\" ]/' ~/.bashrc
sed -i 's/\\[ -z \\\"\\$debian_chroot\\\" \\]/[ -z \"${debian_chroot:-}\" ]/' ~/.bashrc
echo "ulimit -n 65535" >> ~/.bashrc
source ~/.bashrc

# 5. Gensyn リポジトリのクローン
cd ~
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm
git submodule update --init --recursive

# 6. Python 仮想環境のセットアップ
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install protobuf==5.27.5
pip check

# 7. run_rl_swarm.sh の open を echo に書き換え（非Mac環境向け）
sed -i 's/open http:\\/\\/localhost:3000/echo \"Server running at http:\\/\\/localhost:3000. Please open this URL in your browser.\"/' run_rl_swarm.sh

# 8. 実行方法案内
echo \"✅ 起動準備完了。以下の手順でノードを起動してください：\"
echo \"tmux new -s gensyn\"
echo \"cd ~/rl-swarm\"
echo \"source .venv/bin/activate\"
echo \"export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0\"
echo \"export CPU_ONLY=1\"
echo \"export CUDA_VISIBLE_DEVICES=\\\"\\\"\"
echo \"./run_rl_swarm.sh\"

exit 0
