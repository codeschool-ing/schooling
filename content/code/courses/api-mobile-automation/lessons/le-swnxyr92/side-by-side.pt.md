---
title: Espresso, XCUITest e Appium lado a lado
version: 1
---

**As três ferramentas diferem menos no que conseguem testar do que em onde o código delas roda, e
todo o resto decorre disso.** O Espresso fica dentro do app Android. O XCUITest fica ao lado do app
iOS num processo próprio. O Appium fica num computador, falando com um driver que fala com o
aparelho. A tabela põe as lições 15, 16 e esta num lugar só:

| | Espresso (lição 16) | XCUITest | Appium (lição 15) |
|---|---|---|---|
| **plataforma** | Android | iOS | as duas, com um driver para cada |
| **onde o código do teste roda** | no aparelho, no processo do app | no aparelho, num app executor ao lado do app | num computador, em processo próprio |
| **como alcança o app** | segura as views do app diretamente | a camada de acessibilidade | W3C WebDriver sobre HTTP, depois o driver: UiAutomator2 no Android, XCUITest no iOS |
| **o que consegue nomear** | a tela, e as classes do próprio app | a tela, por identificador de acessibilidade ou rótulo | a tela, por resource id, accessibility id ou texto |
| **o que espera** | a thread principal, sozinho; o resto por um idling resource | o app sossegar, sozinho; o resto com uma espera escrita | nada sozinho; toda espera é escrita |
| **as telas do próprio sistema** | não: só as janelas do app | sim, tratando o sistema como outro app | sim, ele vê a tela inteira |
| **linguagem** | Kotlin ou Java, a do app | Swift ou Objective-C, a do app | qualquer uma com cliente WebDriver |
| **o que exige** | Android Studio ou Gradle | um Mac com Xcode | um Mac também, para iOS; o SDK do Android para Android |
| **quem costuma escrever** | quem desenvolve o app | quem desenvolve o app | quem testa, muitas vezes para os dois apps ao mesmo tempo |

**A crença comum é que o Appium é mais lento porque "não é nativo".** O motivo é mais preciso e mais
útil. Todo passo de um teste Appium é uma requisição HTTP a um servidor, que pede a um driver. No
iOS o driver pede ao WebDriverAgent, que é ele mesmo um executor XCUITest. Então um teste Appium no iOS faz
tudo o que um teste XCUITest faz, mais um salto de rede e um servidor a cada passo. Com esse tempo
ele compra uma suíte e uma linguagem para duas plataformas.

## Escolhendo, para uma equipe

Uma equipe com um app Android e um app iOS, cada um escrito de forma nativa, costuma acabar com
todos eles, em alturas diferentes da pirâmide:

- a lógica testada onde mora, com testes locais no Android e Swift Testing no iOS, por quem
  desenvolve, às centenas;
- as telas de cada app testadas com a ferramenta da própria plataforma, Espresso ou XCUITest, por
  quem desenvolve, porque essas ferramentas são rápidas e moram no próprio projeto do app;
- uma suíte menor de jornadas pelos dois apps, como encontrar um espetáculo e abri-lo, escrita
  uma vez em Appium por quem testa. A jornada é a mesma nos dois celulares, e uma suíte custa menos
  para manter do que duas.

Essa última suíte só funciona se os dois apps derem nomes iguais aos elementos. A seção 04 mostrou
que isso não é automático: o Tickets no Android tem linhas chamadas `title`, e no iOS linhas
chamadas `show-sh-103`. **Combinar os nomes é um pedido que quem testa faz às duas equipes**, cedo. É o trabalho de automação de testes mais barato que existe.
