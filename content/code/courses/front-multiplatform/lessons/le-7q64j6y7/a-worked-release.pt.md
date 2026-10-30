---
title: Um release, da tag ao download
version: 1
---

**O release do próprio planner é o exemplo resolvido: `v0.3.0`, a tag que a aula 15 criou.** Todo comando abaixo é
um que você já viu; o ponto desta seção é a ordem, e o que uma pasta de release pronta contém. Primeiro o
repositório, porque um release é gerado a partir de um commit que todo mundo consegue encontrar de novo:

```
ana@dev:~/planner$ git log --oneline | wc -l
14
ana@dev:~/planner$ git log --oneline | head -n 8
de97f95 0.3.0
a065bcf Check for updates at start
7519a04 0.2.0
b876c9c One version, in package.json
531775b Keep signing keys out of the repository
926f02e Icons, and the Electron packages
676a8f1 The planner as a desktop app, with Tauri
ea58854 The planner as a desktop app, with Electron
ana@dev:~/planner$ git describe --tags
v0.3.0
```

**Catorze commits, um para cada passo que o planner deu neste curso, e o `git describe` diz que o código está
exatamente na tag.** Um release gerado de um commit sem tag, ou de uma árvore com mudanças que ninguém pôs num
commit, não pode ser gerado de novo, e um relato de bug contra ele não pode ser reproduzido.

## Os pacotes

Gerados a partir desse commit, com a configuração da aula 13. O build do Tauri está aqui só para mostrar o que a aula
15 prometeu: a versão dele agora vem do `package.json`, sem nada editado à mão:

```
ana@dev:~/planner$ npm run build > /dev/null && npx electron-builder --linux 2>&1 | grep -o "target=.*"
target=AppImage arch=x64 file=release/planner-0.3.0-x86_64.AppImage
target=deb arch=x64 file=release/planner-0.3.0-amd64.deb
ana@dev:~/planner$ npx tauri build --bundles deb 2>&1 | tail -n 2
        /home/ana/planner/src-tauri/target/release/bundle/deb/planner_0.3.0_amd64.deb (2.82 MiB)

ana@dev:~/planner$ dpkg-deb -f src-tauri/target/release/bundle/deb/planner_0.3.0_amd64.deb Version
0.3.0
```

## A pasta

Uma pasta de release contém o que a pessoa baixa, e os meios de conferi-lo. As notas são um arquivo de texto simples,
escrito para pessoas, dizendo o que mudou, o `RELEASE-NOTES.md`:

```
# Study planner 0.3.0

## What changed
- The desktop app checks for a new version when it starts, and installs it when it quits.
- One version number for every platform: 0.3.0 here, build 300 on Android and iOS.

## Install
- AppImage, any Linux: make it executable with `chmod +x` and run it.
- .deb, Ubuntu and Debian: `sudo apt install ./planner-0.3.0-amd64.deb`.

## Check the download
    gpg --import planner-signing-key.asc
    gpg --verify SHA256SUMS.asc SHA256SUMS
    sha256sum -c SHA256SUMS

## Not in this release
No Windows or macOS package, and no store: they were not built.
```

Depois os checksums e a assinatura, como na aula 14, com a chave que a aula 14 criou:

```
ana@dev:~/planner$ mkdir ~/release-0.3.0 && cp release/planner-0.3.0-x86_64.AppImage release/planner-0.3.0-amd64.deb release/latest-linux.yml ~/release-0.3.0/
ana@dev:~/release-0.3.0$ sha256sum planner-0.3.0-x86_64.AppImage planner-0.3.0-amd64.deb > SHA256SUMS
ana@dev:~/release-0.3.0$ gpg --batch --pinentry-mode loopback --passphrase "$KEY_PASS" --armor --detach-sign SHA256SUMS
ana@dev:~/release-0.3.0$ gpg --armor --export ana@example.com > planner-signing-key.asc
ana@dev:~/release-0.3.0$ ls -sh1
total 218M
4.0K RELEASE-NOTES.md
4.0K SHA256SUMS
4.0K SHA256SUMS.asc
4.0K latest-linux.yml
 97M planner-0.3.0-amd64.deb
121M planner-0.3.0-x86_64.AppImage
4.0K planner-signing-key.asc
```

**Sete arquivos**: os dois pacotes, o `latest-linux.yml` para o atualizador da aula 15, as notas, a lista de
checksums, a assinatura dela e a chave pública. Envie os sete juntos, onde quer que o release fique. A última
conferência é a que um desconhecido faz, numa pasta própria:

```
ana@dev:~$ mkdir download && cp release-0.3.0/* download/ && cd download && gpg --verify SHA256SUMS.asc SHA256SUMS 2>&1 | grep -E "Good|BAD" && sha256sum -c SHA256SUMS
gpg: Good signature from "Ana <ana@example.com>" [ultimate]
planner-0.3.0-x86_64.AppImage: OK
planner-0.3.0-amd64.deb: OK
```

**Um release que o próprio autor conferiu como um desconhecido conferiria** é um que a próxima seção pode pôr na
frente das pessoas.
