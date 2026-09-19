---
title: Muitos-para-muitos, e a tabela que ninguém pensa em criar
version: 1
---

Agora o formato em que as duas direções respondem "sim".

Um pedido contém vários produtos. Um produto aparece em vários pedidos. Nenhum dos lados é o "um",
então não há lado onde pôr a chave estrangeira — e é aqui que a regra da seção anterior acaba.

A resposta é que **a própria relação é uma coisa, e coisas ganham tabelas.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 192\" role=\"img\" aria-label=\"Dois painéis. À esquerda, intitulado lugar nenhum para a chave: uma tabela de pedidos e uma de produtos, cada uma com uma coluna marcada com interrogação apontando para a outra, e uma nota de que uma coluna guarda um valor onde isto precisa de vários. À direita, intitulado a relação é uma coisa e coisas ganham tabelas: as mesmas duas tabelas com uma terceira entre elas, order_lines, guardando order_id e product_id, uma seta para cada lado, e uma nota de que o par é a chave — uma linha por pedido e produto.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Um pedido tem vários produtos e um produto está em vários pedidos. Nenhum dos lados é o \"um\".</text><rect x=\"14\" y=\"44\" width=\"300\" height=\"116\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"164\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">lugar nenhum para a chave</text><rect x=\"34\" y=\"80\" width=\"110\" height=\"60\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"89\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">orders</text><text x=\"89\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">product_id?</text><rect x=\"184\" y=\"80\" width=\"110\" height=\"60\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"239\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">products</text><text x=\"239\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">order_id?</text><text x=\"164\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">uma coluna de cada lado guarda um valor, e são precisos vários</text><rect x=\"346\" y=\"44\" width=\"360\" height=\"116\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"526\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">a relação é uma coisa, e coisas ganham tabelas</text><rect x=\"366\" y=\"86\" width=\"96\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"414\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">orders</text><rect x=\"590\" y=\"86\" width=\"96\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"638\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">products</text><rect x=\"486\" y=\"80\" width=\"78\" height=\"60\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"525\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">order_lines</text><text x=\"525\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">order_id</text><text x=\"525\" y=\"126\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">product_id</text><path d=\"M484 110 L466 110\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></path><path d=\"M466 110 L474.0 106.0 L474.0 114.0 Z\" fill=\"var(--phosphor)\"></path><path d=\"M566 110 L588 110\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></path><path d=\"M588 110 L580.0 114.0 L580.0 106.0 Z\" fill=\"var(--phosphor)\"></path><text x=\"526\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">o par é a chave: uma linha por pedido-e-produto</text><text x=\"14\" y=\"180\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Todo muitos-para-muitos em todo banco relacional que já existiu é uma terceira tabela. Não há outro arranjo.</text></svg>", "caption": "A terceira tabela não é um contorno para um recurso que falta. Ela é a relação, escrita como aquilo que ela é."}
```

```sql
CREATE TABLE order_lines (
    order_id   integer NOT NULL REFERENCES orders   (id) ON DELETE CASCADE,
    product_id integer NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    quantity   integer NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (order_id, product_id)
);
```

Uma terceira tabela, guardando duas chaves estrangeiras. Ela tem vários nomes — **tabela de
ligação**, tabela de junção, tabela associativa — e todos significam isto. Toda relação
muitos-para-muitos em todo banco relacional que já existiu é uma terceira tabela. Não há outro
jeito, e depois que você vê o formato reconhece ele em todo lugar: alunos e cursos, atores e filmes,
marcadores e artigos, usuários e papéis.

## Lendo as três tabelas

Uma linha de `order_lines` diz: *este pedido contém este produto, esta quantidade de vezes.*

| order_id | product_id | quantity |
|---|---|---|
| 1001 | 7 | 1 |
| 1002 | 7 | 2 |
| 1002 | 12 | 1 |
| 1003 | 12 | 1 |

O pedido 1002 contém dois produtos, o produto 7 está em dois pedidos, e a chave primária composta
`(order_id, product_id)` diz que o mesmo produto não pode ser listado duas vezes num pedido. Se
alguém acrescenta outra chaleira, a `quantity` vai de 2 para 3; uma segunda linha para o mesmo par é
recusada.

As duas direções agora são respondíveis, e pelo mesmo método — procure linhas que guardam o número
que você tem:

- **O que tem no pedido 1002?** As linhas com `order_id = 1002`, depois siga cada `product_id`.
- **Quais pedidos contêm o produto 7?** As linhas com `product_id = 7`, depois siga cada `order_id`.

## Os dois cascades apontam para lados diferentes, de propósito

Olhe de novo as duas cláusulas `ON DELETE`, porque elas discordam e a discordância é a lição:

```sql
order_id   integer NOT NULL REFERENCES orders   (id) ON DELETE CASCADE
product_id integer NOT NULL REFERENCES products (id) ON DELETE RESTRICT
```

**Apagar um pedido apaga as linhas dele.** Uma linha que diz "uma chaleira" sem um pedido em volta
não é registro de nada — não tem sentido sozinha, e ninguém jamais vai perguntar por ela. `CASCADE`.

**Apagar um produto não pode apagar as linhas que o mencionam.** Essas linhas são o histórico do que
as pessoas compraram. `RESTRICT` recusa a exclusão, que é o banco apontando que você não pode
des-vender algo — e a resposta certa é quase sempre marcar o produto como descontinuado em vez de
removê-lo.

Esse é o mesmo julgamento da seção anterior, aplicado duas vezes numa tabela, e vale parar nele: os
dois lados de uma tabela de ligação normalmente não são simétricos, mesmo que a tabela pareça
tratá-los igual.

## Quando a relação tem fatos próprios

`quantity` é a razão de esta seção ter um título além de "crie uma terceira tabela".

Uma tabela de ligação pura guardaria só as duas chaves. No momento em que você pergunta "quantos?",
"a que preço?", "desde quando?", "que nota?" — esses fatos pertencem ao *par*, não a nenhum dos
lados. A quantidade não é propriedade do pedido (que tem vários produtos) nem do produto (que está
em vários pedidos). É propriedade *deste produto neste pedido*.

```sql
CREATE TABLE order_lines (
    order_id     integer NOT NULL REFERENCES orders   (id) ON DELETE CASCADE,
    product_id   integer NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    quantity     integer NOT NULL CHECK (quantity > 0),
    unit_price   numeric(10,2) NOT NULL,
    PRIMARY KEY (order_id, product_id)
);
```

**`unit_price` na linha, e não lido do produto, é deliberado e é uma regra que vale levar deste
curso.** O preço atual do produto é quanto ele custa hoje. O que este cliente foi cobrado é quanto
custava no dia em que comprou, e são dois fatos diferentes. Ponha o preço só em `products` e todo
pedido passado se reprecifica sozinho na próxima vez que alguém mudar um preço — a fatura que você
imprimiu em março deixa de bater com o banco em abril, e nada deu errado que alguém possa apontar.

Isso parece a duplicação contra a qual o modelo inteiro se opõe, e não é, por uma razão precisa:
**não é uma cópia do mesmo fato, é um fato diferente que por acaso teve o mesmo valor uma vez.**
"Quanto isto custa" e "quanto isto custou naquele dia" são independentes, e fatos independentes são
guardados de forma independente.

Reconhecer essa diferença — cópia contra instantâneo — é uma das partes genuinamente difíceis de
modelagem, e é a razão de a aula 2 dedicar tempo a quando *não* normalizar.

## O formato, uma vez, para você reconhecer

Três tabelas. As duas pontas guardam as coisas; o meio guarda o par e tudo que for verdade sobre o
par.

```
products          order_lines               orders
---------         --------------------      ---------
id  <------------ product_id                id
name              order_id ----------->     ordered_on
price             quantity                  customer_id
                  unit_price
```

As setas apontam da chave estrangeira para a chave primária que ela referencia, que é a direção que
o banco impõe: todo `product_id` no meio tem que existir à esquerda.

**E um último aviso que poupa uma tarde.** Quando você consulta através de uma tabela de ligação
está combinando linhas, e o número de linhas que volta não é o número de pedidos — o pedido 1002
aparece duas vezes acima, uma por linha. Contar pedidos contando linhas depois de uma junção é a
resposta errada mais comum em SQL, e a aula 6 é onde isso recebe tratamento adequado. Por ora: note
que a tabela do meio multiplica, e desconfie de qualquer total que ficou maior do que você
esperava.
