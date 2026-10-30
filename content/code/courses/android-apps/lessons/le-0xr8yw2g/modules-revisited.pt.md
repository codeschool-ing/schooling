---
title: "Um módulo, e quando deixar de ter um só"
version: 1
---

**A aula 1, seção 06, prometeu voltar aos módulos, e a resposta para o planner continua sendo um.**
Um módulo se paga de duas maneiras, ambas citadas lá: recompila menos, porque o Gradle reconstrói só
os módulos que uma mudança toca e os que dependem deles, e impõe fronteiras, porque o código não pode
usar uma classe de um módulo que não declara. Nenhuma das duas incomodou o planner ainda: o build
dele é rápido, e uma pessoa só guarda tudo na cabeça.

## Os sinais de que um módulo só não basta mais

- **Um build pelo qual você espera.** O build de release da seção 04 levou 1 minuto e 16 segundos, e
  boa parte disso é o R8 lendo tudo, o que é inevitável; mas se um build de *debug* depois de uma
  mudança de uma linha começa a levar mais que alguns segundos, o compilador está refazendo um
  trabalho que uma fronteira de módulo teria poupado.
- **Uma regra que ninguém consegue impor.** "As telas nunca falam com o Room diretamente, só pelo
  repositório" é a arquitetura da aula 16. Num módulo só, isso é uma convenção que quem revisa tem de
  pegar; com `:core:data` e `:feature:sessions` como módulos separados, uma tela que importa um DAO
  não compila.
- **Um segundo app.** Uma versão do planner para tablet ou relógio compartilharia o modelo e o
  repositório e nada das telas, e essa é uma fronteira de módulo já desenhada para você.

## Como a divisão costuma acontecer

A orientação de arquitetura do Google para apps modulares descreve o formato comum: `:app` no topo,
montando tudo; módulos `:feature:…`, um por tela ou fluxo, que dependem de módulos `:core:…` mas nunca
uns dos outros; e `:core:data`, `:core:model` e `:core:ui` na base. Cada um é um diretório com o
próprio `build.gradle.kts`, uma linha no `settings.gradle.kts` e o plugin `com.android.library` em
vez de `com.android.application`.

**Não executado** para o planner: dividi-lo acrescentaria arquivos de build e não ensinaria nada de
que uma aula deste curso precise, e um exemplo que não cabe é feito menor, não maior. O catálogo da
aula 1, seção 05, foi escrito para deixar a divisão barata quando ela vier, porque todo módulo lê o
mesmo `libs.versions.toml`.

## Onde o curso termina

Vinte e duas aulas atrás, o planner era oito arquivos e uma frase numa tela. Agora ele tem telas em
Compose que sobrevivem à rotação, estado em ViewModels, dados de um servidor e do Room atrás de um
repositório, sincronização em segundo plano que sobrevive ao app, um lembrete que pede antes de
notificar, testes em três níveis e um bundle assinado e encolhido que o Google Play aceitaria. Os
cursos que vêm depois nesta trilha, `mobile-offline` e `mobile-delivery`, levam o mesmo planner
adiante sem supor qual das três plataformas você escolheu.
