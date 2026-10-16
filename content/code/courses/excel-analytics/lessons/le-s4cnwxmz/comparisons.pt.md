---
title: Comparações, e os dois valores que elas devolvem
version: 1
---

**Uma comparação é uma fórmula cuja resposta é `VERDADEIRO` ou `FALSO`, e toda função desta aula é
construída sobre uma.** `=E2>=10` pergunta se a venda S1001 teve dez sacos ou mais; teve catorze,
então a célula mostra `VERDADEIRO`. Não há `SE` nela, e nenhum é preciso: a comparação já é uma
fórmula completa, com um valor próprio, do tipo lógico que a aula 1 seção 08 listou ao lado de
números e texto.

## Os seis operadores

| operador | quer dizer | na linha 2 de `Sales` | responde |
|---|---|---|---|
| `=` | igual a | `=G2="Wholesale"` | `VERDADEIRO` |
| `<>` | diferente de | `=D2<>"CER1K"` | `FALSO` |
| `>` | maior que | `=F2>100` | `VERDADEIRO` |
| `<` | menor que | `=B2<DATA(2026;1;1)` | `VERDADEIRO` |
| `>=` | maior ou igual a | `=E2>=10` | `VERDADEIRO` |
| `<=` | menor ou igual a | `=E2<=10` | `FALSO` |

Digite qualquer uma em J2 e preencha para baixo, e a coluna J vira uma coluna de respostas, uma por
venda. Experimente a primeira:

```localised
=G2="Wholesale"
```

## O que uma comparação compara

**Texto é comparado sem levar em conta maiúsculas e minúsculas.** `=G2="wholesale"` também dá
`VERDADEIRO`, porque o Excel trata `Wholesale`, `wholesale` e `WHOLESALE` como o mesmo texto numa
comparação. Em geral é o que você quer, e vale saber para o dia em que não for: quando a caixa das
letras importa, a função `EXATO` (`EXACT` no Excel em inglês) compara dois textos exatamente, e
`=EXATO(G2;"wholesale")` dá `FALSO`.

**Uma data é comparada como o número que ela é.** `=B2>=DATA(2026;1;1)` pergunta se a venda
aconteceu em 2026 ou depois. `DATA` (`DATE`) monta a data a partir de ano, mês e dia, então a
fórmula quer dizer a mesma coisa em qualquer país, seja qual for a ordem em que se digita uma data
ali. Escrever a data como texto entre aspas, `"2026-01-01"`, compara um número com um texto, que é
a próxima armadilha.

**Um número e um texto nunca são iguais.** `="14"=14` dá `FALSO`. O primeiro são os caracteres um e
quatro; o segundo é catorze. É de novo o número guardado como texto da aula 1 seção 08 e a
comparação é mais um lugar onde ele falha sem erro: uma coluna de códigos digitados como `1001` e
colada de outro lugar como texto vai dar `FALSO` comparada a cada um deles.

**Texto também tem ordem.** `="Online"<"Shop"` dá `VERDADEIRO`, porque O vem antes de S. É a ordem
que uma classificação usa, e raramente é para isso que se comparam palavras.

## Uma cadeia não é um intervalo

A matemática escreve "entre 4 e 9 sacos" como `4 <= sacos < 10`, e o Excel deixa você digitar:

```localised
=4<=E2<10
```

A resposta é `FALSO`. É `FALSO` para 4 sacos, para 5 e para 9, em toda linha da planilha. O Excel
trabalha da esquerda para a direita: `4<=E2` é uma comparação e dá `VERDADEIRO` ou `FALSO`; depois
esse valor lógico é comparado com 10, e o Excel põe todo valor lógico acima de todo número, então
`VERDADEIRO<10` é `FALSO`. Nenhum erro, uma resposta plausível, e errada em toda linha. Um intervalo
precisa de duas comparações unidas por `E` (`AND`), que é o assunto de duas seções adiante.
