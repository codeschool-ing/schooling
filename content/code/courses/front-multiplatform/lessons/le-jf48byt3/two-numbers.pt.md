---
title: Dois números, e quatro lugares onde eles moram
version: 1
---

**Todo release leva uma versão, e num celular ele leva duas.** Uma é para pessoas: `0.2.0`, `1.4.1`, o número que
uma página de loja mostra e um relato de bug cita. A outra é para o sistema: um número inteiro que precisa crescer
a cada build que uma loja recebe, e que decide qual build é mais novo.

| sistema | para pessoas | para o sistema |
|---|---|---|
| npm, Electron, Tauri | `version` no `package.json` ou no `tauri.conf.json` | a mesma string |
| Android | `versionName`, qualquer texto | `versionCode`, um número inteiro que só cresce |
| iOS | `CFBundleShortVersionString`, o **Version** do Xcode, `MARKETING_VERSION` | `CFBundleVersion`, o **Build** do Xcode, `CURRENT_PROJECT_VERSION` |

**O número para pessoas segue o versionamento semântico**, três números, `MAJOR.MINOR.PATCH`: o patch muda numa
correção, o minor em algo novo que não quebra nada, e o major numa mudança que quebra alguma coisa, como um formato
de arquivo que a versão antiga não consegue ler. Quem lê `1.4.1 → 1.5.0` deveria conseguir adivinhar que tipo de
atualização é.

**O número para o sistema não perdoa.** O Google Play recusa um bundle cujo `versionCode` não seja maior que todos
os que ele já viu para o app, e o App Store Connect recusa um número de build que ele já tem para aquela versão.
Nenhum dos dois números pode ser reusado ou voltar, nem para um build que foi recusado e nunca chegou a ninguém.

A aula 9 encontrou esses números no Expo. O planner os tem em quatro arquivos, escritos por quatro ferramentas, e
eles já discordam:

```
ana@dev:~/planner$ grep -n "\"version\"" package.json src-tauri/tauri.conf.json
package.json:4:  "version": "0.1.0",
src-tauri/tauri.conf.json:4:  "version": "0.1.0",
ana@dev:~/planner$ grep -n "versionCode\|versionName" android/app/build.gradle
10:        versionCode 1
11:        versionName "1.0"
ana@dev:~/planner$ grep -n "MARKETING_VERSION\|CURRENT_PROJECT_VERSION" ios/App/App.xcodeproj/project.pbxproj
303:				CURRENT_PROJECT_VERSION = 1;
310:				MARKETING_VERSION = 1.0;
325:				CURRENT_PROJECT_VERSION = 1;
332:				MARKETING_VERSION = 1.0;
```

**Quatro lugares, duas versões diferentes.** O `package.json` diz `0.1.0`, porque a aula 13 o definiu; o Tauri
também, que o `tauri init` escreveu. O projeto Android diz `1.0` e o projeto iOS `1.0`, os dois do modelo do
Capacitor, com número de build 1. Um release feito agora seria `0.1.0` no desktop e `1.0` nos celulares, para o
mesmo código. A próxima seção dá à versão uma casa só.
