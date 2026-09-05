#!/usr/bin/env bash
# Smoke check. Roda: ./test.sh
set -u
cd "$(dirname "$0")"
fail=0
ok()  { echo "ok   $1"; }
bad() { echo "FAIL $1"; fail=1; }

source ./soundloop

# gap_seconds: faixa por modo, faixa custom MIN-MAX
in_range() { local lo=$1 hi=$2 v; for _ in $(seq 200); do v=$(gap_seconds "$3"); [[ $v =~ ^[0-9]+$ ]] && (( v >= lo && v <= hi )) || return 1; done; }
in_range 90 210 normal    && ok "gap normal 90-210s"     || bad "gap normal fora da faixa"
in_range 1800 3000 slow   && ok "gap slow 1800-3000s"    || bad "gap slow fora da faixa"
in_range 5 6 5-6          && ok "gap custom 5-6"         || bad "gap custom fora da faixa"

# pick_next: nunca repete o anterior com >=2, repete quando só há 1, cobre todos os outros
rep=0; for _ in $(seq 200); do v=$(pick_next b a b c); [[ $v == a || $v == c ]] || rep=1; done
(( rep == 0 )) && ok "pick_next não repete o anterior" || bad "pick_next repetiu o anterior"
[[ $(pick_next a a) == a ]] && ok "pick_next único repete" || bad "pick_next único"
seen=$(for _ in $(seq 300); do pick_next d a b c d; done | sort -u | tr -d '\n')
[[ $seen == abc ]] && ok "pick_next cobre todos os outros" || bad "pick_next cobertura: '$seen'"


# --- integração: cópia isolada, label de teste, gap curto (toca os samples ~3x, ~20s) ---
export SOUNDLOOP_LABEL=com.bzangi.soundloop.test
LA=~/Library/LaunchAgents/$SOUNDLOOP_LABEL.plist
T=$(mktemp -d); trap 'launchctl bootout gui/$UID/$SOUNDLOOP_LABEL 2>/dev/null; rm -f "$LA"; rm -rf "$T"' EXIT
cp -R . "$T/app"; rm -rf "$T/app/.git"; APP=$T/app/soundloop; APPLOG=$T/app/soundloop.log
find "$T/app/assets" -type f ! -name windows-error.mp3 ! -name notif-zapzap.mp3 -delete   # só os 2 sons curtos: mantém o teste em ~20s

$APP status | grep -q '^parado' && ok "status inicial: parado" || bad "status inicial"
$APP start 1-2 | grep -q "^rodando" && ok "start" || bad "start"
$APP start 1-2 >/dev/null 2>&1 && bad "start duplo aceito" || ok "start duplo recusado"
$APP status | grep -q '^rodando (PID [0-9]' && ok "status: rodando com PID" || bad "status rodando"
sleep 12   # afplay tem ~1s de overhead por execução
n=$(grep -c 'tocou' "$APPLOG" 2>/dev/null); (( n >= 2 )) && ok "log: tocou $n vezes" || bad "log: tocou só $n vezes"
grep -q "erro ao tocar" "$APPLOG" && bad "log tem erro do afplay" || ok "log sem erro do afplay"
$APP stop | grep -q "^parado" && ok "stop" || bad "stop"
$APP status | grep -q '^parado' && ok "status após stop: parado" || bad "status após stop"
$APP start foo >/dev/null 2>&1 && bad "modo inválido aceito" || ok "modo inválido recusado"
$APP start 9-3 >/dev/null 2>&1 && bad "faixa invertida aceita" || ok "faixa invertida recusada"
$APP start slow >/dev/null && $APP status | grep -q 'modo slow' && ok "start slow: modo slow no status" || bad "modo slow"
(( $(grep -c 'iniciado' "$APPLOG") >= 2 )) && ok "log acumula entre starts" || bad "log foi truncado"
$APP stop >/dev/null
$APP enable-autostart >/dev/null && [[ -f $LA ]] && ok "enable-autostart cria plist em LaunchAgents" || bad "enable-autostart"
$APP status | grep -q 'autostart: on' && ok "status: autostart on" || bad "status autostart on"
$APP disable-autostart >/dev/null && [[ ! -e $LA ]] && ok "disable-autostart remove plist" || bad "disable-autostart"
$APP status | grep -q 'autostart: off' && ok "status: autostart off" || bad "status autostart off"

cp -R "$T/app" "$T/empty"; rm -f "$T/empty"/assets/*
"$T/empty/soundloop" start 1-2 >/dev/null 2>&1 && bad "start sem áudios aceito" || ok "start sem áudios falha"
"$T/empty/soundloop" stop >/dev/null 2>&1

mkdir -p "$T/g/.git"; cp soundloop "$T/g/"
"$T/g/soundloop" uninstall >/dev/null 2>&1 && bad "uninstall apagou um checkout git" || ok "uninstall recusa checkout git"
[[ -d $T/g ]] || bad "uninstall apagou a pasta do checkout"
$APP uninstall >/dev/null && [[ ! -d $T/app ]] && ok "uninstall apaga a pasta" || bad "uninstall"

(( fail == 0 )) && echo "TUDO OK" || { echo "FALHOU"; exit 1; }
