---
title: Métricas de vaidade
version: 1
---

Alguns números são escolhidos porque ficam bonitos, e o jeito mais comum de ficar bonito é não poder
cair. **Um total acumulado só cresce**: clientes cadastrados, downloads do aplicativo desde o
lançamento, visualizações de página desde que o site abriu, produtos já cadastrados. Cada trimestre
novo é um recorde por construção, e um gráfico disso sobe o que quer que a empresa faça. Um número
assim é uma **métrica de vaidade**: ele elogia quem o apresenta e não muda a decisão de ninguém.

## O recorde que esconde uma queda

A loja online da Varanda conta clientes cadastrados: todo mundo que um dia criou uma conta. No fim de
cada trimestre de 2025, com os clientes que de fato compraram algo nos últimos doze meses ao lado:

| | A | B | C |
|---|---|---|---|
| 1 | Trimestre | Cadastrados | Ativos |
| 2 | T1 | 188300 | 61200 |
| 3 | T2 | 195900 | 60400 |
| 4 | T3 | 203700 | 58900 |
| 5 | T4 | 212400 | 57800 |

```localised
=ARRED((B5/B2-1)*100;1)      12,8
=ARRED((C5/C2-1)*100;1)      -5,6
```

Os clientes cadastrados cresceram **12,8%** no ano, um recorde novo a cada trimestre, e esse era o
número no slide do marketing. Os clientes ativos **caíram 5,6%** no mesmo ano: 3.400 pessoas a menos
comprando, enquanto 24.100 pessoas a mais tinham conta. A parcela das contas que compram foi de 32,5%
para 27,2%:

```localised
=ARRED(C2/B2*100;1)      32,5
=ARRED(C5/B5*100;1)      27,2
```

**O total de cadastrados não consegue mostrar um cliente indo embora, porque ninguém apaga a conta
quando para de comprar.** Ele conta todo mundo que chegou e ninguém que saiu, então sobe num ano bom e
num ano ruim do mesmo jeito.

## O teste

O teste para uma métrica de vaidade é uma pergunta: **se este número dobrasse amanhã, o que você faria
de diferente?** Para clientes cadastrados, a resposta honesta é nada, porque uma dobra poderia vir de
um sorteio que distribui contas sem que ninguém compre nada. Para clientes ativos, a resposta é
concreta: as campanhas que alcançam quem parou de comprar, os produtos que essas pessoas compravam, os
motivos de terem parado. É isso que torna um número **acionável**: um movimento nele aponta para algo
a fazer.

Alguns pares comuns, o número de vaidade primeiro:

| fica bonito | diz alguma coisa |
|---|---|
| clientes cadastrados | clientes ativos, que compraram nos últimos 12 meses |
| downloads do aplicativo | pessoas que usaram o aplicativo nos últimos 30 dias |
| visualizações de página | visitas que terminaram em pedido (conversão, aula 10) |
| seguidores nas redes sociais | pedidos que vieram das redes sociais |
| produtos cadastrados | produtos que venderam ao menos uma vez no trimestre |

Cada número da direita pode cair, e é por isso que vale a pena lê-lo. É também por isso que os da
esquerda são populares: uma equipe avaliada por um número prefere um que não pode descer.

## Vaidade é um uso, não um tipo de número

Clientes cadastrados não é um número inútil. Quem planeja a capacidade do sistema de e-mail precisa
dele, e para essa pessoa ele decide alguma coisa. **O que torna um número de vaidade é apresentá-lo
como progresso a pessoas cujas decisões ele não consegue informar.** O mesmo total é métrica numa
página e vaidade em outra, que é a distinção da aula 10 vista do outro lado: um KPI é escolhido para
uma decisão, e uma métrica de vaidade é escolhida para uma plateia.
