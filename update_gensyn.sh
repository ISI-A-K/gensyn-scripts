#!/bin/bash

# =========================================
# Gensyn Node Update Script (Safe LF Version)
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

# 3. バックアップファイルを復元
cp ~/rl-swarm-bak/swarm.pem ~/rl-swarm/
mkdir -p ~/rl-swarm/modal-login/temp-data
cp ~/rl-swarm-bak/modal-login/temp-data/*.json ~/rl-swarm/modal-login/temp-data/ 2>/dev/null || true

# 4. Python 仮想環境再構築
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install protobuf==5.27.5
pip check

# 5. bashrc の最適化
sed -i 's/^[[:space:]]*PS1=/export PS1=/' ~/.bashrc
sed -i 's/\[ -z \"\$PS1\" \]/[ -z "${PS1-}" ]/' ~/.bashrc
sed -i 's/\[ -z \"\$debian_chroot\" \]/[ -z "${debian_chroot:-}" ]/' ~/.bashrc
grep -qxF 'if [ "$SHELL" = "/bin/bash" ]; then ulimit -n 65535; fi' ~/.bashrc || \
echo 'if [ "$SHELL" = "/bin/bash" ]; then ulimit -n 65535; fi' >> ~/.bashrc

# 6. run_rl_swarm.sh の表示変更（Mac用 open コマンドの除去）
sed -i 's|open http://localhost:3000|echo '\''Server running at http://localhost:3000. Please open this URL in your browser.'\''|' run_rl_swarm.sh

# 7. 起動案内出力
echo "✅ アップデート完了。以下の手順で再起動してください："
echo "tmux new -s gensyn"
echo "cd ~/rl-swarm"
echo "source .venv/bin/activate"
echo "export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0"
echo "export CPU_ONLY=1"
echo "export CUDA_VISIBLE_DEVICES=\"\""
echo "./run_rl_swarm.sh"

exit 0
