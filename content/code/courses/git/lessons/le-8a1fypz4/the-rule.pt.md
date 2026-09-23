---
title: Merge ou rebase, e a regra única
version: 1
---

Os dois comandos juntam trabalho, e os dois terminam com os mesmos arquivos. O que muda é o histórico
que eles deixam, e essa diferença decide quando cada um é seguro.

**O merge acrescenta.** Ele mantém todo commit existente exatamente como era e acrescenta um que os
junta. Nada do que outra pessoa tem é mudado.

**O rebase reescreve.** Ele substitui os commits do seu branch por novos, com ids novos. Os antigos
continuam no seu repositório, sem branch, encontráveis no reflog da aula 4, mas já não são o seu
branch.

## A regra

> **Nunca faça rebase de commits que outra pessoa já tem.**

É a mesma regra que a aula 4 deu para o `reset` e o `--amend`, pelo mesmo motivo. Se o Bruno tem o
`788a11d` e você o substitui pelo `6e29a2d`, a cópia dele e a sua passam a ter dois commits diferentes
que fazem a mesma mudança. Na próxima vez que vocês compartilharem trabalho, os dois se encontram, e o
Git vê dois históricos que discordam sobre o que aconteceu. Alguém acaba arrumando commits duplicados à
mão, em geral sem entender por que eles apareceram.

Então a prática em que a maioria das equipes se acerta é simples:

- **Faça rebase do seu próprio branch, antes de compartilhá-lo**, para atualizá-lo com o `main` e
  manter o histórico reto. Até você enviar, ninguém mais tem esses commits, e reescrevê-los não
  prejudica ninguém.
- **Faça merge de tudo o que é compartilhado.** Depois que um branch está na cópia compartilhada,
  traga o `main` para ele com um merge, ou faça o merge dele no `main`, e deixe o histórico mostrar a
  bifurcação.

A aula 7 é onde *compartilhado* passa a ter um sentido concreto, com o `git push`, e ela mostra o
`git pull --rebase`, que aplica exatamente esta regra aos commits que você ainda não enviou.

## Qual deles uma equipe deve usar?

É uma escolha de verdade, com um custo de verdade, e as equipes discutem isso:

- Um histórico **com merges** é fiel sobre quando o trabalho aconteceu em paralelo, e nunca reescreve
  nada. Ele também é mais barulhento, com um commit de merge para cada branch.
- Um histórico **com rebase** se lê como uma linha limpa e é mais fácil de pesquisar com `git log`. Ele
  também registra uma ordem em parte fictícia: trabalho que aconteceu em paralelo parece sequencial.

Nenhum dos dois está errado. O que importa é a equipe escolher um e escrever isso, e a aula 9 é onde
essa decisão é tomada como parte de um fluxo de trabalho. A regra acima vale nas duas escolhas.
