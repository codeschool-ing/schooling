---
title: Fórmulas que sobrevivem a uma linha inserida
version: 1
---

Uma fórmula escrita hoje é lida daqui a dezoito meses por alguém que não lembra para que ela
servia — muitas vezes você. Três hábitos decidem se essa leitura corre bem.

## Dê nome às coisas

Um **intervalo nomeado** dá uma palavra a uma célula ou a um intervalo. `=B2*ICMS` em vez de
`=B2*$C$1`, e o nome viaja: significa a mesma coisa em toda aba e não se move quando uma linha é
inserida acima dele.

Defina em *Fórmulas, Gerenciador de Nomes* ou na caixa de nome à esquerda da barra de fórmulas.
Três minutos no começo de uma planilha, e toda fórmula depois disso se lê como uma frase.

**Uma tabela, da aula nove, faz isso pelas colunas automaticamente** — `=SOMA(Vendas[Valor])`. Use
os dois: a tabela para os dados, nomes para as premissas.

## Mantenha o aninhamento raso

`SE` dentro de `SE` dentro de `SE` é onde planilhas vão morrer. Três níveis é onde uma pessoa
deixa de conseguir ler, e cinco é onde ninguém consegue mudar com segurança.

Os substitutos são todos curtos:

| em vez de | use |
|---|---|
| `SE` aninhado sobre faixas de um número | `SES`, ou uma tabela de consulta com correspondência aproximada |
| `SE` aninhado sobre uma lista exata de valores | `PARÂMETRO`, ou `PROCX` contra uma tabelinha |
| a mesma subexpressão três vezes | `DEIXAR`, que a nomeia uma vez |
| uma fórmula longa que ninguém lê | duas colunas, com o passo do meio visível |

**Essa última linha é a primeira a buscar.** Uma coluna auxiliar não é fracasso; é a conta
mostrada. Uma coluna que dá para olhar é uma coluna que alguém consegue conferir, e ela pode ser
escondida depois que a planilha fica pronta.

## Trate os erros com honestidade

`#N/D`, `#VALOR!`, `#REF!` e `#DIV/0!` não são ruído. Cada um nomeia um defeito diferente:

| | significa |
|---|---|
| `#N/D` | uma consulta não achou nada. Normalmente um fato real sobre os dados |
| `#VALOR!` | aritmética sobre algo que não é número. Muitas vezes o problema do texto numa coluna |
| `#REF!` | uma referência a uma célula que não existe mais. Algo foi apagado |
| `#DIV/0!` | uma divisão por célula vazia ou zero |
| `#NOME?` | uma função ou um nome que o programa não conhece. Muitas vezes um erro de digitação |

**Embrulhar tudo em `SEERRO` é o jeito mais comum de esconder um problema real.** `SEERRO(x; 0)`
transforma *não achei este cliente* em *este cliente não comprou nada*, e o total fica errado
exatamente no tanto em que a consulta falhou.

Use `SENÃODISP` em vez de `SEERRO` quando você quer dizer só o caso da consulta, e dê um valor
visível — `SENÃODISP(x; "não encontrado")` — em vez de um zero que desaparece dentro de uma soma.

## E a que sempre vale escrever

**`=ARRED(x; 2)` no ponto em que uma pessoa lê um número**, e nunca no meio da corrente. A
observação sobre ponto flutuante da aula nove é o motivo: um total de valores arredondados e um
total arredondado são números diferentes, e o que uma pessoa confere à mão é o segundo.
