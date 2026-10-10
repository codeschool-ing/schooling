---
title: Instalando o Android Studio e um emulador
version: 1
---

**O Android Studio é instalado a partir de developer.android.com, e todo o resto vem por ele.** É um
programa de desktop com janelas e assistentes, e não pôde rodar na máquina onde este curso foi
gravado, então os passos abaixo são descritos, não mostrados. As ferramentas de linha de comando que
ele instala puderam rodar ali, e as transcrições delas são reais.

## O Android Studio e o SDK

1. Baixe o Android Studio de developer.android.com/studio para o seu sistema e instale: um
   instalador no Windows e no macOS, um arquivo compactado no Linux cujo `bin/studio.sh` o inicia.
2. A primeira abertura roda um assistente. Escolha a instalação *Standard*. Ela baixa o SDK, o
   emulador e uma plataforma Android recente, alguns gigabytes, numa pasta que ela nomeia no fim:
   `~/Android/Sdk` no Linux, `~/Library/Android/sdk` num Mac e `AppData\Local\Android\Sdk` na sua
   pasta de usuário no Windows.
3. Abra *Settings*, depois *Languages & Frameworks › Android SDK*. Em *SDK Platforms*, marque
   **Android 15.0 (API 35)**, a versão contra a qual o app da seção 05 foi compilado. Em *SDK Tools*,
   confira que *Android SDK Platform-Tools* e *Android Emulator* estão marcados.

As ferramentas de linha de comando do SDK são o que este curso digita, então diga ao seu terminal
onde elas ficam. No Linux, acrescente estas linhas ao `~/.bashrc` e abra um terminal novo (num Mac,
as mesmas linhas com o caminho do Mac, no `~/.zshrc`; no Windows, a página *SDK Manager* do Android
Studio mostra o caminho a acrescentar à variável `Path` do usuário):

```sh
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator
```

Duas ferramentas respondem dali. O **adb**, Android Debug Bridge, é como o seu computador conversa
com qualquer aparelho, emulador ou celular: instala apps, roda comandos de shell no aparelho,
encaminha portas e coleta logs. O **emulator** inicia aparelhos virtuais:

```
ana@laptop:~$ adb version
Android Debug Bridge version 1.0.41
Version 36.0.0-13206524
Installed as /home/ana/Android/Sdk/platform-tools/adb
Running on Linux 6.18.44-fc-v114 (x86_64)
ana@laptop:~$ emulator -version | head -1
Android emulator version 36.1.9.0 (build_id 13823996) (CL:N/A)
```

## Um aparelho virtual

Um emulador roda um **AVD**, um Android Virtual Device: a descrição de um celular (tela, memória,
botões) mais uma imagem de sistema, o Android que ele inicia.

1. No Android Studio, abra o *Device Manager* e aperte *Create Virtual Device*.
2. Escolha o **Pixel 8** na lista *Phone*, ou qualquer celular com tela de umas seis polegadas.
3. Escolha a imagem de sistema **API 35**, *Google APIs*, para o seu processador: *x86_64* num
   computador Intel ou AMD, *arm64-v8a* num Mac com Apple silicon. Baixe quando pedir, uns 1,5 GB.
4. Dê o nome `Pixel_8_API_35` e conclua. Aperte o botão de play ao lado para iniciá-lo.

A primeira inicialização leva um ou dois minutos e as seguintes alguns segundos. Enquanto ele roda, o
adb o lista como um aparelho chamado `emulator-5554`, e a linha de comando o inicia sem o Android
Studio: `emulator -avd Pixel_8_API_35`.

Na máquina de gravação não há emulador nem aparelho, então os dois comandos que os listariam voltam
vazios. No seu, depois dos passos acima, o primeiro lista `emulator-5554` com a palavra `device` ao
lado e o segundo lista `Pixel_8_API_35`:

```
ana@laptop:~$ adb devices
* daemon not running; starting now at tcp:5037
* daemon started successfully
List of devices attached

ana@laptop:~$ emulator -list-avds
```

## Como o emulador chega ao boxoffice

Dentro do emulador, `localhost` é o próprio emulador, não o seu computador. **O emulador dá ao seu
computador um endereço fixo, `10.0.2.2`**, e uma requisição do app a `http://10.0.2.2:8080` chega ao
boxoffice na porta 8080 do seu computador:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 240\" role=\"img\" aria-label=\"O boxoffice roda no seu computador e escuta em localhost, porta 8080. Dentro do emulador, localhost significa o próprio emulador. O Tickets pergunta a http://10.0.2.2:8080, e o emulador entrega essa requisição ao computador em que roda, onde o boxoffice responde.\"><defs><marker id=\"f14addresses-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"300\" height=\"170\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"170\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">seu computador</text><rect x=\"45\" y=\"120\" width=\"250\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">boxoffice</text><text x=\"170\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">localhost:8080</text><rect x=\"380\" y=\"30\" width=\"300\" height=\"170\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"530\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o emulador</text><rect x=\"405\" y=\"120\" width=\"250\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"530\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Tickets</text><text x=\"530\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">http://10.0.2.2:8080</text><rect x=\"405\" y=\"62\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"530\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">localhost</text><text x=\"530\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o próprio emulador, não o seu computador</text><line x1=\"403\" y1=\"145\" x2=\"297\" y2=\"145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f14addresses-ah)\"></line><text x=\"350\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">10.0.2.2</text><text x=\"350\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10.0.2.2 é o endereço que o emulador dá ao computador em que roda</text></svg>", "caption": "Dentro do emulador, localhost é o emulador; o seu computador é 10.0.2.2.", "same": ["Tickets"]}
```

Um celular no cabo não tem esse endereço. `adb reverse tcp:8080 tcp:8080` faz a porta 8080 do próprio
celular levar à do seu computador, e o app passa a usar `http://localhost:8080`; a seção 05 diz que
linha mudar. Esse comando não foi executado para este curso, por não haver celular contra o qual
executá-lo.
