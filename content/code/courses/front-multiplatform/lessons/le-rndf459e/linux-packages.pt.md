---
title: Os pacotes do Linux, abertos e comparados
version: 1
---

**Um AppImage é executado, não instalado**: ele vira executável, o que o electron-builder já fez, e é iniciado
como qualquer programa. Num desktop, você clica duas vezes nele. A máquina de gravação não tinha tela, e um
contêiner não tem FUSE, a parte do Linux que um AppImage usa para se montar, então ele rodou com
`APPIMAGE_EXTRACT_AND_RUN=1`, que o desempacota numa pasta temporária em vez disso, e no Xvfb:

```
ana@dev:~/planner$ xvfb-run -a sh -c "APPIMAGE_EXTRACT_AND_RUN=1 timeout 12 release/*.AppImage > /dev/null 2>&1 & sleep 10; xwininfo -root -tree | grep -o \"Study planner.*\" | head -n 1"
Study planner": ("planner" "planner")  900x700+190+162  +190+162
```

**A janela está lá, com o título do planner, nos 900 por 700 do Electron.** Nada no app mudou entre o
`npm start` e o AppImage; o que mudou é que quem o roda não precisa de Node, de npm nem de projeto.

## O que um `.deb` pede ao computador

Um `.deb` é instalado com `sudo apt install ./planner-0.1.0-amd64.deb`, e o `apt` lê antes os campos de
controle do pacote. O `dpkg-deb -f` os imprime sem instalar nada. O pacote Tauri da aula 12 é gerado de novo
aqui, só com o `.deb` desta vez, porque agora ele leva o ícone novo:

```
ana@dev:~/planner$ npx tauri build --bundles deb 2>&1 | tail -n 2
        /home/ana/planner/src-tauri/target/release/bundle/deb/planner_0.1.0_amd64.deb (2.82 MiB)

ana@dev:~/planner$ dpkg-deb -f release/*.deb Package Version Depends
Package: planner
Version: 0.1.0
Depends: libgtk-3-0, libnotify4, libnss3, libxss1, libxtst6, xdg-utils, libatspi2.0-0, libuuid1, libsecret-1-0
ana@dev:~/planner$ dpkg-deb -f src-tauri/target/release/bundle/deb/planner_0.1.0_amd64.deb Package Version Depends
Package: planner
Version: 0.1.0
Depends: libwebkit2gtk-4.1-0, libgtk-3-0
```

**Os dois pacotes citam o GTK, e só o do Tauri cita o WebKitGTK**, que é a troca da aula 12 escrita no pacote: o
Electron leva o próprio navegador e pede ao sistema as bibliotecas em volta de uma janela, das notificações e do
chaveiro; o Tauri pede ao sistema o próprio navegador. No Ubuntu 24.04 todas elas estão no repositório, então o
`apt` instala o que faltar e a pessoa nunca vê uma lista.

## Qual distribuir

| | AppImage | `.deb` | `.rpm` |
|---|---|---|---|
| roda em | na maioria das distribuições, como arquivo | Debian, Ubuntu e a família deles | Fedora, openSUSE e a família deles |
| instalado por | ninguém: vira executável e roda | `apt` | `dnf` ou `zypper` |
| uma entrada no menu | só se a pessoa ou um auxiliar a criar | sim | sim |
| removido por | apagar o arquivo | `apt remove planner` | `dnf remove planner` |
| atualizado por | ele mesmo, ou um novo download (aula 15) | um pacote novo, ou um repositório | um pacote novo, ou um repositório |
| o planner do Electron | 121 MB | 97 MB | não gerado aqui |
| o planner do Tauri | 77,85 MiB, na aula 12 | 2,82 MiB | 2,86 MiB, na aula 12 |

**Num primeiro release, ofereça o AppImage e o `.deb`**: um roda em qualquer lugar e o outro se instala direito
na família que a maioria das pessoas usa. O Linux também tem lojas próprias, o Flathub e a Snap Store, que
recebem um pacote nos formatos delas, Flatpak e Snap; *nenhum dos dois foi gerado para este curso*, e a
documentação das duas ferramentas tem uma página sobre eles.

O projeto vai para o git com a `release/` ignorada, como o `src-tauri/target` já era, porque um pacote é gerado a
partir do código e nunca guardado ao lado dele:

```
ana@dev:~/planner$ echo release/ >> .gitignore
ana@dev:~/planner$ git add . && git commit -q -m "Icons, and the Electron packages" && git log --oneline -1
926f02e Icons, and the Electron packages
```
