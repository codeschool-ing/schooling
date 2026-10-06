---
title: As três na planilha
version: 1
---

Toda planilha calcula as três. Com os tempos de entrega da Horta nas células A2 a A13, as cestas em B2 a
B13 e os itens em C2 a C13:

```localised
=MÉDIA(A2:A13)          38,9583333333333
=MED(A2:A13)            37,25
=MED(B2:B13)            68,2
=MODO.ÚNICO(C2:C13)     3
```

Os valores à direita são o que o LibreOffice Calc devolveu para essas fórmulas com os dados do curso. O
Excel e o Google Planilhas têm as mesmas funções; numa planilha em português elas se chamam como acima.

## As funções de moda escondem coisas

Dois comportamentos da função de moda valem ser conhecidos antes que surpreendam você.

**Sem valor repetido, ela devolve um erro.** `MODO.ÚNICO` sobre os doze tempos de entrega dá um erro em
vez de um número, porque cada tempo aparece uma vez. O erro é a resposta correta, mas um gráfico ou um
relatório que esperava um número vai quebrar com ele.

**Com empate, ela devolve um dos valores empatados sem avisar.** Sobre as notas em estrelas, na ordem em
que a tabela as lista, `MODO.ÚNICO` devolve **5**: o primeiro dos dois valores empatados que encontra. Os
4, que aparecem tantas vezes quanto, somem. `MODO.MULT` devolve todas as modas, aqui 5 e 4, como uma
lista que ocupa várias células.

Então `MODO.ÚNICO` informando 5 para as notas é uma afirmação verdadeira que esconde metade da verdade.
Olhe as contagens antes de confiar numa moda única.

## Escrever a fórmula não é escolher o resumo

A planilha calcula `MÉDIA` sobre uma coluna de CEPs ou de códigos de pagamento sem reclamar, como a aula 2
avisou. A fórmula é o último passo. O primeiro é decidir que centro a escala da variável permite, e as
duas próximas seções ajudam no segundo passo: decidir qual deles a pergunta precisa.
