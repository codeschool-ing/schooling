---
title: Os pacotes de celular, e um checklist antes de qualquer um deles
version: 1
---

**Os pacotes de Android e iOS são gerados pelas ferramentas das próprias plataformas, e nenhuma delas rodou
na máquina de gravação**: o Gradle precisa do SDK do Android, que ela não conseguiu baixar, e um `.ipa`
precisa do Xcode. O que segue são os passos da documentação do Capacitor e do Google, marcados como não
executados, para você saber o que esperar no seu computador.

## Android: um APK para testar, um AAB para publicar

A CLI do Capacitor consegue conduzir o Gradle por você. O **`npx cap build android`** roda o build de release do
projeto `android/` e o assina com uma chave que você fornece, que a aula 14 cria:

```sh
npm run build && npx cap sync android
npx cap build android --androidreleasetype AAB \
  --keystorepath ~/keys/planner-upload.jks --keystorealias upload
```

*Não executado.* O mesmo build pelo Android Studio é **Build, Generate Signed App Bundle or APK**, e num terminal
dentro de `android/` é `./gradlew bundleRelease` para um AAB e `./gradlew assembleRelease` para um APK, com as
configurações de assinatura em `android/app/build.gradle`. Os resultados ficam em `android/app/build/outputs/`,
em `bundle/release/` e `apk/release/`.

**Gere o AAB para o Google Play e um APK para todo o resto**: um testador a quem você manda um arquivo, ou o seu
próprio site. O Play só aceita bundles para apps novos, e gera a partir de cada um os APKs que os celulares
baixam.

## iOS: um archive, pelo Xcode

Num Mac, o `npx cap open ios` abre o projeto da aula 3 no Xcode. **Product, Archive** gera o app para aparelhos e
o guarda no Organizer do Xcode, e dali o **Distribute App** o assina e o envia ao App Store Connect, para o
TestFlight e a App Store, ou exporta um `.ipa` para a distribuição própria de uma empresa. *Não executado, pelo
motivo que a aula 1 deu.* A CLI do Capacitor consegue fazer o mesmo num terminal de Mac, com `npx cap build ios`,
dadas as configurações de assinatura da aula 14.

## Um checklist antes de qualquer pacote

Um pacote é o código como ele estava no momento do build, então as verificações vêm antes do build, não depois
de alguém já ter instalado. O checklist do planner, na ordem em que um release acontece:

| verificação | como | onde foi visto |
|---|---|---|
| o site acabou de ser gerado | `npm run build`, e ler a última linha | aula 1: um build que falhou deixa a `dist/` antiga |
| os projetos de celular têm esse site | `npx cap sync` | aula 2: um projeto com a `dist/` de ontem |
| **nenhum `server.url` e nenhum `cleartext`** | o `grep` abaixo | aula 2: um app que é uma página na sua rede |
| uma versão só em todo lugar | aula 15 | `package.json`, `tauri.conf.json`, Android e iOS |
| o ícone é o do próprio app | olhar o pacote | esta aula |
| só os arquivos do app vão no pacote | `npx asar list`, ou a lista de arquivos do pacote | esta aula |
| as permissões são as que o app usa | `AndroidManifest.xml` e `Info.plist` | aula 4 |

**A terceira linha é a que a aula 2 prometeu.** O live reload funciona pondo um `server.url` na configuração do
Capacitor, e um app gerado com ele abre um endereço da sua rede em vez do app que leva. O `cap sync` copia a
configuração para cada projeto nativo, então a busca cobre os três lugares:

```
ana@dev:~/planner$ grep -n "url\|cleartext" capacitor.config.ts android/app/src/main/assets/capacitor.config.json ios/App/App/capacitor.config.json; echo "grep exit status: $?"
grep exit status: 1
```

**Nenhuma linha impressa, e o `grep` saiu com 1, que é o jeito dele de dizer que não achou nada**: a
configuração distribuída não tem `server.url`. Um 0 ali queria dizer que uma linha foi encontrada e impressa
acima, e o release para até ela sumir. Uma verificação feita à mão é uma verificação esquecida na noite em que
importa, então um projeto que faz releases com frequência põe essa linha num script, ou na CI, e deixa que ela
faça o build falhar.
