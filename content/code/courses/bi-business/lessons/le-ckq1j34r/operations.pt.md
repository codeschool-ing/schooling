---
title: Operações: estoque, depósito e entregas
version: 1
---

Operações é tudo que acontece com as mercadorias entre o fornecedor e o cliente: comprá-las, guardá-las,
levá-las até uma loja ou até a porta de alguém. Na Varanda essa é a área de Caio Barreto, com o depósito
de Contagem no centro. **Os números dela tratam de duas coisas que puxam em sentidos opostos: ter as
mercadorias certas onde os clientes as querem, e não prender dinheiro em mercadoria que ninguém está
comprando.** A maioria das decisões operacionais é escolher onde ficar entre as duas.

## Estoque: quanto, e com que velocidade gira

Estoque é dinheiro em forma de sofá. Em média, nos doze fechamentos de mês de 2025, a Varanda tinha
R$ 9,48 milhões de estoque a custo. Sozinho, esse número não diz nada; diante do custo do que foi
vendido no ano, R$ 55,37 milhões, da seção de finanças, ele diz com que velocidade as mercadorias
andam. Digite os dois numa aba, o custo das mercadorias vendidas em B2 e o estoque médio em B3:

```localised
=ARRED(B2/B3;1)          5,8
=ARRED(B3/B2*365;1)      62,5
```

**O estoque girou 5,8 vezes no ano, que é o mesmo fato que 62,5 dias de estoque**: em média, um item
ficou cerca de dois meses entre chegar e ser vendido. Os dois são o mesmo número de cabeça para baixo,
e as empresas usam um ou outro por costume. Os dois são médias de mercadorias muito diferentes. Um
pacote de sementes pode vender em uma semana enquanto uma mesa de jantar espera meio ano, e por isso
operações olha os dias de estoque por categoria, nunca só para a empresa inteira.

Vale ter de cabeça quanto custa um dia de estoque:

```localised
=ARRED(B2/365;1)      151,7
```

**Um dia a mais de estoque prende cerca de R$ 152.000** a custo — dinheiro que não está no banco, que
paga espaço no depósito e corre o risco de sair de moda.

## Entregas: no prazo, e em quanto tempo

Os móveis saem do depósito nos caminhões da própria Varanda. Em 2025 eles fizeram 14.600 entregas, e 949
chegaram depois da data prometida, os mesmos registros de que Caio se lembrava errado na aula 2:

```localised
=ARRED((14600-949)/14600*100;1)      93,5
```

**93,5% no prazo.** Ao lado disso operações acompanha o **prazo de entrega**, os dias entre o pedido e a
entrega, porque uma entrega pode chegar no prazo de uma promessa de três semanas e mesmo assim perder o
cliente para um concorrente que promete três dias. O que "no prazo" quer dizer — o dia prometido, ou
dentro de uma janela, contando ou não as entregas que o cliente remarcou — é uma definição, e a aula 10
mostra duas versões razoáveis dando duas taxas diferentes.

## O dilema

A tensão do primeiro parágrafo tem nome: **nível de serviço contra custo de estoque.** Mantenha mais
estoque e menos clientes encontram a prateleira vazia, mas mais dinheiro fica parado no depósito.
Mantenha menos e o dinheiro fica livre, mas alguns clientes vão embora sem comprar, e nada nos dados de
vendas registra a venda que não aconteceu. Entregas mais rápidas pedem mais caminhões ou mais estoque
perto do cliente; as duas coisas custam dinheiro.

Não há resposta certa em geral, só uma resposta certa para um produto e uma época. **O que o analista
traz são os números dos dois lados da balança**, para que a decisão de Caio sobre o estoque de Natal
seja uma escolha entre dois custos conhecidos, e não entre uma preocupação com prateleiras vazias e uma
preocupação com o saldo do banco. A aula 9 calcula uma dessas decisões, um ponto de reposição, com
números.
