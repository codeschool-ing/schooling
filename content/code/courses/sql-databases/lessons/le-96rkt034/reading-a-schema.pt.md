---
title: Lendo um esquema, e desenhando um
version: 1
---

Tudo nesta aula até aqui foi uma tabela por vez. Um **esquema** é todas elas juntas com as
referências entre elas, e conseguir ler um numa tela — de outra pessoa, de um sistema em que você
acabou de entrar — é uma habilidade prática que paga imediatamente.

Aqui está a loja, completa:

```sql
CREATE TABLE customers (
    id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name   text    NOT NULL,
    email  text    NOT NULL UNIQUE,
    city   text
);

CREATE TABLE products (
    id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku    text          NOT NULL UNIQUE,
    name   text          NOT NULL,
    price  numeric(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE orders (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id integer NOT NULL REFERENCES customers (id) ON DELETE RESTRICT,
    ordered_on  date    NOT NULL DEFAULT current_date,
    total       numeric(10,2) NOT NULL CHECK (total >= 0),
    status      text    NOT NULL DEFAULT 'placed'
                        CHECK (status IN ('placed', 'shipped', 'cancelled'))
);

CREATE TABLE order_lines (
    order_id   integer NOT NULL REFERENCES orders   (id) ON DELETE CASCADE,
    product_id integer NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    quantity   integer NOT NULL CHECK (quantity > 0),
    unit_price numeric(10,2) NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (order_id, product_id)
);
```

Quatro tabelas. Lidas nessa ordem elas contam uma história: quem compra, o que é vendido, o que foi
comprado, e o que havia nisso.

**O `orders.total` é o único valor aqui que daria para descobrir em outro lugar** — some as linhas e
você o tem. Ele é guardado mesmo assim, porque toda tela que lista pedidos o quer e nenhuma delas
quer um join para consegui-lo. Isso é uma troca e não um erro, e a aula 2 é onde ela é argumentada
direito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um diagrama de entidade e relacionamento com quatro tabelas. Customers e products ficam nas pontas; orders fica entre customers e order lines; order lines fica entre orders e products. Uma bifurcacao marca o lado muitos de cada relacao: um cliente para muitos pedidos, um pedido para muitas linhas, um produto para muitas linhas.\"><rect x=\"18\" y=\"40\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"18\" y=\"40\" width=\"150\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\"></rect><text x=\"28\" y=\"53\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">customers</text><text x=\"28\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">id</text><text x=\"28\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">name</text><text x=\"28\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">email</text><text x=\"28\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">city</text>\n<rect x=\"285\" y=\"40\" width=\"150\" height=\"116\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"285\" y=\"40\" width=\"150\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" fill-opacity=\".2\"></rect><text x=\"295\" y=\"53\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><text x=\"295\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">id</text><text x=\"295\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">customer_id</text><text x=\"295\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ordered_on</text><text x=\"295\" y=\"132\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">total</text><text x=\"295\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">status</text>\n<rect x=\"285\" y=\"196\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"285\" y=\"196\" width=\"150\" height=\"24\" rx=\"3\" fill=\"var(--wire)\" fill-opacity=\".3\"></rect><text x=\"295\" y=\"209\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">order_lines</text><text x=\"295\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">order_id</text><text x=\"295\" y=\"252\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">product_id</text><text x=\"295\" y=\"270\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">quantity</text><text x=\"295\" y=\"286\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">unit_price</text>\n<rect x=\"552\" y=\"196\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"552\" y=\"196\" width=\"150\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\"></rect><text x=\"562\" y=\"209\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">products</text><text x=\"562\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">id</text><text x=\"562\" y=\"252\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sku</text><text x=\"562\" y=\"270\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">name</text><text x=\"562\" y=\"286\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">price</text>\n<path d=\"M168 88 L285 88\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M285 78 L271 88 L285 98\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<text x=\"226\" y=\"78\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 → muitos</text>\n<path d=\"M360 156 L360 196\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M350 196 L360 182 L370 196\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<text x=\"370\" y=\"168\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 → muitos</text>\n<path d=\"M552 244 L435 244\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M435 234 L449 244 L435 254\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<text x=\"493\" y=\"234\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 → muitos</text>\n<text x=\"360\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">order_lines e o muitos-para-muitos entre orders e products. A bifurcacao e a ponta &#34;muitos&#34;.</text>\n</svg>", "caption": "As mesmas quatro tabelas como desenho. Os nomes em ambar sao chaves; a ponta bifurcada de cada linha e o lado que pode ter varios."}
```
## Como ler um que você não escreveu

Um diagrama como esse é a segunda coisa a olhar. A primeira é o texto do esquema, e há uma ordem que
te orienta mais rápido.

**1. Liste as tabelas e diga o que é uma linha de cada.** Em voz alta, com um substantivo no
singular. `orders` — uma linha é um pedido. `order_lines` — uma linha é um produto num pedido. Se
você não consegue terminar a frase para uma tabela, é dessa tabela que você deve perguntar a alguém;
ou ela está mal nomeada ou está guardando duas coisas.

**2. Ache as tabelas de ligação.** Uma tabela cuja chave primária são duas chaves estrangeiras é uma
relação, não uma coisa. É onde moram as perguntas interessantes, e identificá-las te diz na hora
quais pares de tabelas são muitos-para-muitos.

**3. Leia os `NOT NULL` como descrição do que é obrigatório.** `orders.customer_id NOT NULL` diz que
este sistema não tem pedidos anônimos. Isso é uma decisão de produto, visível no esquema, e muitas
vezes te conta mais sobre como o negócio funciona do que a documentação conta.

**4. Leia os `ON DELETE` como descrição do que é descartável.** `CASCADE` marca as partes;
`RESTRICT` marca os registros. Numa passada você aprende o que este sistema considera histórico.

**5. Procure as restrições ausentes.** Uma coluna `text` chamada `status` sem `CHECK`, uma coluna que
obviamente é email sem `UNIQUE`, uma coluna de dinheiro tipada como `double precision`. É onde estão
os bugs, e conseguir identificá-los em cinco minutos é a maior parte do que torna alguém útil na
primeira semana num sistema desconhecido.

## Pedindo ao banco que se descreva

Nem sempre vão te entregar os comandos `CREATE TABLE`. Todo banco sabe se descrever, e no `psql` os
comandos são curtos:

```
ana@vm:~$ psql shop
psql (16.13 (Ubuntu 16.13-0ubuntu0.24.04.1))
Type "help" for help.

shop=# \dt
          List of relations
 Schema |    Name     | Type  | Owner 
--------+-------------+-------+-------
 public | customers   | table | ana
 public | order_lines | table | ana
 public | orders      | table | ana
 public | products    | table | ana
(4 rows)

shop=# \d orders
                               Table "public.orders"
   Column    |     Type      | Collation | Nullable |           Default            
-------------+---------------+-----------+----------+------------------------------
 id          | integer       |           | not null | generated always as identity
 customer_id | integer       |           | not null | 
 ordered_on  | date          |           | not null | CURRENT_DATE
 total       | numeric(10,2) |           | not null | 
 status      | text          |           | not null | 'placed'::text
Indexes:
    "orders_pkey" PRIMARY KEY, btree (id)
Check constraints:
    "orders_status_check" CHECK (status = ANY (ARRAY['placed'::text, 'shipped'::text, 'cancelled'::text]))
    "orders_total_check" CHECK (total >= 0::numeric)
Foreign-key constraints:
    "orders_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
Referenced by:
    TABLE "order_lines" CONSTRAINT "order_lines_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
```

**A seção `Referenced by:` no rodapé é a que as pessoas não veem**, e é a parte mais útil. Ela
responde o que o `CREATE TABLE` não responde: *quem aponta para mim?* — que é o que você precisa
saber antes de mudar ou apagar qualquer coisa.

`\dt` e `\d` são do PostgreSQL. MySQL e MariaDB usam `SHOW TABLES` e `DESCRIBE orders`; SQLite usa
`.tables` e `.schema orders`. A aula 12 cobre as diferenças adequadamente.

## O projeto, numa página

Tudo desta aula, como a sequência que você de fato seguiria para modelar algo novo:

1. **Nomeie as coisas.** Substantivos de como as pessoas falam do trabalho: cliente, pedido,
   produto. Cada um vira uma tabela, cada uma com chave primária substituta.
2. **Escreva os fatos sobre cada coisa**, uma coluna cada, com um tipo. Dinheiro é `numeric`.
3. **Ache as relações e pergunte "vários?" nas duas direções.** Um "não" significa chave estrangeira
   do lado "muitos". Dois "sins" significam uma terceira tabela.
4. **Pergunte o que pertence ao par** em vez de a qualquer uma das pontas — quantidade, preço do
   dia, a data em que começou. Essas colunas vão na tabela de ligação.
5. **Faça toda coluna `NOT NULL`** exceto aquelas em que você consegue dizer o que vazio significa.
6. **Decida cada `ON DELETE`** perguntando se o filho é uma parte ou um registro.
7. **Acrescente um `CHECK` onde você escreveria um comentário.**

A aula 2 leva isso de procedimento a teoria — normalização é o nome do que os passos 1 a 4 estão
aproximando, tem regras que dizem com precisão quando um projeto está terminado, e também diz quando
quebrá-las deliberadamente.
