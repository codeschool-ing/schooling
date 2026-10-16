---
title: A lista de suspeitos
version: 1
---

A esta altura a pergunta é estreita: por que foram pagos 828 pedidos online a menos em outubro de
2025 do que em outubro de 2024, com o mesmo tíquete médio? Uma pergunta estreita ainda tem várias
respostas possíveis, e o hábito que separa um diagnóstico de uma história é **escrever todas antes
de testar qualquer uma**. A primeira explicação de que alguém gosta tende a ser a última que alguém
confere.

## A lista: o que mais mudou?

A maioria das mudanças no mês de um varejista vem de uma lista curta de lugares. A lista da Lívia,
com a evidência sobre cada um:

| suspeito | o que o mostraria | o que os dados da Varanda disseram |
|---|---|---|
| o calendário | menos dias de fim de semana, ou um feriado em dia útil | 8 dias de fim de semana nos dois outubros; o feriado de 12 de outubro caiu num fim de semana nos dois anos |
| preços | um tíquete médio diferente | R$ 350 nos dois outubros |
| estoque | itens mais vendidos sem estoque no site | nenhum produto entre os 20 mais vendidos online ficou sem estoque por mais de um dia |
| os próprios dados | a contagem de pedidos do site discordando da do banco de dados | os dois dizem 3.086 pedidos pagos |
| campanhas | uma campanha num outubro e não no outro | a campanha anual da loja online foi de 21 a 31 de outubro em 2024, e de 3 a 13 de novembro em 2025 |

**Os próprios dados estão na lista de propósito.** Um pipeline que para de copiar pedidos por três
dias produz exatamente o desenho que a árvore encontrou, um canal caindo com o tíquete igual, e é o
suspeito mais barato de testar. O Tiago Ramos, que mantém os pipelines, comparou a contagem de
pedidos pagos da própria loja online com a do banco de dados em cada dia de outubro, e elas bateram.

## Testando a campanha

Sobrou um suspeito de pé: a campanha mudou de lugar. A equipe da Renata Sá tinha feito a campanha
anual da loja online nos últimos onze dias de outubro em 2024. Em 2025 a moveram para as duas
primeiras semanas de novembro, para ficar mais perto dos maiores dias de compra da estação. Um
suspeito de pé ainda não é uma causa. A Lívia o testou de dois jeitos.

**Primeiro, dividindo outubro de 2024 na campanha.** Se a campanha explica a queda, os dias comuns de
outubro de 2025 devem se parecer com os dias comuns de outubro de 2024, um pouco melhores, e não com
os dias de campanha. Digite os pedidos numa tabela pequena:

| | A | B | C |
|---|---|---|---|
| 1 | | dias | pedidos |
| 2 | Out 2024, 1–20, sem campanha | 20 | 1760 |
| 3 | Out 2024, 21–31, campanha | 11 | 2154 |
| 4 | Out 2025, 1–31, sem campanha | 31 | 3086 |

e divida cada um pelos seus dias:

```localised
=ARRED(C2/B2;1)      88
=ARRED(C3/B3;1)      195,8
=ARRED(C4/B4;1)      99,5
```

Os dias comuns de outubro de 2025 tiveram em média 99,5 pedidos, 13,1% a mais que os 88 dos dias
comuns de outubro de 2024. Os dias de campanha de 2024 tiveram 195,8. **Outubro de 2025 não perdeu
clientes; perdeu onze dias de campanha.**

**Segundo, juntando outubro e novembro.** Se a campanha só mudou de lugar, o que outubro perdeu
novembro deveria ter ganhado. Online, outubro e novembro de 2024 venderam R$ 3.030 mil; em 2025
venderam R$ 3.140 mil, 3,6% a mais. A loja online de novembro sozinha cresceu 24,1%.

## O que sobra

A campanha explica por que outubro caiu. Não explica tudo. Juntos, outubro e novembro de 2025
cresceram 3,9% sobre os mesmos dois meses de 2024, abaixo dos 5,7% do ano, e as lojas também
cresceram 3,9% nos dois meses. **Alguma coisa deixou o fim do ano um pouco abaixo do resto, e essa
coisa não é a campanha.** A Lívia escreveu essa sobra no relatório como uma pergunta em aberto, em
vez de esticar a campanha para cobri-la. Esse é o assunto da próxima seção: como dizer o que um
diagnóstico encontrou, e nada além disso.
