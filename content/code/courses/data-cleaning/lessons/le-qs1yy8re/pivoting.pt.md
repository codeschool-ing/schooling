---
title: Pivotando, e duas linhas numa célula
version: 1
---

O movimento oposto, do longo para o largo, é **pivotar**: os valores de uma coluna viram os novos
cabeçalhos, e outra coluna preenche as células. As vendas são longas por natureza, uma linha por
venda. Para lê-las ao lado das metas, elas precisam de uma linha por loja e uma coluna por mês.

O `actuals.py`, mostrado inteiro na próxima seção, empilha as vendas do caixa das lojas e os pedidos
online entregues numa única tabela longa chamada `sales`, com três colunas: `loja`, `month`,
`amount`. Pivotando direto:

```
ana@lab:~/clean$ python -c "from actuals import sales; sales.pivot(index='loja', columns='month', values='amount')" 2>&1 | tail -1
ValueError: Index contains duplicate entries, cannot reshape
ana@lab:~/clean$ python -c "from actuals import sales; print(len(sales), len(sales[['loja', 'month']].drop_duplicates()))"
50104 72
```

O `pivot` se recusa, e com razão. Ele põe exatamente um valor em cada célula, e **há 50.104 vendas
para só 72 células de loja e mês**. Ele não sabe o que fazer com as centenas de vendas que dividem
uma célula, então para em vez de escolher.

O `pivot_table` é a versão a quem se diz o que fazer: um `aggfunc` que transforma os muitos valores
de uma célula em um.

```
ana@lab:~/clean$ python -c "from actuals import sales; w = sales.pivot_table(index='loja', columns='month', values='amount', aggfunc='sum'); print(w.shape); print(w.iloc[:, :3].round(2).to_string())"
(6, 12)
month        2025-01   2025-02   2025-03
loja                                    
Batel       14475.70   16645.9   19089.5
Botafogo    24815.80   24449.8   31686.7
Cambuí      15126.90   16271.5   19287.9
Online     124345.55  125994.1  164724.0
Pinheiros   49952.80   52629.7   62632.7
Savassi     15635.20   16955.1   20411.6
```

Seis lojas, doze meses, e cada célula com as vendas do mês somadas. É o padrão útil para dinheiro.
É também o lugar em que um pivot pode mentir sem erro, porque **a agregação roda sobre o que chegar
à célula**:

- **Linhas duplicadas são somadas, não recusadas.** Se os 25 pedidos repetidos da aula 5 ainda
  estivessem nos dados, o `pivot_table` os somaria em silêncio, onde o `pivot` ao menos teria
  parado.
- **A função precisa combinar com a medida.** `sum` serve para dinheiro e não serve para um preço ou
  uma nota, em que média ou mediana é o resumo honesto; o padrão do `pivot_table` é a média, então
  esquecer o `aggfunc` põe em cada célula a venda média por venda, sob um cabeçalho que parece de
  totais.
- **Uma célula vazia é um vazio, não um zero.** Se uma loja não tivesse vendas num mês, a célula
  seria `NaN`. Se isso deve ser 0 é a pergunta da aula 3: uma loja que não vendeu nada e uma loja
  cujo arquivo falta não são a mesma coisa.

**Use o `pivot` primeiro, e o `pivot_table` quando a recusa disser que os dados têm mais de uma
linha por célula.** O erro é informação sobre o grão, e a escolha do `aggfunc` passa a ser uma
decisão tomada de propósito.
