#!/bin/bash

# --- VNC Password Configuration ---
# VNCパスワードが環境変数で設定されていない場合、ランダムなパスワードを自動生成する
if [ -z "$VNC_PASSWORD" ]; then
  echo "VNC_PASSWORD is not set. Generating a random password..."
  # 12文字の英数字のパスワードを生成
  VNC_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 12)
  echo
  echo "-------------------------------------------------"
  echo ">>> VNC Password for this container: ${VNC_PASSWORD} <<<"
  echo "-------------------------------------------------"
  echo
else
  echo "Using VNC_PASSWORD from environment variable."
fi

# VNCパスワード認証を設定
echo "Configuring VncAuth."
mkdir -p /home/kali/.vnc
echo "$VNC_PASSWORD" | vncpasswd -f > /home/kali/.vnc/passwd
chmod 600 /home/kali/.vnc/passwd
chown -R kali:kali /home/kali/.vnc
SECURITY_OPT="-SecurityTypes VncAuth"
AUTH_OPT="-rfbauth /home/kali/.vnc/passwd"
 
# --- VNC Server Command Assembly ---
# vncserverコマンドを組み立てる
VNC_CMD="vncserver :1 \
    -geometry 1280x800 \
    -depth 24 \
    $SECURITY_OPT $AUTH_OPT \
    # クリップボード設定:
    # -AcceptCutText 1 : ホストPCからのペーストを許可
    # -SendCutText 0   : ホストPCへのコピーを禁止
    -AcceptCutText 1 \
    -SendCutText 0"

# --- Process Startup Logic ---
# 手順1: VNCサーバーを 'kali' ユーザーとしてデーモン起動する
echo "Starting VNC server as a daemon..."
su - kali -c "$VNC_CMD"

# 手順2: VNCサーバーがポート5901でリッスンを開始するのを待つ (競合状態の防止)
echo "Waiting for VNC server to be ready on port 5901..."
while ! nc -z localhost 5901; do
  sleep 0.1 # 0.1秒待ってから再試行
done
echo "VNC server is ready."

# 手順3: VNCサーバーの準備が整ったら、noVNCプロキシをフォアグラウンドで起動する
# これがコンテナのメインプロセスとなり、コンテナを起動し続ける
echo "Starting noVNC proxy on port 6080..."
/usr/share/novnc/utils/novnc_proxy --listen 6080 --vnc localhost:5901
