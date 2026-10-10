---
title: Medidas e colunas calculadas
version: 1
---

O DAX pode acrescentar dois tipos de coisa a um modelo, e escolher o errado é o engano de iniciante
mais comum no Power BI.

Uma **coluna calculada** é calculada uma vez por linha, quando os dados são carregados, e guardada
como qualquer outra coluna. É a certa para um atributo da linha pelo qual você quer agrupar ou
filtrar:

```
Order Size = IF ( orders[gross] >= 400, "large", "small" )
```

Uma **medida** é calculada quando um visual pede, sobre as linhas que o visual está mostrando
naquele momento. É a certa para qualquer coisa que se soma:

```
Net Revenue = SUM ( orders[net_revenue] )

Orders = COUNTROWS ( orders )

Net Revenue per Order = DIVIDE ( [Net Revenue], [Orders] )
```

(Não rodou: estão escritas a partir da documentação da Microsoft, como toda fórmula desta aula.)

A diferença aparece no momento em que você divide. Uma coluna calculada que divide algo em cada
linha, depois tirada a média por um visual, dá uma média de razões; uma medida que divide uma soma
por uma contagem dá a razão das somas. Essas são as duas médias da aula 2, e a aula 2 disse que o
número "da loja" é a razão das somas — então uma razão é uma medida, sempre.

`DIVIDE` em vez de `/` é um hábito que vale ter desde o primeiro dia: devolve branco em vez de erro
quando o denominador é zero, o que num relatório é um mês sem pedidos em alguma região.

## Medidas implícitas, e por que evitá-las

Arraste `net_revenue` para um gráfico e o Power BI soma sem ninguém pedir: uma **medida implícita**.
Funciona, e é o problema de camada semântica da aula 3 num lugar novo. Cada autor de relatório que
arrasta a coluna escolhe a agregação de novo — soma aqui, média ali — e o nome no gráfico é *Soma de
net_revenue* em vez de uma definição que alguém tem. **Escreva a medida uma vez, dê nome a ela,
esconda a coluna crua**, e quem monta relatórios sobre o modelo escolhe *Net Revenue* de uma lista,
como escolheu no menu do Metabase na aula 3.
