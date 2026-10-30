---
title: Quatro jeitos de fazer o mesmo app
version: 1
---

**Existem quatro jeitos de colocar o mesmo app no Android e no iPhone, e eles diferem em quanto do
programa é escrito uma vez só.** A imagem comum é a de um conversor: você escreve o app num lugar e
uma ferramenta o transforma em dois apps nativos. Nada faz isso. Cada abordagem decide, em vez disso,
quais partes rodam nos dois celulares sem mudar e quais partes são escritas separadamente para cada
um.

| abordagem | o que você escreve | o que desenha a tela | o que é escrito uma vez |
|---|---|---|---|
| nativa, por plataforma | Kotlin com Jetpack Compose; Swift com SwiftUI | as views da própria plataforma | nada: são dois apps |
| UI multiplataforma | React Native: JavaScript ou TypeScript. Flutter: Dart | React Native: as views da plataforma. Flutter: o próprio motor | as telas e a lógica |
| lógica compartilhada | Kotlin Multiplatform, mais as telas de cada plataforma | as views da plataforma, ou o Compose Multiplatform | a lógica |
| embrulho web | HTML, CSS e JavaScript, dentro do Capacitor ou do Cordova | uma WebView, que é um motor de navegador | tudo, como um site |

## Nativo, por plataforma

**Dois apps, em duas linguagens, com dois conjuntos de ferramentas.** O app Android é Kotlin, com
telas em Jetpack Compose, construído no Android Studio. O app iOS é Swift, com telas em SwiftUI,
construído no Xcode. Nada passa de um para o outro além do design e do servidor com que os dois
conversam. Toda regra do planner, como em que semana cai uma sessão, é escrita duas vezes, e um bug
corrigido num continua esperando no outro. Em troca, cada app usa o recurso mais novo da sua
plataforma no dia em que ele sai, e nada fica entre o código e o sistema.

## UI multiplataforma: React Native e Flutter

**Um código só, telas incluídas, para os dois celulares.** O React Native é escrito em JavaScript ou
TypeScript com React, e o Flutter em Dart, uma linguagem do Google, como o próprio Flutter. Os dois
põem o app inteiro num projeto e geram dele um pacote Android e um pacote iOS. Ficam no mesmo grupo
pelo que compartilham, que são as telas, e são opostos no jeito como essas telas chegam ao vidro: o
React Native pede à plataforma as views dela, e o Flutter pinta cada pixel sozinho. A próxima etapa
trata dessa diferença.

## Só a lógica compartilhada: Kotlin Multiplatform

**As regras são escritas uma vez em Kotlin, e as telas continuam nativas.** O Kotlin Multiplatform,
da JetBrains, compila o mesmo código Kotlin para Android e para iOS. Uma equipe escreve uma vez os
dados do planner, as somas e as chamadas de rede, e continua desenhando as telas Android em Compose e
as telas iOS em SwiftUI. Quem quer compartilhar as telas também pode somar o Compose Multiplatform,
o kit da JetBrains que roda telas Compose no iOS, o que aproxima esta abordagem da anterior.

## Embrulhos web, e o PWA

**Um embrulho é um app nativo cuja tela inteira é uma página web.** O Capacitor, e o Cordova antes
dele, pegam um site, colocam dentro de um projeto Android e de um projeto iOS e o mostram numa
WebView, o motor de navegador que o sistema empresta aos apps. Ele vai para as lojas como qualquer
app, e plugins dão à página a câmera ou o sistema de arquivos. Um **progressive web app** é menos
ainda: um site que o navegador consegue instalar na tela inicial, sem pacote de app e sem loja
própria. É a entrada mais barata, e alcança só o que o navegador permite.

## Para onde este curso vai

A bifurcação da trilha depois deste curso oferece três destes caminhos. **Android com Kotlin** e
**iOS com Swift** são o caminho nativo, uma plataforma cada. **Multiplataforma com React Native** é a
única UI multiplataforma que a trilha ensina. Flutter e Kotlin Multiplatform não são um caminho
aqui, e o curso `react-native` olha os dois na aula 22. Os embrulhos são o assunto de
`front-multiplatform`, que leva o Capacitor da aula 2 até a aula 6. A aula 3 deste curso é sobre
como escolher entre eles.
