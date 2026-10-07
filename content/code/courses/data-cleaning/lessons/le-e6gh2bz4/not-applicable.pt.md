---
title: Vazios que são respostas
version: 1
---

**Antes de perguntar por que um valor falta, pergunte se um valor deveria existir.** Boa parte dos
vazios de qualquer arquivo real são respostas e não lacunas: a pergunta não se aplicava, ou é o
jeito de o sistema dizer zero, ou é um fato de que o negócio nunca precisou. Separá-los primeiro não
é arrumação. É tirar o ruído que, de outro modo, esconderia os vazios que importam.

Três tipos aparecem nos arquivos da Quitanda Verde.

**Não se aplica.** Uma retirada não tem entregador nem tempo de entrega, porque nada foi entregue.
No arquivo de pedidos, isso responde por 5.717 vazios em `courier` e pelos mesmos 5.717 em
`delivery_minutes`. Esses vazios estão certos, e **o tratamento certo é deixá-los vazios e parar de
contá-los como faltantes**: uma regra de completude para tempos de entrega deve testar entregas, e
foi assim que o quadro da aula 1 foi de 54% para 97%.

**Um vazio que quer dizer zero.** O desconto vazio do site é um desconto de nada, o mesmo fato que o
aplicativo escreve como `0`. Aqui o vazio é uma grafia, e a aula 4 o troca pelo zero que ele quer
dizer. Fazer isso só é seguro porque o significado foi estabelecido — pelo perfil da aula 2, que
mostrou todo vazio vindo de um sistema e todo zero do outro, e pelo fato de que os cupons em si
aparecem como valores nos dois.

**Desconhecido, e inofensivo para a maior parte dos usos.** No balcão de uma loja, o cliente pode dar
um número de fidelidade ou não:

```
ana@lab:~/clean$ psql -c "SELECT cliente IS NULL AS no_customer, count(*), round(avg(replace(substr(total, 4), ',', '.')::numeric), 2) AS avg_total FROM raw.store_sales GROUP BY 1"
 no_customer | count | avg_total 
-------------+-------+-----------
 f           |  8188 |     65.58
 t           | 15406 |     65.68
(2 rows)
```

Duas vendas em três não têm cliente. **A venda aconteceu e o comprador é desconhecido.** Para a
receita, o vazio não importa nada. Para qualquer coisa sobre clientes — com que frequência voltam, o
que compram — importa muito, e a pergunta passa a ser se o terço identificado se parece com o resto.
O tíquete médio é o teste mais barato que existe: R$ 65,58 com cliente e R$ 65,68 sem, o que não é
indício de que os dois grupos comprem diferente. Não prova que se pareçam em todo o resto; deixa de
achar uma diferença onde a mais óbvia estaria.

## Escreva o significado

Cada um desses é uma decisão, e a decisão precisa morar em outro lugar que não a memória da
analista. Uma tabela curta resolve:

| coluna | o vazio quer dizer | então |
|---|---|---|
| `courier`, `delivery_minutes` numa retirada | não houve entrega | deixar vazio, excluir da completude |
| `delivery_minutes` numa entrega da Rapidex | a parceira nunca informa tempos | deixar vazio; tempos de entrega descrevem só a frota própria |
| `discount` no site | zero | trocar por 0 |
| `cliente` nas lojas | venda sem número de fidelidade | deixar vazio; análise por cliente cobre um terço das vendas |
| `delivery_minutes`, frota própria, entregue | **ainda não se sabe** | o resto desta aula |

A última linha é o que sobra depois de tirar as respostas do caminho: 441 pedidos entregues e 15
reembolsados dos entregadores da própria empresa, sem tempo e sem motivo na linha. Tirar as
retiradas e as entregas da Rapidex do caminho é o que torna esses 456 vazios visíveis.
