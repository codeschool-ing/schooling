---
title: Quem lê, e o que decide
version: 1
---

**Um painel se projeta de trás para a frente, da decisão que ele serve até as células que a
servem.** O caminho de costume é o contrário: abrir os dados, fazer todo gráfico que eles permitem
e espalhar tudo numa planilha. O resultado mostra tudo e não responde nada, porque ninguém disse
para que ele servia.

O painel da Café Serra tem um leitor e uma decisão. A dona abre o painel no começo de cada mês e
decide para onde vai o esforço do próximo trimestre: mais visitas aos clientes de atacado, uma
promoção na loja virtual, mais estoque de um produto e menos de outro. Tudo na planilha precisa
ajudar nessa decisão, e o que não ajuda sai.

## Da decisão a quatro KPIs

O curso `bi-business`, na posição 2 da trilha, dá o vocabulário. Uma **métrica** é qualquer número
que dá para calcular a partir dos dados. Um **KPI** é uma das poucas métricas que alguém escolheu
para se guiar, e vem com uma definição, uma comparação, um dono e uma frequência. A Café Serra tem
centenas de métricas possíveis e precisa de quatro KPIs:

| KPI | definição | medida | jan–jun 2026 | jan–jun 2025 |
|---|---|---|---|---|
| **Receita** | a soma de `Bags` × `Price` no período | `Revenue` | R$ 15.943 | R$ 17.789 |
| **Sacos** | sacos vendidos no período | `Bags` | 168 | 218 |
| **Vendas** | vendas registradas no período | `Sales count` | 36 | 36 |
| **Venda média** | receita dividida pelo número de vendas | `Average sale` | R$ 443 | R$ 494 |

As três primeiras medidas são da aula 16. A quarta é mais uma linha no mesmo lugar, feita de duas
que já existem:

```dax
Average sale := DIVIDE ( [Revenue], [Sales count] )
```

A dona é quem abre o painel, e a frequência é mensal. A comparação é a coluna da direita, e é a
parte que as pessoas esquecem.

## Um número sem nada ao lado não é um KPI

R$ 15.943 sozinho não diz nada à dona. É bom? Ao lado de R$ 17.789 nos mesmos seis meses de 2025,
diz que a receita está **10,4% menor** do que um ano antes, e isso é algo sobre o qual agir. A medida
`YoY %` da aula 16 é exatamente essa comparação, e vai para a tela ao lado de cada número a que se
aplica.

A comparação precisa ser **de igual para igual**. Janeiro a junho de 2026 contra o ano inteiro de
2025 põe seis meses contra doze e mostra uma queda de 55,2%, que é falsa e alarmante. Os mesmos
meses um ano antes são a comparação justa quando não há outra, e é o que a medida `Revenue LY` da
aula 16 calcula.

Um KPI completo também tem uma **meta**, um número com que alguém se comprometeu. Os dados da Café
Serra não têm meta, então o ano anterior faz esse papel. Um painel que tenha meta deve mostrá-la,
porque "10,4% abaixo do ano passado" e "2% acima do plano" podem ser verdade ao mesmo tempo, e o
plano é o que a dona combinou.

## E um que fica de fora

A margem bruta parece um quinto KPI óbvio: a receita menos o que o café custou. A planilha
`Products` tem a coluna `Unit cost`, então a fórmula é fácil de escrever. Mas essa coluna guarda
**um custo por produto, o de hoje**. Aplicada às vendas de 2025, ela calcula uma margem de 2025 com
custos de 2026, e nada na tela diria isso.

Um painel ganha crédito porque parece pronto, então **um KPI que os dados não sustentam com
honestidade fica fora dele** até que os dados sustentem. Aqui, isso quer dizer uma tabela de custos
com a data em que cada um passou a valer. Quatro números verdadeiros servem melhor à dona do que
cinco em que um está errado sem avisar.
