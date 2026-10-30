---
title: Quando você precisa abri-los
version: 1
---

**Na maioria dos dias você nunca abre os projetos nativos.** Você muda o planner, constrói, sincroniza
e roda, e o trabalho está todo na `src/`. O lado nativo precisa de você por uma lista curta de motivos,
e cada um é uma aula deste curso:

| você precisa | onde | aula |
|---|---|---|
| pedir uma permissão: câmera, localização, notificações | `AndroidManifest.xml`, e uma chave com uma frase no `Info.plist` | 4 |
| escrever código nativo, ou depurar o de um plugin | Java ou Kotlin em `android/app`, Swift em `ios/App` | 5 |
| definir o ícone e a tela de abertura | `res/mipmap-*` no Android, `Assets.xcassets` no iOS | 13 |
| assinar o app para uma loja | um keystore no Gradle, um time e um perfil no Xcode | 14 |
| subir a versão | `build.gradle` no Android, as configurações do target no Xcode | 15 |
| ler um erro que a WebView nunca mostra | o Logcat do Android Studio, o console do Xcode | abaixo |

A última linha é a que as pessoas esquecem. **Uma falha em código nativo nunca chega à WebView**, então
nada no seu JavaScript consegue capturá-la nem imprimi-la. A janela Logcat do Android Studio e o
console do Xcode mostram o log nativo, onde aparecem as mensagens do próprio plugin e o rastro de uma
falha. O Chrome consegue se conectar a uma WebView Android depurável em `chrome://inspect`, e o Safari a
uma do iOS pelo menu Develop, o que dá as ferramentas de desenvolvimento do próprio navegador para a
metade web.

## O custo de cada edição

Cada mudança numa pasta nativa é mais uma coisa que tem que sobreviver ao próximo upgrade do Capacitor.
As versões maiores do Capacitor vêm com um guia de upgrade que lista as edições a fazer à mão em cada
projeto, e um projeto que mudou pouco tem pouco a juntar. **Prefira a configuração no
`capacitor.config.ts`, depois um plugin, depois uma edição nativa**, nessa ordem, e quando editar, faça
um commit só dela com uma mensagem dizendo por quê, para o próximo upgrade a encontrar.
