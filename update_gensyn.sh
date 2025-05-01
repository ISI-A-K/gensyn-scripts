#!/bin/bash

# =========================================
# Gensyn Node Update Script (Enhanced Version)
# =========================================

# 1. バックアップ作成
mkdir -p ~/rl-backups
tar czvf ~/rl-backups/gensyn_backup_$(date +%F).tar.gz \
  ~/rl-swarm/swarm.pem \
  ~/rl-swarm/modal-login/temp-data/userData.json \
  ~/rl-swarm/modal-login/temp-data/userApikey.json 2>/dev/null || true

# 2. 古いノードを退避し、新しいコードを取得
mv ~/rl-swarm ~/rl-swarm-bak
cd ~
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm
git submodule update --init --recursive

# 3. Node.js をバージョン20にアップグレード
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v

# 4. バックアップファイルを復元
cp ~/rl-swarm-bak/swarm.pem ~/rl-swarm/
mkdir -p ~/rl-swarm/modal-login/temp-data
cp ~/rl-swarm-bak/modal-login/temp-data/*.json ~/rl-swarm/modal-login/temp-data/ 2>/dev/null || true

# 5. Python 仮想環境再構築
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# プロトコルバージョンの衝突回避のため protobuf ダウングレード
pip install protobuf==5.27.5
pip check

# 6. GitHubから最新のbashrcを取得
curl -sSfL https://raw.githubusercontent.com/ISI-A-K/gensyn-scripts/main/bashrc_template -o ~/.bashrc

# 7. GitHubから修正済みtestnet_grpo_runner.pyを取得
curl -sSfL https://raw.githubusercontent.com/ISI-A-K/gensyn-scripts/main/testnet_grpo_runner.py -o ~/rl-swarm/hivemind_exp/runner/gensyn/testnet_grpo_runner.py

# 8. run_rl_swarm.sh の表示修正（Mac用 open の置換）
sed -i 's|open http://localhost:3000|echo '\''Server running at http://localhost:3000. Please open this URL in your browser.'\''|' run_rl_swarm.sh

# 9. 起動案内出力
cat <<EOM
✅ アップデート完了。以下のコマンドでノードを起動してください：

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

