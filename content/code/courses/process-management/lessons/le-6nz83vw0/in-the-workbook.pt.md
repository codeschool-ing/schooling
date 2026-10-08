---
title: Estimativas de três pontos na planilha
version: 1
---

A aritmética desta aula cabe numa folha da planilha que você montou na aula 3. Disponha as quatro tarefas com seus três números, acrescente três colunas calculadas, e os totais vêm em seguida.

## A disposição

Ponha os cabeçalhos na primeira linha — **Tarefa**, **O**, **M**, **P**, **Média**, **DP**, **Variância** — e uma tarefa por linha abaixo, com a API de horários na linha 2. Para essa primeira linha, as três células calculadas são:

```localised
E2   =(B2+4*C2+D2)/6      6
F2   =(D2-B2)/6
G2   =F2^2
```

Copie-as até a linha 5. A integração de pagamento, na linha 4, mostra um desvio padrão de **2,83333333333333** em F4, que é o LibreOffice imprimindo todos os dígitos que tem.

## Os totais

Abaixo das tarefas, ou numa coluna própria, os quatro totais. Estas são as fórmulas numa planilha em português e o que o LibreOffice devolveu para elas:

```localised
=SOMA(E2:E5)                               20,5
=SOMA(G2:G5)                               12,25
=RAIZ(SOMA(G2:G5))                         3,5
=SOMA(E2:E5)+1,04*RAIZ(SOMA(G2:G5))        24,14
=SOMA(C2:C5)                               17
=SOMA(D2:D5)                               46
```

Numa planilha em inglês, `SOMA` é `SUM` e `RAIZ` é `SQRT`:

```localised
=SUM(E2:E5)                                20.5
=SUM(G2:G5)                                12.25
=SQRT(SUM(G2:G5))                          3.5
=SUM(E2:E5)+1.04*SQRT(SUM(G2:G5))          24.14
=SUM(C2:C5)                                17
=SUM(D2:D5)                                46
```

## Usando

O valor da folha é ser rápida de mudar. Baixe o pessimista da integração de pagamento de 20 para 12, como o time poderia fazer depois de um bom primeiro dia com o ambiente de testes do provedor, e o total do percentil 85 cai; acrescente uma quinta tarefa e todos os totais se mexem. Tente as duas coisas: é o jeito mais rápido de ver quanto uma cauda longa contribui para o todo, e qual tarefa merece atenção primeiro.

Confira uma linha à mão antes de confiar na coluna, como a aula 3 recomendou: para a API de horários, (3 + 4 × 5 + 13) / 6 = 36 / 6 = 6.
