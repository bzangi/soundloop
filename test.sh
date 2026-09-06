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
in_range 10 13 fast       && ok "gap fast 10-13s"        || bad "gap fast fora da faixa"
T=$RAMP_DURATION; ramp=$(for t in 0 $((T/4)) $((T/2)) $T $((T*2)); do gap_seconds ramp $t; done | tr '\n' ' ')
[[ $ramp == "900 845 682 30 30 " ]] && ok "gap ramp quadrático no tempo (ease-in): 900 → 845 (T/4) → 682 (T/2) → 30 (T), clamp após T" || bad "gap ramp: '$ramp'"
in_range 5 6 5-6          && ok "gap custom 5-6"         || bad "gap custom fora da faixa"

[[ $(pct_to_gain 60) == 0.60 && $(pct_to_gain 100) == 1.00 && $(pct_to_gain 5) == 0.05 ]] && ok "pct_to_gain 60/100/5" || bad "pct_to_gain: $(pct_to_gain 60) $(pct_to_gain 100) $(pct_to_gain 5)"

parse_volume_settings "output volume:75, input volume:48, alert volume:100, output muted:true" && [[ $SYS_VOL == 75 && $SYS_MUTED == true ]] && ok "parse_volume_settings" || bad "parse_volume_settings: vol='${SYS_VOL-}' muted='${SYS_MUTED-}'"

# pick_next: nunca repete o anterior com >=2, repete quando só há 1, cobre todos os outros
rep=0; for _ in $(seq 200); do v=$(pick_next b a b c); [[ $v == a || $v == c ]] || rep=1; done
(( rep == 0 )) && ok "pick_next não repete o anterior" || bad "pick_next repetiu o anterior"
[[ $(pick_next a a) == a ]] && ok "pick_next único repete" || bad "pick_next único"
seen=$(for _ in $(seq 300); do pick_next d a b c d; done | sort -u | tr -d '\n')
[[ $seen == abc ]] && ok "pick_next cobre todos os outros" || bad "pick_next cobertura: '$seen'"


# --- integração: cópia isolada, label de teste, gap curto (toca os samples ~3x, ~20s) ---
export SOUNDLOOP_LABEL=com.bzangi.soundloop.test
LA=~/Library/LaunchAgents/$SOUNDLOOP_LABEL.plist
ORIG_VOL=$(osascript -e 'output volume of (get volume settings)'); ORIG_MUTED=$(osascript -e 'output muted of (get volume settings)')
T=$(mktemp -d); trap 'launchctl bootout gui/$UID/$SOUNDLOOP_LABEL 2>/dev/null; rm -f "$LA"; rm -rf "$T"; osascript -e "set volume output volume $ORIG_VOL" -e "set volume output muted $ORIG_MUTED"' EXIT
TEST_VOL=5; osascript -e "set volume output volume $TEST_VOL" -e 'set volume output muted false'   # baixo e desmutado pros testes gerais; o bloco do mudo muta de propósito
cp -R . "$T/app"; rm -rf "$T/app/.git"; APP=$T/app/soundloop; APPLOG=$T/app/soundloop.log
find "$T/app/assets" -type f ! -name windows-error.mp3 ! -name notif-zapzap.mp3 ! -name discord-join.mp3 -delete   # só sons curtos
cp "$T/app/assets/windows/windows-error.mp3" "$T/app/assets/stop.mp3"   # risada de 7s vira som de 1s nos testes

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
$APP start slow >/dev/null && $APP status | grep -q 'modo slow, volume 60%' && ok "start slow: modo slow, volume default 60%" || bad "start slow / volume default: $($APP status | head -1)"
$APP stop >/dev/null; $APP start fast 30% >/dev/null && $APP status | grep -q 'modo fast, volume 30%' && ok "start fast 30%: modo e volume no status" || bad "start fast 30%: $($APP status | head -1)"
$APP stop >/dev/null; $APP start 45% >/dev/null && $APP status | grep -q 'modo ramp, volume 45%' && ok "start 45%: modo default ramp, volume 45%" || bad "start 45%: $($APP status | head -1)"
$APP stop >/dev/null; $APP start 150% >/dev/null 2>&1 && bad "volume >100% aceito" || ok "volume >100% recusado"
n1=$(grep -c tocou "$APPLOG"); $APP start fast lazy >/dev/null && $APP status | grep -q 'modo fast, volume 60%, lazy' && ok "start fast lazy: lazy no status" || bad "start fast lazy: $($APP status | head -1)"
sleep 3; (( $(grep -c tocou "$APPLOG") == n1 )) && grep -q 'lazy' "$APPLOG" && ok "lazy: nada tocou nos 3s iniciais e log avisa" || bad "lazy: tocou ou não logou"
$APP stop >/dev/null
(( $(grep -c 'iniciado' "$APPLOG") >= 2 )) && ok "log acumula entre starts" || bad "log foi truncado"
$APP stop >/dev/null
# --- pacotes: subpastas de assets/; start <pacote> toca só ele; stop toca stop.mp3 ---
n1=$(grep -c tocou "$APPLOG"); $APP start discord 1-2 >/dev/null && $APP status | grep -q 'pacote discord' && ok "start discord: pacote no status" || bad "start discord: $($APP status | head -1)"
sleep 5; $APP stop >/dev/null
novos=$(grep tocou "$APPLOG" | tail -n +$((n1+1)) | grep -v 'stop:'); [[ -n $novos && -z $(grep -v 'discord-' <<<"$novos") ]] && ok "pacote discord: só tocou discord-*" || bad "pacote discord: tocou: $novos"
grep -q 'stop: tocou stop.mp3' "$APPLOG" && ok "stop toca stop.mp3 e loga" || bad "stop não logou stop.mp3"

# --- override do mudo: muta o Mac, roda ~1 ciclo, confere marca no log e estado restaurado ---
osascript -e 'set volume output muted true'
$APP start 1-2 >/dev/null; sleep 6; $APP stop >/dev/null; sleep 4
grep -qE "Mac no mudo: toquei a ${TEST_VOL}% e voltei ao mudo" "$APPLOG" && ok "mudo: desmutou, tocou com min(volume,30%)=${TEST_VOL}% e logou" || bad "mudo: sem marca no log"
[[ $(osascript -e 'output muted of (get volume settings)') == true ]] && ok "mudo: voltou ao mudo no fim" || bad "mudo: ficou desmutado"
[[ $(osascript -e 'output volume of (get volume settings)') == "$TEST_VOL" ]] && ok "mudo: volume do sistema restaurado ($TEST_VOL)" || bad "mudo: volume virou $(osascript -e 'output volume of (get volume settings)')"
osascript -e 'set volume output muted false'

$APP enable-autostart >/dev/null && [[ -f $LA ]] && ok "enable-autostart cria plist em LaunchAgents" || bad "enable-autostart"
$APP status | grep -q 'autostart: on' && ok "status: autostart on" || bad "status autostart on"
$APP disable-autostart >/dev/null && [[ ! -e $LA ]] && ok "disable-autostart remove plist" || bad "disable-autostart"
$APP status | grep -q 'autostart: off' && ok "status: autostart off" || bad "status autostart off"

cp -R "$T/app" "$T/empty"; rm -rf "$T/empty"/assets/*
"$T/empty/soundloop" start 1-2 >/dev/null 2>&1 && bad "start sem áudios aceito" || ok "start sem áudios falha"
"$T/empty/soundloop" stop >/dev/null 2>&1

mkdir -p "$T/g/.git"; cp soundloop "$T/g/"
"$T/g/soundloop" uninstall >/dev/null 2>&1 && bad "uninstall apagou um checkout git" || ok "uninstall recusa checkout git"
[[ -d $T/g ]] || bad "uninstall apagou a pasta do checkout"
$APP uninstall >/dev/null && [[ ! -d $T/app ]] && ok "uninstall apaga a pasta" || bad "uninstall"

(( fail == 0 )) && echo "TUDO OK" || { echo "FALHOU"; exit 1; }
