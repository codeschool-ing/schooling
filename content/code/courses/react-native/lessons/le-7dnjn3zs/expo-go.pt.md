---
title: O Expo Go, e o muro em que ele bate
version: 1
---

**O Expo Go é um app nativo que já contém todas as bibliotecas de um SDK do Expo.** Você o instala pela
App Store ou pelo Google Play, sobe o servidor de desenvolvimento no computador e aponta o Expo Go para
ele. Ele baixa o seu JavaScript e o roda dentro de si. Nada é compilado no seu computador, não é
preciso Android SDK nem Xcode, e uma mudança que você salva aparece no celular um segundo depois.

*O Expo Go num celular não foi rodado para este curso*, porque o computador em que ele foi gravado não
tinha celular por perto. A aula 3 dá os passos, a partir da documentação do Expo, e toda aula roda
também num navegador.

## Por que ele é tão rápido

A parte lenta de construir um app mobile é o build nativo: o Gradle ou o Xcode compilando e
empacotando tudo. O Expo Go já fez isso, uma vez, para todo mundo, com todos os módulos nativos do SDK
compilados dentro. O seu projeto então só acrescenta o que o Hermes consegue rodar, JavaScript, e é
isso que o servidor de desenvolvimento envia. **O Expo Go é um anfitrião pré-compilado e o seu app é um
hóspede nele.**

## Onde ele para

O mesmo fato desenha os limites dele, e eles não são arbitrários:

- **Só existe o código nativo com que ele foi compilado.** Uma biblioteca que não faz parte do SDK do
  Expo e traz código nativo, um SDK de pagamentos por exemplo, não roda no Expo Go, porque o Kotlin e o
  Swift dela nunca foram compilados dentro dele. Bibliotecas só de JavaScript funcionam, porque chegam
  com o seu bundle.
- **A configuração nativa do seu app não se aplica.** O nome, o ícone, o identificador e os textos de
  permissão são os do Expo Go, não os seus. Um config plugin como o de duas seções adiante não muda
  nada ali.
- **Uma versão de SDK por vez.** O Expo Go das lojas acompanha o SDK mais novo. Um projeto deixado numa
  versão anterior talvez não abra nele, e a solução é atualizar o projeto, não o app.
- **Alguns serviços precisam da sua própria identidade.** Notificações push enviadas ao Expo Go chegam
  como sendo do Expo Go; a aula 16 explica por que um app de verdade precisa da própria.

## O development build: o seu próprio Expo Go

A resposta a cada item dessa lista é a mesma: **compile o seu próprio anfitrião**. Um development build
é o seu app, compilado com o próprio código nativo e a própria configuração, mais a biblioteca
`expo-dev-client`, que dá a ele a capacidade do Expo Go de carregar JavaScript do servidor de
desenvolvimento. Você o compila uma vez, instala no celular ou no emulador, e depois trabalha
exatamente como com o Expo Go, até acrescentar outra biblioteca nativa e compilar de novo.

| | Expo Go | development build |
|---|---|---|
| módulos nativos | os do SDK, fixos | os que o projeto incluir |
| o seu nome, ícone, permissões | não | sim |
| precisa de build nativo | nunca | uma vez, e depois a cada mudança nativa |
| quem compila | o Expo, já feito | você, localmente (aula 3) ou na nuvem do Expo (aula 20) |

**Comece no Expo Go e saia dele no dia em que precisar de algo que ele não contém.** Para uma equipe que
já sabe que vai precisar de uma biblioteca nativa, esse dia é o primeiro, e o planner deste curso
chega a ele na aula 17.
