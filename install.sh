#!/usr/bin/env bash
# Instala ou atualiza o soundloop em ~/.soundloop e já inicia com lazy (primeiro som só depois de 30min).
set -euo pipefail
DEST=$HOME/.soundloop
mkdir -p "$DEST"
curl -fsSL https://github.com/bzangi/soundloop/archive/refs/heads/main.tar.gz | tar xz -C "$DEST" --strip-components=1
chmod +x "$DEST/soundloop"
echo "soundloop instalado em $DEST."
"$DEST/soundloop" start lazy || true   # ponytail: || true porque numa reinstalação o start recusa se já estiver rodando
echo
"$DEST/soundloop" help
