# Dockerfile
# ベースイメージとしてKali Linuxの公式イメージを使用
FROM kalilinux/kali-rolling

# 環境変数を設定し、インストール中の対話を無効化
ENV DEBIAN_FRONTEND=noninteractive

# 必要なパッケージをインストール
# TigerVNC
RUN apt-get update && apt-get install -y \
    kali-desktop-xfce \
    tigervnc-standalone-server \
    dbus-x11 \
    x11-xserver-utils \
    xfce4-clipman \
    fonts-noto \
    novnc \
    netcat-openbsd \
    locales \
    sudo \
    # ロケールを設定して文字化けを解消
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

# コンテナ全体のデフォルト言語を設定
ENV LANG en_US.UTF-8

# 一般ユーザー 'kali' を作成し、パスワード 'kali' を設定
# sudoグループに追加
RUN useradd -m -s /bin/bash kali \
    && echo "kali:kali" | chpasswd \
    && adduser kali sudo

# VNCの設定ファイルを作成
# TigerVNCの新しい設定ディレクトリを直接作成し、移行処理を不要にします
RUN mkdir -p /home/kali/.config/tigervnc \
    && echo '#!/bin/sh' > /home/kali/.config/tigervnc/xstartup \
    && echo 'unset SESSION_MANAGER' >> /home/kali/.config/tigervnc/xstartup \
    && echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /home/kali/.config/tigervnc/xstartup \
    && echo 'vncconfig -nowin &' >> /home/kali/.config/tigervnc/xstartup \
    && echo 'xfce4-clipman &' >> /home/kali/.config/tigervnc/xstartup \
    && echo 'dbus-launch --exit-with-session startxfce4' >> /home/kali/.config/tigervnc/xstartup \
    && chown -R kali:kali /home/kali/.config \
    && chmod 755 /home/kali/.config/tigervnc/xstartup

# TO:DO
# - noVNCのデフォルトスケーリングモードを「Remote Resizing」に変更

# 環境変数を設定
ENV HOME /home/kali
ENV USER kali

# コンテナ起動時に実行するスクリプトをコピー
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# コンテナ起動
ENTRYPOINT ["/entrypoint.sh"]
