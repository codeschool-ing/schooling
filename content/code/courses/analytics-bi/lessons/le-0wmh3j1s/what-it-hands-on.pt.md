---
title: O que a exploração entrega ao próximo passo
version: 1
---

Uma análise exploratória termina com uma lista, e não com um gráfico. Ninguém precisa ver o
histograma de novo; todo mundo que constrói um número sobre estas tabelas precisa saber o que foi
encontrado. Aqui está a da Lantern, como iria para o time:

| achado | evidência | consequência |
|---|---|---|
| `order_lines` é uma linha por produto num pedido | 11.362 linhas, 7.102 pedidos | contar pedidos em `orders`, nunca nas linhas |
| o valor do pedido é assimétrico à direita | mediana R$ 95,80, média R$ 170,23 | mostrar a mediana ao lado de qualquer média |
| duas populações: home e office | medianas R$ 85,80 e R$ 456,25 | separar por segmento antes de resumir |
| três linhas com preço 100× maior | pedidos 412, 415, 431 | corrigir na origem; até lá, excluir e dizer |
| o cliente 1 é a conta de teste da loja | quatro pedidos de um a três centavos | excluir de todo número de vendas |
| falta o dia 14 de agosto de 2025 | zero pedidos entre dias de 5 a 15 | os totais de agosto de 2025 estão curtos |
| junho de 2026 é um mês parcial | os dados terminam em 17 de junho | nunca comparar com um mês inteiro |
| o domingo vale meio dia útil | 537 pedidos contra cerca de 1.000 | comparar um dia com o mesmo dia da semana |
| a correlação do desconto é o segmento | *r* 0,271 geral, −0,005 dentro de home | não afirmar que desconto aumenta o pedido |

**Cada linha dessa tabela é algo que um painel, de outro modo, erraria em silêncio.** Nenhuma
delas aparece num número só: cada uma foi encontrada olhando uma distribuição, um extremo, um
buraco ou um grupo.

## Dos achados às definições

Olhe a última coluna. Metade dela é uma decisão sobre o que um número deve incluir: pedidos
estornados ou não, a conta de teste ou não, o mês parcial ou não, o valor bruto ou o valor depois
do desconto. Dois analistas que tomam essas decisões de jeitos diferentes vão estar os dois certos
sobre a própria consulta e vão discordar sobre a receita da Lantern.

Essa discordância é a aula 2. Antes de qualquer ferramenta desenhar um gráfico, as pessoas que
leem os números precisam combinar o que cada um significa, e escrever isso onde todo mundo lê a
mesma frase.
