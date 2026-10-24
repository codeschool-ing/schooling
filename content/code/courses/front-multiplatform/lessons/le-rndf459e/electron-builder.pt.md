---
title: Empacotando o Electron com o electron-builder
version: 1
---

**O Electron não tem um comando de empacotamento próprio; o app Electron do planner vira um pacote com o
`electron-builder`**, a ferramenta que a maioria dos apps Electron usa, aqui na versão 26.18.0. Ele copia o
runtime do Electron, põe os arquivos do app ao lado dele num arquivo só, e embrulha o resultado nos formatos
pedidos. A primeira execução, sem configuração nenhuma, mostra o que ele faz quando ninguém lhe diz nada:

```
ana@dev:~/planner$ npm install -E -D electron-builder@26.18.0 > /dev/null 2>&1
ana@dev:~/planner$ npx electron-builder --linux AppImage > /dev/null 2>&1; ls dist
assets
builder-debug.yml
courses.json
index.html
linux-unpacked
planner-0.0.0.AppImage
ana@dev:~/planner$ rm -rf dist && npm run build > /dev/null && ls dist
assets
courses.json
index.html
```

**Ele escreveu o AppImage na `dist/`, a pasta onde o Vite gera o site.** `dist` é a pasta de saída padrão do
electron-builder, e o site do planner já mora ali. Deixado assim, o próximo `npm run build` apaga o pacote, e o
próximo pacote leva o anterior dentro dele, porque a `dist/` é o que ele empacota. O segundo comando devolveu a
`dist/` ao que o Vite gera. A primeira regra da configuração é, portanto, **uma pasta própria para os pacotes**,
`release/`.

O primeiro build também baixou do GitHub as ferramentas que usa, o runtime do AppImage, um compactador e,
depois, o `fpm` para o `.deb`, por isso foi lento; elas ficam guardadas em `~/.cache` para o próximo.

## A configuração

O electron-builder lê as configurações de uma chave `build` no `package.json`. **O `npm pkg set` a escreve** sem
abrir o arquivo, uma chave de cada vez, e um `[]` no fim de uma chave acrescenta a uma lista:

```
ana@dev:~/planner$ npm pkg set build.appId=com.example.studyplanner build.productName="Study planner" build.directories.output=release "build.files[]=dist/**" "build.files[]=electron/**"
ana@dev:~/planner$ npm pkg set build.linux.category=Education build.linux.icon=src-tauri/icons/icon.png "build.linux.target[]=AppImage" "build.linux.target[]=deb" "build.artifactName=\${name}-\${version}-\${arch}.\${ext}"
ana@dev:~/planner$ npx electron-builder --linux 2>&1 | grep -E "^(Please|It is required)"
Please specify author 'email' in the application package.json
It is required to set Linux .deb package maintainer. Or you can set maintainer in the custom linux options.
```

Cada configuração é uma decisão:

| chave | valor | por quê |
|---|---|---|
| `appId` | `com.example.studyplanner` | a mesma identidade do app de celular e do app Tauri |
| `productName` | `Study planner` | o nome que a pessoa vê no menu |
| `directories.output` | `release` | fora do caminho do Vite |
| `files` | `dist/**`, `electron/**` | **só o que o app roda**: não `android/`, `ios/`, `src-tauri/` nem o código-fonte |
| `linux.category` | `Education` | onde o menu do desktop o arquiva |
| `linux.icon` | o PNG de 512 pixels da seção anterior | o mesmo ícone do Tauri |
| `linux.target` | `AppImage`, `deb` | os dois formatos a gerar |
| `artifactName` | `${name}-${version}-${arch}.${ext}` | um nome de arquivo sem espaço, para scripts conseguirem lidar com ele |

**O `.deb` se recusou a ser gerado.** Um pacote Debian precisa nomear quem o mantém, uma pessoa com endereço de
e-mail, e o electron-builder tira isso do `author` do `package.json`, que o planner nunca teve. A versão do
planner também ainda era o `0.0.0` do Vite, e um pacote com essa versão não diz nada a quem o instala. A aula 15
trata de números de versão; aqui o planner vira `0.1.0`, a versão que a configuração do Tauri já trazia:

```
ana@dev:~/planner$ npm pkg set version=0.1.0 description="A study planner" homepage=https://example.com/planner author.name=Ana author.email=ana@example.com
ana@dev:~/planner$ rm -rf release && npx electron-builder --linux 2>&1 | grep -o "target=.*"
target=AppImage arch=x64 file=release/planner-0.1.0-x86_64.AppImage
target=deb arch=x64 file=release/planner-0.1.0-amd64.deb
ana@dev:~/planner$ du -sh release/*.AppImage release/*.deb
121M	release/planner-0.1.0-x86_64.AppImage
97M	release/planner-0.1.0-amd64.deb
```

**121 MB para o AppImage e 97 MB para o `.deb`**, contra 2,85 MB do `.deb` do Tauri na aula 12. A diferença é a
que a aula 12 mediu no disco, agora no que uma pessoa baixa.

## O que tem dentro

O pacote do Electron guarda os arquivos do próprio app num arquivo só, o `app.asar`, que o `npx asar` consegue
listar:

```
ana@dev:~/planner$ npx asar list release/linux-unpacked/resources/app.asar | cut -d/ -f2-3 | sort -u
dist
dist/assets
dist/courses.json
dist/index.html
electron
electron/main.mjs
electron/preload.cjs
node_modules
node_modules/@capacitor
node_modules/@tauri-apps
node_modules/capacitor-keep-awake
node_modules/tslib
package.json
```

**O `files` cumpriu o papel dele para as pastas do projeto**: `dist/`, `electron/` e `package.json`, e nada de
`android/`, `ios/`, `src-tauri/` ou `src/`. Mas **o `node_modules` está ali**, com os pacotes do Capacitor e a
API do Tauri dentro. O electron-builder sempre acrescenta os pacotes listados em `dependencies` no
`package.json`, porque o processo principal de um app Electron pode fazer `require` deles em tempo de execução.
O processo principal do planner não usa nenhum: o Vite já juntou na `dist/assets` o que a página usa. Mover
esses pacotes para `devDependencies` os deixaria fora do arquivo. Eles são pequenos, então o planner os deixa
onde estão, e você agora sabe onde olhar quando um pacote for maior do que deveria.
