---
title: Comparando dispersões entre escalas
version: 1
---

Um desvio padrão de 9,77 minutos é grande? E um de R$ 59,42? Os números não podem ser comparados
diretamente, porque estão em unidades diferentes. Mesmo dentro de uma unidade, uma dispersão de R$ 10 é
grande num café e pequena num carro.

O **coeficiente de variação** resolve os dois problemas dividindo o desvio padrão pela média:

```localised
CV = s ÷ média
```

Ele não tem unidade, porque as unidades se cancelam, e diz quão grande é a dispersão **em relação ao
tamanho típico**.

## As colunas da Horta comparadas

| coluna | média | desvio padrão | CV |
|---|---|---|---|
| minutos | 38,96 | 9,77 | 0,25 |
| itens | 6,25 | 4,20 | 0,67 |
| cesta (R$) | 79,17 | 59,42 | 0,75 |

Os tempos de entrega variam cerca de um quarto da média. As cestas variam três quartos da delas. Isso
combina com a loja: o tempo para atravessar Campinas não muda muito de pedido para pedido, enquanto uma
casa compra um litro de leite e a próxima faz a compra do mês.

## Onde se usa

O CV aparece onde quer que dispersões em escalas diferentes precisem ser comparadas.

- **Controle de qualidade**: uma envasadora cujo CV em sacos de 1 kg é 0,5% é mais estável que uma cujo CV
  em sacos de 5 kg é 2%, embora a segunda tenha os sacos maiores.
- **Laboratórios** informam o CV de medições repetidas como a precisão de um método.
- **Finanças** comparam o risco de investimentos de tamanhos diferentes pela dispersão por unidade de
  retorno.

## Seus limites

O CV exige uma **escala de razão**, com zero verdadeiro, que a aula 2 pôs como condição para razões. Em
temperaturas em Celsius ele não tem significado: a média depende de onde se pôs o zero, então o CV
mudaria com a escala.

Ele também se comporta mal quando a média está perto de zero. Uma média de 0,1 e um desvio padrão de 1
dão um CV de 10, o que diz mais sobre a média pequena que sobre a dispersão. Para variáveis que podem ser
negativas, como lucro, ele nem é usado.
