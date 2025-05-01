#!/bin/bash

# =========================================
# Gensyn Node Setup Script (Full Updated Version)
# =========================================

# 1. 必要パッケージのインストール
sudo apt update && sudo apt install -y \
  git python3 python3-pip python3-venv curl tmux build-essential nodejs

# 2. Node.js v20 のセットアップ
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v

# 3. Cloudflared のインストール（GUIログイン用）
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/
cloudflared --version

# 4. Swap 設定（RAMが少ない場合に備えて）
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
grep -qxF '/swapfile none swap sw 0 0' /etc/fstab || \
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 5. bashrc をGitHubから取得して置き換え
curl -sSfL https://raw.githubusercontent.com/ISI-A-K/gensyn-scripts/main/bashrc_template -o ~/.bashrc

# 6. Gensyn リポジトリのクローンと初期化
cd ~
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm
git submodule update --init --recursive

# 7. Python 仮想環境のセットアップ
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install protobuf==5.27.5
pip check

# 8. 修正済み testnet_grpo_runner.py をGitHubから取得して反映
curl -sSfL https://raw.githubusercontent.com/ISI-A-K/gensyn-scripts/main/testnet_grpo_runner.py -o ~/rl-swarm/hivemind_exp/runner/gensyn/testnet_grpo_runner.py

# 9. run_rl_swarm.sh の表示変更（Mac用 open を除去）
sed -i 's|open http://localhost:3000|echo '\''Server running at http://localhost:3000. Please open this URL in your browser.'\''|' run_rl_swarm.sh

# 10. 起動案内
cat <<EOM
✅ セットアップ完了。以下のコマンドでノードを起動してください：

tmux new -s gensyn
cd ~/rl-swarm
source .venv/bin/activate
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
export CPU_ONLY=1
export CUDA_VISIBLE_DEVICES=""
./run_rl_swarm.sh

Cloudflare Tunnel を使うには別ターミナルで：
cloudflared tunnel --url http://localhost:3000
EOM

exit 0
