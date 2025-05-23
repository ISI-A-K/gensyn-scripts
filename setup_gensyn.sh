#!/bin/bash

# =========================================
# Gensyn Node Install Script (Fresh Setup)
# =========================================

set -e

# 1. 必要パッケージのインストール
sudo apt update && sudo apt install -y \
  git python3 python3-pip python3-venv curl tmux build-essential nodejs

# 2. Node.js v20 のインストール
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v

# 3. Cloudflared のインストール（GUIログイン用）
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/
cloudflared --version

# 4. Swap（8GB）設定（必要に応じて）
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
grep -qxF '/swapfile none swap sw 0 0' /etc/fstab || \
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 5. bashrc をテンプレートから取得
curl -sSfL https://raw.githubusercontent.com/ISI-A-K/gensyn-scripts/main/bashrc_template -o ~/.bashrc

# 6. Gensynリポジトリの取得 + 最新タグへ切り替え
cd ~
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm
git fetch --tags
latest_tag=$(git tag --sort=-v:refname | head -n 1)
echo "最新タグに切り替え: $latest_tag"
git checkout "tags/$latest_tag" -b "$latest_tag"
git submodule update --init --recursive

# 7. Python仮想環境と依存解決
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate

pip install --upgrade pip
pip install -r requirements-cpu.txt
pip install \
  numpy==1.24.3 \
  protobuf==5.29.0 \
  pydantic==2.11.4
pip check

# 8. modal-login の依存とビルドを手動実行（公式ビルド失敗回避）
cd modal-login
rm -f package-lock.json
rm -rf node_modules
sudo npm uninstall -g yarn || true
sudo npm install -g yarn

yarn install
yarn upgrade
yarn add next@14 viem@latest encoding pino-pretty
yarn build
cd ..

# 9. runner.py パッチ（GitHubから取得）
curl -sSfL https://raw.githubusercontent.com/ISI-A-K/gensyn-scripts/main/testnet_grpo_runner.py -o ~/rl-swarm/hivemind_exp/runner/gensyn/testnet_grpo_runner.py

# 10. run_rl_swarm.sh の修正（不要な pip install を無効化）
sed -i '/pip install/d' ~/rl-swarm/run_rl_swarm.sh
sed -i 's|open http://localhost:3000|echo '\''Server running at http://localhost:3000. Please open this URL in your browser.'\''|' run_rl_swarm.sh

# 11. 案内表示
cat <<EOM
✅ セットアップ完了。以下のコマンドでノードを起動してください：

tmux new -s gensyn
cd ~/rl-swarm
source .venv/bin/activate
export CPU_ONLY=1
export CUDA_VISIBLE_DEVICES=""
./run_rl_swarm.sh

Cloudflareトンネルは別ターミナルで：
cloudflared tunnel --url http://localhost:3000
EOM

exit 0
