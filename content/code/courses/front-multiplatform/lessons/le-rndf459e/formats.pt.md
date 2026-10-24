---
title: O que é um pacote, em cada sistema
version: 1
---

**Um pacote é o arquivo único que uma pessoa baixa, e cada sistema tem os seus tipos.** Até aqui o planner
rodou de uma pasta de projeto: `npx cap run`, `npm start`, `npx tauri dev`. Ninguém mais tem essa pasta. O que
as pessoas recebem é um pacote, e o pacote decide como o app é instalado, para onde vão os arquivos dele, como
ele é removido, e quem respondeu por ele.

| sistema | pacote | o que é | quem instala |
|---|---|---|---|
| Android | `.apk` | o app, pronto para instalar num celular | a pessoa, a partir de um arquivo, ou uma loja |
| Android | `.aab` | um **Android App Bundle**: o app em pedaços, para o Google Play cortar em APKs por aparelho | só o Google Play |
| iOS | `.ipa` | o app, assinado, num arquivo compactado | a App Store, o TestFlight, ou o sistema próprio de uma empresa |
| Windows | `.exe` (NSIS), `.msi` | um programa instalador, ou um pacote que o instalador do próprio Windows lê | a pessoa, ou as ferramentas de uma empresa |
| macOS | `.dmg` com um `.app` | uma imagem de disco com o app dentro, arrastado para Aplicativos | a pessoa |
| Linux | `.deb`, `.rpm` | um pacote que o gerenciador de pacotes do sistema instala, com as dependências | `apt`, `dnf` e companhia |
| Linux | AppImage | um arquivo único que roda onde está, com tudo dentro | ninguém: ele vira executável e roda |

**Duas linhas merecem um segundo olhar.** Um **AAB não é algo que uma pessoa consiga instalar**: é o que o
Google Play pede que um desenvolvedor envie, e o Play gera a partir dele o APK que cada celular recebe, só com
a densidade de tela e o processador daquele celular. Um APK continua sendo o que você entrega a um testador ou
põe no seu próprio site. E **um `.ipa` não pode ser distribuído** do jeito comum: um iPhone só instala um app
assinado para ele, então o arquivo sai pela Apple, que é o assunto da aula 14.

## O que este curso gera, e o que ele descreve

| pacote | gerado aqui | com |
|---|---|---|
| `.deb`, `.rpm`, AppImage do Tauri | sim, na aula 12 | `npx tauri build` |
| `.deb` e AppImage do Electron | sim, nesta aula | `electron-builder` |
| ícones para todo sistema | sim, nesta aula | `tauri icon`, `@capacitor/assets` |
| `.apk` e `.aab` | **não** | Android Studio ou Gradle, que a máquina de gravação não conseguiu instalar |
| `.ipa` | **não** | Xcode, num Mac |
| `.exe`, `.msi`, `.dmg` | **não** | as mesmas ferramentas, rodando no Windows ou num Mac |

**Cada instalador de desktop é gerado no próprio sistema.** A ferramenta do Electron consegue gerar alguns
formatos do Windows no Linux com programas extras instalados, e o Tauri consegue tentar o mesmo, mas assinar e
testar ainda pedem o sistema de verdade, e a documentação das duas ferramentas gera os pacotes de cada sistema
naquele sistema. É por isso que um projeto distribuído para três sistemas faz o build em três máquinas,
geralmente três runners de um serviço de CI, assunto a que a aula 15 volta.
