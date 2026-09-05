#!/usr/bin/env bash
# Instala ou atualiza o soundloop em ~/.soundloop. Não inicia nada sozinho.
set -euo pipefail
DEST=$HOME/.soundloop
mkdir -p "$DEST"
curl -fsSL https://github.com/bzangi/soundloop/archive/refs/heads/main.tar.gz | tar xz -C "$DEST" --strip-components=1
chmod +x "$DEST/soundloop"
echo "soundloop instalado em $DEST (nada foi iniciado)."
echo
"$DEST/soundloop" help
