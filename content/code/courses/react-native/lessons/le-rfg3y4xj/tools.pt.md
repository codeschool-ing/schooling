---
title: Logs e React Native DevTools
version: 1
---

O resto da depuração é olhar um app rodando, e três ferramentas fazem a maior parte.

## Logs

- **O `console.log` em desenvolvimento vai para o terminal do Metro**, e também para o console do DevTools.
  Em release ele vai para o log da plataforma, onde ninguém o lê a não ser que vá procurar.
- **No Android, esse log é o `logcat`**, lido com `adb logcat` das platform tools da aula 3, com um celular
  ou um emulador ligado. As mensagens do JavaScript do React Native levam a tag `ReactNativeJS`, então
  `adb logcat ReactNativeJS:V *:S` mostra essas e silencia o resto. Uma falha nativa, do próprio Kotlin,
  aparece lá como uma pilha do `AndroidRuntime`.
- **No iOS, o app Console** num Mac mostra o log de um celular ligado, e o Xcode mostra o de um simulador.

*Nenhum dos três foi executado para este curso: cada um precisa de um celular, de um emulador ou de um Mac.*

## React Native DevTools

**Aperte `j` no terminal onde o Metro roda**, com um development build conectado, e o React Native DevTools
abre: as ferramentas de desenvolvedor do Chrome, conectadas ao Hermes no celular. Ele tem um console, pontos
de parada e um depurador passo a passo para o seu TypeScript, mapeados pelos mesmos source maps da última
seção, um painel **Components** que mostra a árvore e as props e o estado de cada componente, e um
**Profiler** que registra quais componentes renderizaram e por quê, que a aula 19 usa. *Este curso não o
abriu, pelo mesmo motivo: não havia development build rodando num aparelho.*

**O que você consegue abrir é o build web num navegador**, cujas ferramentas de desenvolvedor fazem o mesmo
para tudo o que não é nativo: pontos de parada no seu código, o painel de rede mostrando cada requisição que
o planner faz, e a extensão React DevTools para a árvore de componentes.

## Relatório de falhas

Um app publicado precisa contar ao time quando falha, porque as pessoas para quem ele falha não vão contar.
Serviços como o Sentry e o Bugsnag têm bibliotecas para React Native que capturam erros de JavaScript,
falhas nativas e os relatos das error boundaries, e enviam os source maps na hora do build, para cada
relatório já chegar mapeado para um arquivo e uma linha. A boundary do planner tem o lugar dessa chamada, no
`componentDidCatch`.
