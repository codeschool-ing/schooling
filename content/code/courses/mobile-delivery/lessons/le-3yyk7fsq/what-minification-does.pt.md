---
title: O que um build de release faz com os seus nomes
version: 1
---

**Um build de release não é o seu código com a depuração desligada; é o seu código reescrito para
ficar menor, e a reescrita é o que torna os crashes dele ilegíveis.** Toda plataforma faz isso, pelos
mesmos dois motivos: um download menor, lição 18, e uma abertura mais rápida, lição 15.

| | a ferramenta | o que ela faz com os nomes | o que ela deixa para trás |
|---|---|---|---|
| Android | o **R8**, rodado pelo Gradle quando `isMinifyEnabled = true` | renomeia classes, métodos e campos para `a`, `b`, `c`; copia métodos pequenos para dentro de quem os chama; remove o que nada usa | `mapping.txt` |
| iOS | o compilador e o linker, com os símbolos **removidos** do binário | tira os nomes de função de vez; um crash nomeia endereços | um bundle `.dSYM` |
| React Native | o **Metro** ou o esbuild, depois o **Hermes** compilando para bytecode | renomeia variáveis e funções, junta tudo numa linha | um **source map** |

## Três efeitos que mudam o que uma pilha diz

- **Renomear.** `WeekViewModel.totalMinutes` vira `a.b`. A pilha está certa e não diz nada.
- **Embutir (inlining).** Um método curto é copiado para dentro do método que o chama, e deixa de
  existir como quadro próprio. Uma pilha de um build de release pode ser **mais curta** que a do mesmo
  crash em debug, sem a função onde está o bug.
- **Juntar linhas.** JavaScript minificado é uma linha, então todo quadro diz linha 1, e só a coluna
  os distingue.

## A regra que esta lição repete

**O arquivo que desfaz a reescrita é produzido pelo build, e só o arquivo daquele build funciona.**
Dois builds do mesmo commit podem escolher nomes curtos diferentes e embutir coisas diferentes.
Então o mapeamento, o dSYM ou o source map é guardado ao lado do build publicado, e enviado ao coletor
de crashes como parte do release, lição 12. As próximas duas seções mostram o que esse arquivo faz,
com as ferramentas de verdade, no seu computador.
