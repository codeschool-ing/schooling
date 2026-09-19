---
title: Achando o que não está lá
version: 1
---

Algumas das perguntas mais valiosas são sobre ausência:

- clientes que nunca pediram
- produtos que nunca venderam
- pedidos sem pagamento
- usuários que se cadastraram e nunca voltaram

Nenhuma delas é respondível olhando linhas que existem. São perguntas sobre **linhas que não
existem**, e há três jeitos de fazer.

## A anti-junção

```sql
SELECT c.name
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE  o.id IS NULL;
```

Leia em dois passos. O `LEFT JOIN` mantém todo cliente e preenche as colunas da direita com nulos
onde não houve parceiro. Aí o `WHERE o.id IS NULL` mantém exatamente esses — **as linhas em que a
junção não achou nada**.

Esta é a exceção deliberada da seção anterior: uma condição sobre a tabela da direita no `WHERE`, e
aqui ela é o ponto inteiro.

**A coluna que você testa tem que ser uma que não possa ser nula na tabela.** Teste `o.id` — uma
chave primária — e nulo significa "sem parceiro". Teste `o.cancelled_at`, que aceita nulo, e você
também pega pedidos que existem e nunca foram cancelados, que é uma pergunta completamente diferente
e devolve uma resposta errada plausível.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 176\" role=\"img\" aria-label=\"À esquerda, as cinco linhas que um LEFT JOIN produz: Ana três vezes, Bruno uma, e Célia uma com nulos nas duas colunas de pedido, essa última acesa. Uma seta tracejada rotulada WHERE o.id IS NULL atravessa para a direita, onde resta uma única linha acesa: Célia Reis. Uma nota diz que quatro das cinco linhas são jogadas fora, e que isso é a resposta.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">LEFT JOIN … ON o.customer_id = c.id</text><text x=\"14\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">todo cliente, com nulos onde não havia par</text><rect x=\"14\" y=\"58\" width=\"220\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"22\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1001  34.90</text><rect x=\"14\" y=\"82\" width=\"220\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"22\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1003  51.00</text><rect x=\"14\" y=\"106\" width=\"220\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"22\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1004  34.90</text><rect x=\"14\" y=\"130\" width=\"220\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"22\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bruno Sá    1002  69.80</text><rect x=\"14\" y=\"154\" width=\"220\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"22\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Célia Reis  NULL  NULL</text><text x=\"268\" y=\"100\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">WHERE o.id IS NULL</text><path d=\"M258 118 L430 118\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" fill=\"none\"></path><path d=\"M430 118 L422 114 L422 122 Z\" fill=\"var(--amber)\"></path><text x=\"268\" y=\"134\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a exceção deliberada: uma coluna da direita no WHERE</text><text x=\"444\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as linhas para as quais a junção não achou nada</text><rect x=\"444\" y=\"106\" width=\"220\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"452\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Célia Reis</text><text x=\"444\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quatro das cinco linhas são jogadas fora, e isso é a resposta.</text></svg>", "caption": "A junção faz o trabalho e o WHERE é uma peneira sobre o resultado dela. Lido nessa ordem são dois passos simples em vez de um idioma estranho."}
```

## `NOT EXISTS`

```sql
SELECT c.name
FROM   customers c
WHERE  NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);
```

A aula 7 cobre subconsultas direito; este formato vale ter agora porque normalmente é o mais claro
dos três.

Ele diz o que significa — *não existe pedido para este cliente* — sem junção sobre a qual raciocinar,
sem nulos inventados, e sem depender de escolher uma coluna não nula. `SELECT 1` é convenção: o
`EXISTS` se importa se uma linha volta, não com o que tem nela.

**Ele também para no primeiro casamento.** Para um cliente com mil pedidos, a anti-junção constrói
linhas que vai descartar; o `NOT EXISTS` acha uma e segue.

## `NOT IN`, que você não deve usar aqui

```sql
SELECT name FROM customers
WHERE  id NOT IN (SELECT customer_id FROM orders);
```

Lê melhor dos três, e **devolve nenhuma linha**, porque `orders.customer_id` aceita nulo e o pedido
1005 tem um. As aulas 1 e 4 avisaram; aqui é onde de fato morde.

`x NOT IN (1, 2, NULL)` se desdobra em `x <> 1 AND x <> 2 AND x <> NULL`, o último termo é
desconhecido, e o `AND` inteiro nunca pode ser verdadeiro. Sem erro. Resultado vazio.

Dá para resgatar — `WHERE customer_id IS NOT NULL` dentro da subconsulta — e aí é uma consulta
correta com uma armadilha em que a próxima pessoa a editar vai cair.

> **Para "não está neste conjunto", escreva `NOT EXISTS`.** Está correto havendo nulos ou não, e não
> exige que quem lê confira.

## Os três, lado a lado

| | correto com nulos | para cedo | lê como a pergunta |
|---|---|---|---|
| `LEFT JOIN … IS NULL` | sim, se você testar coluna não nula | não | mais ou menos |
| `NOT EXISTS` | sim, sempre | sim | sim |
| `NOT IN` | **não** | não | sim |

O desempenho entre os dois primeiros é próximo o bastante para não ser o fator decisivo, e a aula 10
é como você descobriria para uma consulta específica. Correção e clareza apontam as duas para o
`NOT EXISTS`, e isso basta.

## O espelho: "pelo menos um"

Os mesmos três formatos respondem a pergunta positiva, e o mesmo vence:

```sql
-- clientes que JÁ pediram
SELECT name FROM customers c WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);

-- a mesma coisa, mal feita
SELECT DISTINCT c.name FROM customers c JOIN orders o ON o.customer_id = c.id;
```

A segunda é o aviso do `DISTINCT` da aula 4 e a seção da multiplicação, chegando juntos: a junção
constrói uma linha por pedido e depois joga a maioria fora. O `EXISTS` nunca as constrói.

**Sempre que a pergunta for "existe pelo menos um", a resposta é `EXISTS`, não uma junção.** Uma
junção é para quando você quer as colunas da outra tabela; o `EXISTS` é para quando você só quer
saber.
