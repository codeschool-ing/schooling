---
title: Escolhendo, e o que este curso escolheu
version: 1
---

**A pergunta não é Expo ou React Native.** É o React Native que você vai escrever de qualquer jeito, e
duas perguntas menores por baixo dela: quem escreve os projetos nativos, e quem compila o app.

| a sua situação | comece com | por quê |
|---|---|---|
| um app novo, ainda sem código nativo | Expo, com prebuild | tudo neste curso funciona no primeiro dia, e nada impede acrescentar código nativo depois |
| um app novo que você sabe que precisa de um SDK nativo sem config plugin | Expo, com prebuild e um plugin que você escreve | vinte linhas de plugin saem mais barato que dois projetos nativos mantidos à mão |
| um app Android ou iOS existente acrescentando React Native a algumas telas | bare, seguindo o guia do React Native para apps existentes | o projeto nativo já existe e pertence à equipe dele |
| uma equipe de desenvolvedores nativos que vai editar Gradle e Xcode todo dia | bare, ou Expo com as pastas no commit | a geração brigaria com o jeito deles de trabalhar |

## O que este curso usa

**Expo SDK 58, com React Native 0.88, e prebuild.** O planner começa na aula 3 a partir do modelo do
Expo, roda num navegador e em testes no computador, tem as pastas nativas geradas quando um build
Android é necessário, e ganha um módulo nativo próprio na aula 17 sem que nenhuma das pastas seja
editada à mão.

Essa escolha também é o que a documentação do próprio React Native recomenda para um app novo, o que
importa por um motivo prático: os exemplos que você encontra, na documentação e nas instruções das
bibliotecas, cada vez mais partem dela. Onde as instruções de uma biblioteca dizem "edite o
`MainApplication.kt`", a versão Expo da mesma instrução é o config plugin dela, e a aula 17 mostra como
saber qual dos dois uma biblioteca tem.

## Uma conferência da decisão

Três perguntas, antes que uma equipe escreva a primeira tela:

1. **Alguma biblioteca de que o app precisa traz código nativo e nenhum config plugin?** Se sim, preveja
   um plugin para cada uma, ou um projeto bare.
2. **Quem compila o app iOS, e em quê?** Um Mac na mesa de alguém, ou o EAS Build. Aula 20.
3. **Alguém vai editar as pastas nativas à mão?** Se sim, coloque-as no commit e trate o projeto como
   bare desde o início, em vez de descobrir as edições depois de um `prebuild --clean`.
