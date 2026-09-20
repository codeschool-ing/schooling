---
title: Conferir o próprio trabalho, que nada mais no arquivo vai fazer
version: 1
---

Todo outro documento deste curso te avisa quando está quebrado. Uma planilha não avisa. Ela
produz um número, com confiança, seja lá o que tenha entrado — então a conferência é uma coisa que
você constrói, e leva uns dez minutos.

## A coluna de conferência

**Uma coluna cujo único serviço é ser zero.**

Ao lado de um total calculado, uma fórmula que calcula a mesma coisa por outro caminho e subtrai
uma da outra. Ao lado de um rateio, uma fórmula que soma as partes e compara com o todo. Ao lado
de uma consulta, uma contagem de quantas não casaram.

```
=ARRED(total_pelo_detalhe - total_pelo_resumo; 2)
```

A formatação condicional deixa vermelho qualquer coisa que não seja zero, e agora a planilha **te
avisa** quando está errada. Essa é a diferença inteira entre uma planilha em que você confia e
uma sobre a qual você torce.

## As conferências que valem em qualquer planilha

| | pega |
|---|---|
| **`CONT.NÚM` ao lado de `CONT.VALORES`** | texto escondido numa coluna de números. Respostas diferentes significam que alguma célula não é número |
| **um total contra uma figura conhecida** | um extrato, uma nota fiscal, o relatório do mês passado. A única conferência externa que existe |
| **a contagem de linhas, antes e depois** | uma consulta ou um filtro que perdeu linhas |
| **o maior e o menor valor** | uma vírgula no lugar errado, uma data em 1900, um negativo que não deveria existir |
| **`=SOMA(a coluna inteira)` contra `=SUBTOTAL` das visíveis** | um filtro que você esqueceu que estava ligado |

**A segunda linha é a que mais importa e a que as pessoas pulam**, porque é a única conferência
que alcança fora do arquivo. Todo o resto confirma que a planilha é consistente consigo mesma, o
que uma planilha construída sobre uma premissa errada também é.

## As ferramentas que o programa te dá

- **Rastrear Precedentes e Rastrear Dependentes** — aba *Fórmulas*. Setas mostrando quais células
  alimentam uma fórmula e quais fórmulas se alimentam de uma célula. Dois cliques, e é assim que
  se descobre o que uma planilha de vinte anos está fazendo.
- **Mostrar Fórmulas** — `Ctrl+` crase. A planilha inteira troca de valores para fórmulas de uma
  vez, que é o jeito mais rápido de achar uma constante que alguém digitou no meio de uma coluna
  de cálculos.
- **Verificação de erros** — os triangulozinhos verdes. Na maior parte ruído, e genuinamente acha
  *fórmula inconsistente nesta região*, que é a que importa.
- **Avaliar Fórmula**, que percorre uma expressão longa um pedaço por vez. Para o `SE` aninhado
  que outra pessoa escreveu, é o único jeito.

## Dois defeitos com nome

**Uma referência circular** é uma fórmula que depende do próprio resultado. O programa anuncia e
depois mostra zero, o que é a coisa educada a fazer e não é uma resposta. É quase sempre um
intervalo que sem querer inclui a célula em que a fórmula está — uma `SOMA` escrita uma linha
longe demais.

**O `#REF!` significa uma célula que foi apagada.** O importante sobre ele é que ele se espalha:
toda fórmula que depende de um `#REF!` vira um. Então o conserto é achar o *primeiro* — aquele
cujos próprios argumentos estão bons — e não os quatrocentos rio abaixo dele.

## E o hábito que vale por todo o resto

**Antes de enviar, abra como se alguém tivesse te entregado.**

Leia a aba `notas`. Siga um número da saída de volta até uma entrada. Mude uma premissa e veja o
total se mover. Confira a contagem de linhas. Leva cinco minutos e pega a coisa que senão seria
pega pela pessoa que agiu sobre o número.
