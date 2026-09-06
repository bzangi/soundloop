# soundloop

Toca um som aleatório em background, em intervalos aleatórios. Brincadeira de escritório: **consensual, visível e parável**. Quem instala sabe o que é, sabe que **toca mesmo com o Mac no mudo**, e sabe como parar. Só macOS.

## Instalar

```sh
curl -fsSL https://raw.githubusercontent.com/bzangi/soundloop/main/install.sh | bash
```

Baixa o repo pra `~/.soundloop`. **Nada é iniciado automaticamente.** Quer ler antes de rodar: [install.sh](install.sh). Pra atualizar, rode o mesmo comando de novo.

## Comandos

| Comando | Faz |
|---|---|
| `~/.soundloop/soundloop start` | inicia em background no modo `ramp`: começa com 15 min entre sons e aperta 10% a cada som, até 30s (~2h30 de rampa) |
| `~/.soundloop/soundloop start normal` | 90–210s entre sons, fixo |
| `~/.soundloop/soundloop start slow` | modo lento (30–50 min entre sons) |
| `~/.soundloop/soundloop start fast` | modo rápido (10–13s entre sons) |
| `~/.soundloop/soundloop start 5-10` | intervalo custom, em segundos |
| `~/.soundloop/soundloop start fast 30%` | modo rápido a 30% do volume do Mac (default: 60%) |
| `~/.soundloop/soundloop start lazy` | primeiro som só depois de 20 min; combina com qualquer modo |
| `~/.soundloop/soundloop stop` | para (o som em curso termina sozinho) |
| `~/.soundloop/soundloop status` | rodando/parado, PID, modo, autostart |
| `~/.soundloop/soundloop enable-autostart` | inicia sozinho no login |
| `~/.soundloop/soundloop disable-autostart` | remove do login |
| `~/.soundloop/soundloop uninstall` | para, remove do login e apaga `~/.soundloop` |

Os argumentos do `start` vão em qualquer ordem (`start slow 40% lazy`). Sem argumentos = ramp, 60%, sem lazy. `enable-autostart` usa as opções do último `start`.

## Como funciona

- Cada ciclo: sorteia um som de `assets/` (sempre diferente do anterior), toca com `afplay`, espera um intervalo aleatório, repete. Um som por vez, sem sobreposição.
- O loop roda como serviço do `launchd` (label `com.bzangi.soundloop`). `status` mostra o PID. Log em `~/.soundloop/soundloop.log`.
- Autostart é um plist em `~/Library/LaunchAgents/`; o macOS lista em Ajustes do Sistema › Geral › Itens de Início. Só existe se você rodar `enable-autostart`.
- Toca a 60% do volume atual do Mac por padrão; `N%` no `start` muda.
- **Toca mesmo com o Mac no mudo.** Na hora do som: desmuta com o volume do sistema limitado a 30%, toca, volta ao mudo e restaura o volume. `stop` no meio de um som espera o som acabar e restaura também. Só `kill -9` no meio de um som deixa o Mac desmutado.
- Zero dependências: `bash`, `afplay` e `launchctl` já vêm no macOS.

## Sons

Qualquer arquivo que o `afplay` toque (mp3, m4a, wav, aiff) dentro de `~/.soundloop/assets/`. Pode jogar arquivos lá com o loop rodando: o próximo sorteio já considera.

Pra entrar no pacote de todo mundo, commita em `assets/` do repo (nome sem espaços). Quem já instalou pega rodando o install de novo.

## Remover

```sh
~/.soundloop/soundloop uninstall
```

## Dev

`./test.sh` roda os testes (~40s): usa um label launchd separado, põe o volume do Mac em 5% e desmutado, muta de propósito no bloco do override, e restaura o estado original no fim. Os sons de teste são audíveis.
