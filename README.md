# soundloop

Toca um som aleatório em background, em intervalos aleatórios. Brincadeira de escritório: **consensual, visível e parável**. Quem instala sabe o que é e como parar. Só macOS.

## Instalar

```sh
curl -fsSL https://raw.githubusercontent.com/bzangi/soundloop/main/install.sh | bash
```

Baixa o repo pra `~/.soundloop`. **Nada é iniciado automaticamente.** Quer ler antes de rodar: [install.sh](install.sh). Pra atualizar, rode o mesmo comando de novo.

## Comandos

| Comando | Faz |
|---|---|
| `~/.soundloop/soundloop start` | inicia em background (90–210s entre sons) |
| `~/.soundloop/soundloop start slow` | modo lento (30–50 min entre sons) |
| `~/.soundloop/soundloop start 5-10` | intervalo custom, em segundos |
| `~/.soundloop/soundloop stop` | para (o som em curso termina sozinho) |
| `~/.soundloop/soundloop status` | rodando/parado, PID, modo, autostart |
| `~/.soundloop/soundloop enable-autostart` | inicia sozinho no login |
| `~/.soundloop/soundloop disable-autostart` | remove do login |
| `~/.soundloop/soundloop uninstall` | para, remove do login e apaga `~/.soundloop` |

## Como funciona

- Cada ciclo: sorteia um som de `assets/` (sempre diferente do anterior), toca com `afplay`, espera um intervalo aleatório, repete. Um som por vez, sem sobreposição.
- O loop roda como serviço do `launchd` (label `com.bzangi.soundloop`). `status` mostra o PID. Log em `~/.soundloop/soundloop.log`.
- Autostart é um plist em `~/Library/LaunchAgents/`; o macOS lista em Ajustes do Sistema › Geral › Itens de Início. Só existe se você rodar `enable-autostart`.
- Zero dependências: `bash`, `afplay` e `launchctl` já vêm no macOS.

## Sons

Qualquer arquivo que o `afplay` toque (mp3, m4a, wav, aiff) dentro de `~/.soundloop/assets/`. Pode jogar arquivos lá com o loop rodando: o próximo sorteio já considera.

## Remover

```sh
~/.soundloop/soundloop uninstall
```

## Dev

`./test.sh` roda os testes (usa um label launchd separado e toca os samples algumas vezes, ~20s).
