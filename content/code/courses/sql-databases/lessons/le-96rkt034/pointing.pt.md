---
title: A chave estrangeira: uma linha que aponta para uma linha
version: 1
---

A chave primária dá um nome a uma linha. A **chave estrangeira** é como outra linha o usa.

```sql
CREATE TABLE orders (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id integer NOT NULL REFERENCES customers (id),
    ordered_on  date    NOT NULL,
    total       numeric(10,2) NOT NULL
);
```

`REFERENCES customers (id)` é a ideia inteira deste curso numa cláusula. O pedido não guarda o
nome, o email nem a cidade da Ana. Ele guarda o número `1`, e o número `1` é a Ana, uma vez, em
outro lugar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas tabelas lado a lado. A tabela customers tem três linhas com ids 1, 2 e 3, cada uma com um nome e um e-mail escritos uma vez. A tabela orders tem quatro linhas, cada uma guardando um customer_id de 1, 2, 1 ou 1 em vez de uma cópia do nome. Três setas vão das linhas de orders de volta ao cliente 1, e uma ao cliente 2. Uma nota ao pé diz: o nome é escrito uma vez; os pedidos guardam um número.\"><rect x=\"14\" y=\"38\" width=\"296\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect><text x=\"26\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">customers</text><text x=\"120\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">id</text><text x=\"160\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">name</text><text x=\"232\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">email</text>\n<rect x=\"14\" y=\"62\" width=\"296\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"120\" y=\"75\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"160\" y=\"75\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Ana Lopes</text><text x=\"232\" y=\"75\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ana@…</text>\n<rect x=\"14\" y=\"88\" width=\"296\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"120\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">2</text><text x=\"160\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Bruno Sá</text><text x=\"232\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">bruno@…</text>\n<rect x=\"14\" y=\"114\" width=\"296\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"120\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">3</text><text x=\"160\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Célia Reis</text><text x=\"232\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">celia@…</text>\n<text x=\"26\" y=\"162\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">escrito uma vez</text>\n<rect x=\"410\" y=\"38\" width=\"296\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".18\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"422\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><text x=\"500\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">id</text><text x=\"540\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">customer_id</text><text x=\"648\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">date</text>\n<rect x=\"410\" y=\"62\" width=\"296\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"500\" y=\"75\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1001</text><text x=\"576\" y=\"75\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"648\" y=\"75\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">03-02</text>\n<rect x=\"410\" y=\"88\" width=\"296\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"500\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1002</text><text x=\"576\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">2</text><text x=\"648\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">03-02</text>\n<rect x=\"410\" y=\"114\" width=\"296\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"500\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1003</text><text x=\"576\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"648\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">03-04</text>\n<rect x=\"410\" y=\"140\" width=\"296\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"500\" y=\"153\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1004</text><text x=\"576\" y=\"153\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"648\" y=\"153\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">03-07</text>\n<text x=\"422\" y=\"188\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">apontado, quatro vezes</text>\n<path d=\"M404 75 C 372 75 348 75 316 75\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path>\n<path d=\"M404 101 C 372 101 348 101 316 101\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path>\n<path d=\"M404 127 C 372 127 348 84 316 78\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path>\n<path d=\"M404 153 C 372 153 348 88 316 82\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path>\n<text x=\"360\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">O email da Ana existe em exatamente um lugar.</text>\n<text x=\"360\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Corrija ali e os quatro pedidos ficam corretos, porque nenhum guardava uma copia.</text>\n</svg>", "caption": "Três dos quatro pedidos são da Ana, e nenhum deles contém o nome dela. Eles contêm o número 1."}
```
## O que o banco agora recusa

Declarar a referência compra algo que um comentário não compraria:

```sql
INSERT INTO orders (customer_id, ordered_on, total) VALUES (77, '2026-03-09', 39.90);
```

```
ERROR:  insert or update on table "orders" violates foreign key constraint "orders_customer_id_fkey"
DETAIL:  Key (customer_id)=(77) is not present in table "customers".
```

Não existe cliente 77, então não pode existir pedido pertencente ao cliente 77. O banco sabe disso
porque você disse uma vez, no `CREATE TABLE`, e ele vai continuar sabendo a cada inserção de cada
programa pelo tempo de vida dos dados.

Essa propriedade tem nome: **integridade referencial**. Todo ponteiro aponta para algo que existe.
Não "geralmente", não "enquanto a aplicação for cuidadosa" — sempre, por construção.

Considere o que isso elimina. Um pedido cujo cliente sumiu não é evento raro em sistemas sem isso; é
o estado final normal, porque sempre há mais programas escrevendo num banco do que alguém lembra. A
importação noturna, o script de migração que alguém rodou uma vez, a ferramenta de administração, o
colega consertando algo à mão às 2 da manhã. **Uma regra na aplicação é uma regra que vale para os
programas que a lembram. Uma regra no banco vale para todo mundo.**

## E o que acontece quando você apaga

A metade interessante é a outra direção. A Ana tem três pedidos. O que acontece com eles se a Ana
for apagada?

O banco não vai adivinhar. Você diz, quando a tabela é criada:

```sql
customer_id integer NOT NULL REFERENCES customers (id) ON DELETE RESTRICT
```

| cláusula | o que um `DELETE FROM customers WHERE id = 1` faz |
|---|---|
| `ON DELETE RESTRICT` | recusa, porque há pedidos apontando para aquela linha. O padrão, e normalmente o certo |
| `ON DELETE NO ACTION` | a mesma recusa, mas verificada no fim da transação em vez de imediatamente |
| `ON DELETE CASCADE` | apaga a Ana **e os três pedidos dela**, em silêncio |
| `ON DELETE SET NULL` | mantém os pedidos e esvazia o `customer_id` deles — só legal se a coluna aceitar `NULL` |

**`CASCADE` é o que exige cuidado**, e o cuidado não é com a cláusula, é com o que as linhas filhas
significam. Apagar um carrinho certamente deve apagar as linhas dele: uma linha de carrinho não tem
sentido sem o carrinho. Apagar um cliente quase certamente **não** deve apagar os pedidos dele,
porque um pedido é um registro financeiro que aconteceu, e ele não deixa de ter acontecido quando
alguém encerra a conta.

A regra prática que sobrevive ao contato com sistemas reais:

> `CASCADE` quando o filho não pode existir sem o pai e ninguém jamais vai perguntar por ele.
> `RESTRICT` quando o filho é o registro de algo que ocorreu.

E quando `RESTRICT` bloqueia uma exclusão que você realmente quer, normalmente é o banco apontando
que você não queria uma exclusão — você queria marcar o cliente como encerrado e manter o
histórico.

## Lendo uma referência nas duas direções

Uma única linha no `CREATE TABLE` te dá duas perguntas de graça, e é aqui que o modelo começa a
pagar:

- **Dado um pedido, quem é o cliente?** Siga o número. Exatamente uma linha, sempre, porque a chave
  estrangeira garante que existe e a primária garante que é uma só.
- **Dado um cliente, quais são os pedidos dele?** Procure toda linha de pedido que guarda aquele
  número. Zero, um, ou mil — você descobre perguntando, e não precisou decidir de antemão que essa
  pergunta importaria.

A segunda pergunta é a que a planilha não conseguia responder, e nada foi acrescentado para
torná-la possível. Ela passou a ser possível no momento em que o nome deixou de ser copiado.

Juntar as duas tabelas — escrever de fato a consulta que produz "Ana Lopes, três pedidos" — é a
aula 5. O que esta aula estabelece é *por que as tabelas têm um formato que torna a junção
possível*.
