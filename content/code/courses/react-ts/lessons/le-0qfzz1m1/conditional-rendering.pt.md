---
title: Desenhar uma coisa ou outra
version: 1
---

**O JSX não tem `if`, porque chaves guardam expressões, e a aula 2 disse por quê.** Um componente
escolhe o que desenhar com as quatro ferramentas que o JavaScript lhe dá, e o planejador já usa as
quatro:

| ferramenta | o que significa | no planejador |
|---|---|---|
| um `return` antecipado | desenhe isto em vez de tudo abaixo | as telas de carregamento e de falha do `App`, e a tela do curso |
| um ternário, `a ? <A /> : <B />` | uma de duas | "session" ou "sessions" no `CourseCard` |
| `&&`, `cond && <A />` | isto, ou nada | nenhum ainda: a próxima seção mostra por que pede cuidado |
| uma variável | monte o elemento antes, use abaixo | o botão que o `CourseCard` passa ao `Card` como `title` |

**Um `return` antecipado é para telas inteiras; um ternário ou um `&&` é para parte de uma.** O `App`
retorna cedo porque um planejador carregando não tem semana nenhuma para mostrar, e a aula 6 disse
onde esses returns vão: abaixo de todo hook. Dentro de uma tela, um ternário deixa os dois ramos lado
a lado, onde quem lê consegue compará-los.

`null`, `undefined`, `false` e `true` não desenham nada, e é isso que faz o `&&` funcionar: quando a
condição é falsa, a expressão é `false`, e nada é desenhado. **Números e strings renderizam como
texto**, inclusive `0` e `''` — mas só o `0` aparece na tela — e essa diferença entre `false` e `0` é
o bug da próxima seção.

Um componente também pode devolver `null`, como o `RenderCount` da aula 7, para não desenhar nada e
continuar sendo um componente com estado e efeitos. Isso é diferente de não renderizá-lo: um
componente que devolve `null` mantém o estado, e um componente que o pai deixa de renderizar o perde.
