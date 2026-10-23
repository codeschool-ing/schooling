---
title: Quanto a hidratação custa ao processador
version: 1
---

**A hidratação roda os componentes da página mais uma vez, no navegador, para descobrir o que o
servidor já sabia.** No planner isso é uma chamada de função. Num framework é a árvore inteira de
componentes, reconstruída na memória e percorrida sobre os elementos existentes. Num notebook é rápido
o bastante para não se notar, e os visitantes para quem isso importa estão em celulares, cujos
processadores são várias vezes mais lentos.

O Chromium consegue deixar o próprio processador mais lento. O `tools/cpu.ts` abre uma página com o
processador quatro vezes mais lento, que é mais ou menos um celular intermediário perto do notebook
onde isto foi gravado, e informa dois contadores do próprio Chromium: o tempo rodando JavaScript, e o
tempo de todas as tarefas da thread principal, com interpretação, estilo, layout e pintura incluídos.
Cada número é a mediana de cinco cargas novas, porque uma carga só tem ruído demais. Salve em
`tools/`:

```typescript
@@
```

Com o `server.ts` do planner na 3000 e os quatro servidores da aula 2 da 3001 à 3004, todos com o
build do jeito que a aula 3 os deixou, abra a mesma página de curso em cada um:

```
@@
```

## Lendo isso

**O Next.js de novo custa mais e o SvelteKit menos, mas não na proporção do que mandaram.** O
Next.js mandou umas cinco vezes o JavaScript do SvelteKit na aula 2, e rodou umas três vezes e meia o
tempo de script dele aqui. E o planner puro, com 2,8 KB, mediu tanto tempo de script quanto o Angular:
neste tamanho os contadores medem o que qualquer página com script custa para começar, tanto quanto o
framework, e só a diferença grande fica clara acima disso. Com o que os números concordam é com a
escala: uma página com dois links e duas sessões custa a um processador mais lento dezenas de
milissegundos para ser assumida, e uma página de verdade, com cem componentes, custa
proporcionalmente mais, tudo isso enquanto a página parece pronta.

A aula 5 dá um nome a esse custo, como parte de quão rápido uma página responde a um toque, e a aula
6 abre o mesmo trabalho no painel de performance do Chromium, tarefa por tarefa.
