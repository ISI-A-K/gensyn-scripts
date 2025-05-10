#!/bin/bash

# =========================================
# Gensyn Node Update Script (Preserve ID & Auto-Tag)
# =========================================

set -e

# 1. バックアップ作成（swarm.pem + userData.json）
mkdir -p ~/rl-backups
mkdir -p ~/rl-swarm-bak
cp ~/rl-swarm/swarm.pem ~/rl-swarm-bak/swarm.pem 2>/dev/null
cp -r ~/rl-swarm/modal-login/temp-data ~/rl-swarm-bak/modal-login-temp-data 2>/dev/null
tar czvf ~/rl-backups/gensyn_backup_$(date +%F).tar.gz \
  ~/rl-swarm/swarm.pem \
  ~/rl-swarm/modal-login/temp-data/userData.json \
  ~/rl-swarm/modal-login/temp-data/userApikey.json 2>/dev/null || true

# 2. 古いノード削除・再取得
rm -rf ~/rl-swarm
cd ~
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm
git fetch --tags
latest_tag=$(git tag --sort=-v:refname | head -n 1)
echo "最新タグに切り替え: $latest_tag"
git checkout "tags/$latest_tag" -b "$latest_tag"
git submodule update --init --recursive

# 3. Node.js の確認
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v

# 4. swarm.pem の復元
if [ -f ~/rl-swarm-bak/swarm.pem ]; then
  cp ~/rl-swarm-bak/swarm.pem ~/rl-swarm/
  echo "✅ swarm.pem を復元しました。"
else
  echo "⚠️ swarm.pem が見つかりません（新規作成されます）"
fi

# 5. userData.json の復元
mkdir -p ~/rl-swarm/modal-login/temp-data
cp ~/rl-swarm-bak/modal-login-temp-data/*.json ~/rl-swarm/modal-login/temp-data/ 2>/dev/null || true

# 6. 仮想環境再構築と pip install
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

# 7. modal-login の依存アップグレードとビルド
cd modal-login
yarn install
yarn upgrade
yarn add next@14 viem@latest encoding pino-pretty
yarn build
cd ..

# 8. bashrc, runner.py の取得
curl -sSfL https://raw.githubusercontent.com/ISI-A-K/gensyn-scripts/main/bashrc_template -o ~/.bashrc
curl -sSfL https://raw.githubusercontent.com/ISI-A-K/gensyn-scripts/main/testnet_grpo_runner.py -o ~/rl-swarm/hivemind_exp/runner/gensyn/testnet_grpo_runner.py

# 9. run_rl_swarm.sh の修正
sed -i '/pip install/d' ~/rl-swarm/run_rl_swarm.sh
sed -i 's|open http://localhost:3000|echo '\''Server running at http://localhost:3000. Please open this URL in your browser.'\''|' run_rl_swarm.sh

# 10. 案内表示
cat <<EOM
✅ アップデート完了。以下のコマンドでノードを再起動してください：

tmux attach -t gensyn  # セッションが残っている場合はこちら
# または
tmux new -s gensyn      # 新規セッションを作る場合はこちら

cd ~/rl-swarm
source .venv/bin/activate
export CPU_ONLY=1
export CUDA_VISIBLE_DEVICES=""
./run_rl_swarm.sh

Cloudflareトンネルは別ターミナルで：
cloudflared tunnel --url http://localhost:3000
EOM

exit 0
