---
title: MÉDIASES, e a média de quê
version: 1
---

**Uma média é um total dividido por uma contagem, e a parte difícil é decidir o que a contagem
conta.** `MÉDIASES` (`AVERAGEIFS` no Excel em inglês) recebe os mesmos argumentos que `SOMASES`,
com o intervalo da média primeiro, e faz a divisão por você. Essa comodidade esconde a escolha, e a
escolha muda a resposta.

## Sacos por venda, por canal

```localised
=MÉDIASES(E2:E109; G2:G109; "Wholesale")
```

responde **10,605…**, cerca de 10,6 sacos por venda do atacado. A mesma fórmula com `"Online"` dá
**3,17** e com `"Shop"` **1,70**, arredondando em duas casas. Um pedido do atacado tem mais de três
vezes o tamanho de um pedido online.

É exatamente o total dividido pela contagem, como você pode provar na célula seguinte:

```localised
=SOMASES(E2:E109; G2:G109; "Wholesale")/CONT.SES(G2:G109; "Wholesale")
```

dá os mesmos 10,605…, de 403 sacos sobre 38 vendas. Escrever assim uma vez vale a digitação a mais,
porque mostra pelo que `MÉDIASES` divide: **linhas que passaram**, aqui vendas.

## Quando nenhuma linha passa

```localised
=MÉDIASES(E2:E109; D2:D109; "CER1K"; G2:G109; "Shop")
```

responde `#DIV/0!`. A Café Serra nunca vendeu um saco de 1 kg do Cerrado no balcão, então a contagem
é zero e não há pelo que dividir. Esse erro é informação: diz que o grupo está vazio, o que é
diferente de um grupo cuja média é zero. Escondê-lo atrás de `SEERRO` (`IFERROR`), da aula 3,
transformaria *nenhuma venda* num branco ou num 0 que o leitor toma por medida.

## Por venda ou por saco

Quanto a Café Serra recebeu por um saco de 1 kg do Cerrado? Duas fórmulas dão duas respostas:

```localised
=MÉDIASES(F2:F109; D2:D109; "CER1K")
=SOMASES(H2:H109; D2:D109; "CER1K")/SOMASES(E2:E109; D2:D109; "CER1K")
```

A primeira responde **110,107…**, cerca de R$ 110,11. A segunda responde **106,78**. As duas são
médias do preço de `CER1K`; discordam porque contam coisas diferentes.

`MÉDIASES` faz a média da coluna `Price` sobre **vendas**. Uma venda do atacado de 15 sacos a
R$ 104 conta uma vez, exatamente como uma venda online de um saco a R$ 115. A segunda fórmula divide
a receita, R$ 21.356, por **sacos**, 200, então os quinze sacos do atacado contam quinze vezes.
Clientes do atacado compram muitos sacos a preço mais baixo, então pesar por saco puxa a média para
baixo.

Nenhuma está errada; respondem perguntas diferentes. *Quanto uma venda típica de `CER1K` cobra por
saco* é a primeira. *Quanto rendeu um saco de `CER1K`* é a segunda, e é ela que multiplica de volta:
106,78 × 200 sacos dá os R$ 21.356 de receita, e 110,11 × 200 não dá. Quando uma média vai ser
multiplicada por uma quantidade, como numa previsão ou num orçamento, ela precisa ser a ponderada
por essa quantidade.

## Nunca tire a média das médias

O mesmo erro com outra cara: as três médias de sacos por venda dos canais são 10,6, 3,17 e 1,70, e
a média simples delas dá cerca de 5,16. A média real sobre as 108 vendas é

```localised
=MÉDIA(E2:E109)
```

que responde **5,472…**, 591 sacos sobre 108 vendas. A média das três deu a cada canal o mesmo
peso, como se 38 vendas do atacado e 23 vendas do balcão fossem o mesmo número de vendas. Uma média
de médias só está certa quando todo grupo tem a mesma contagem, o que em dados reais quase nunca
acontece. Volte aos totais e divida uma vez.
