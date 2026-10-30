---
title: Um app Electron que se atualiza sozinho
version: 1
---

**Uma loja atualiza um app de celular; um app de desktop baixado do seu site precisa se atualizar sozinho.** A aula 11
terminou no motivo de isso importar: um app Electron leva um Chromium, e as correções de segurança dele só chegam às
pessoas quando chega uma versão nova do app. O `electron-updater`, do mesmo projeto do electron-builder, é o caminho
de costume, e ele precisa de três coisas: um lugar que sirva os releases, um arquivo ali que diga qual é o mais
recente, e código no app que pergunte.

**O lugar é qualquer servidor web**, com o provedor `generic`: uma pasta de arquivos num endereço. O electron-builder
também conhece o GitHub Releases e o S3, que são a mesma ideia com uma conta. O do planner é
`http://localhost:8080/`, servido do seu próprio computador, para o ciclo inteiro poder ser acompanhado sem publicar
nada. A biblioteca vai para `dependencies`, porque o processo principal a carrega em tempo de execução, e o endereço
vai para a configuração:

```
ana@dev:~/planner$ npm install -E electron-updater@6.8.11 > /dev/null 2>&1
ana@dev:~/planner$ npm pkg set build.publish.provider=generic build.publish.url=http://localhost:8080/
ana@dev:~/planner$ git add . && git commit -q -m "Check for updates at start" && git log --oneline -1
a065bcf Check for updates at start
```

O código é um arquivo próprio, `electron/updater.mjs`, que o processo principal chama quando está pronto:

```javascript
// electron/updater.mjs: ask the release server whether a newer version exists, and fetch it.
import { app } from "electron";
import updater from "electron-updater";

export function checkForUpdates() {
  const { autoUpdater } = updater;
  autoUpdater.on("update-available", (info) => console.log(`update available: ${info.version}`));
  autoUpdater.on("update-not-available", (info) => console.log(`up to date: ${info.version}`));
  autoUpdater.on("update-downloaded", (info) => console.log(`downloaded ${info.version}; it installs on quit`));
  autoUpdater.on("error", (error) => console.log(`update failed: ${error.message}`));
  // Only a packaged app has a version to compare; npm start has nothing to replace.
  if (app.isPackaged) autoUpdater.checkForUpdates();
}
```

O `electron/main.mjs` ganha um import ao lado dos outros e uma chamada, a primeira coisa depois do `serveSite()`:

```javascript
import { checkForUpdates } from "./updater.mjs";
```

```javascript
  checkForUpdates();
```

**As linhas de `console.log` estão ali para serem lidas num terminal**; um app de verdade mostra à pessoa um aviso
discreto, ou nada, já que a atualização se instala sozinha quando o app fecha.

## Uma versão antiga, e uma nova

Para ver uma atualização, alguém precisa ter a versão antiga instalada. Gere a `0.2.0`, copie o AppImage dela para
outro lugar, como se uma pessoa o tivesse baixado, e depois lance a `0.3.0` com o comando da seção anterior:

```
ana@dev:~/planner$ rm -rf release && npx electron-builder --linux AppImage 2>&1 | grep -o "target=.*"
target=AppImage arch=x64 file=release/planner-0.2.0-x86_64.AppImage
ana@dev:~/planner$ mkdir ~/installed && cp release/planner-0.2.0-x86_64.AppImage ~/installed/
```

```
ana@dev:~/planner$ npm version minor

> version
> node scripts/version.mjs && git add android ios

version 0.3.0, build 300
v0.3.0
ana@dev:~/planner$ npx electron-builder --linux AppImage > /dev/null 2>&1; ls release
builder-debug.yml
latest-linux.yml
linux-unpacked
planner-0.2.0-x86_64.AppImage
planner-0.3.0-x86_64.AppImage
ana@dev:~/planner$ cat release/latest-linux.yml
version: 0.3.0
files:
  - url: planner-0.3.0-x86_64.AppImage
    sha512: oZimtcTzcMUGYgsQx8RfGs1dqw2huly6TaXz25UIs6utgqE19BTMC2CFOy+UQ2TSc6oDNWSTK2rxRhMOunraeg==
    size: 126764447
    blockMapSize: 132531
path: planner-0.3.0-x86_64.AppImage
sha512: oZimtcTzcMUGYgsQx8RfGs1dqw2huly6TaXz25UIs6utgqE19BTMC2CFOy+UQ2TSc6oDNWSTK2rxRhMOunraeg==
releaseDate: '2026-10-24T02:07:31.180Z'
```

**O `latest-linux.yml` é o arquivo que o app pede.** Ele diz qual é a versão mais nova, o arquivo a baixar, o
tamanho, e o **SHA-512** dele, o checksum que a aula 14 fez à mão, aqui feito pelo electron-builder em todo release.
Envie o AppImage e esse arquivo juntos, toda vez, ou o app continua encontrando o antigo.

## A atualização

Sirva a `release/` num segundo terminal com `python3 -m http.server 8080 --directory release`, e inicie a `0.2.0`
instalada:

```
ana@dev:~$ xvfb-run -a sh -c "APPIMAGE_EXTRACT_AND_RUN=1 timeout 40 installed/planner-0.2.0-x86_64.AppImage 2>/dev/null | grep -v appimage_extracted"
Found version 0.3.0 (url: planner-0.3.0-x86_64.AppImage)
update available: 0.3.0
Downloading update from planner-0.3.0-x86_64.AppImage
updater cache dir: /home/ana/.cache/planner-updater
New version 0.3.0 has been downloaded to /home/ana/.cache/planner-updater/pending/planner-0.3.0-x86_64.AppImage
downloaded 0.3.0; it installs on quit
Auto install update on quit
Install: isSilent: true, isForceRunAfter: false
```

**Ela perguntou, achou a `0.3.0`, baixou, e vai pô-la no lugar do arquivo instalado quando fechar.** As duas linhas
que vêm do `updater.mjs` são `update available` e `downloaded`; o resto é o log do próprio electron-updater. A
primeira linha dele, `Checking for update`, saiu na mesma linha que o fim da lista de arquivos do runtime, então o
`grep` que esconde a lista a levou junto. O `timeout` então parou o app, o que é um fechamento, e a próxima
abertura mostra o que aconteceu com o arquivo:

```
ana@dev:~$ ls installed
planner-0.3.0-x86_64.AppImage
ana@dev:~$ sha256sum installed/*.AppImage planner/release/planner-0.3.0-x86_64.AppImage | cut -c1-16,66-
acee15a1a238fe71 installed/planner-0.3.0-x86_64.AppImage
acee15a1a238fe71 planner/release/planner-0.3.0-x86_64.AppImage
```

**A `0.2.0` em `~/installed` sumiu, e a `0.3.0` está no lugar dela**, byte a byte o arquivo do servidor: o
atualizador troca o AppImage que a pessoa iniciou, na pasta onde ela o guarda, e como o nome antigo tinha a versão,
o arquivo novo leva o nome da versão nova. A próxima abertura roda a `0.3.0`.

**O checksum é conferido, não é enfeite.** Aqui um byte é acrescentado ao AppImage no servidor depois de o release
ter sido feito, como se alguém o tivesse trocado, e uma cópia nova da versão antiga pergunta de novo:

```
ana@dev:~$ rm -rf installed/* ~/.cache/planner-updater && cp planner/release/planner-0.2.0-x86_64.AppImage installed/
ana@dev:~$ printf x >> planner/release/planner-0.3.0-x86_64.AppImage
ana@dev:~$ xvfb-run -a sh -c "APPIMAGE_EXTRACT_AND_RUN=1 timeout 40 installed/planner-0.2.0-x86_64.AppImage 2>/dev/null | grep -E \"^(up to date|update)|sha512\" | cut -c1-110"
update available: 0.3.0
updater cache dir: /home/ana/.cache/planner-updater
update failed: sha512 checksum mismatch, expected oZimtcTzcMUGYgsQx8RfGs1dqw2huly6TaXz25UIs6utgqE19BTMC2CFOy+U
```

**O download foi recusado, e a versão instalada ficou como estava.** O SHA-512 no `latest-linux.yml` é o que torna
isso possível, e é também o limite dele: quem consegue mudar os dois arquivos no servidor consegue mudá-los de forma
coerente. No macOS e no Windows o electron-updater também confere a assinatura de código da versão nova contra a da
instalada, que é a garantia mais forte que a aula 14 comprou com um certificado.

## O atualizador do Tauri

O Tauri tem um plugin de atualização, o `@tauri-apps/plugin-updater`, e ele põe a assinatura no acordo: toda
atualização é assinada com uma chave própria, e o app recusa uma que não seja. A chave é criada pela CLI:

```
ana@dev:~/planner$ npx tauri signer generate --ci -p recording-machine-only -w ~/keys/planner-updater.key 2>&1 | grep -v "^ *$" | head -n 4
Your keypair was generated successfully:
Private: /home/ana/keys/planner-updater.key (Keep it secret!)
Public: /home/ana/keys/planner-updater.key.pub
---------------------------
ana@dev:~/planner$ ls ~/keys
planner-updater.key
planner-updater.key.pub
planner-upload.jks
```

**A chave pública vai para o `tauri.conf.json`**, em `plugins.updater.pubkey`, com o endereço de um `latest.json` em
`endpoints`; **a chave privada fica em `~/keys`** junto com o keystore do Android, e o build a lê da variável
`TAURI_SIGNING_PRIVATE_KEY` para assinar cada bundle. *O plugin não foi acrescentado ao planner: ele precisa de outro
build Rust e de um segundo app para atualizar, e o ciclo do Electron acima já mostrou cada passo.* A documentação do
Tauri tem o formato do `latest.json` e os lados Rust e JavaScript do plugin.
