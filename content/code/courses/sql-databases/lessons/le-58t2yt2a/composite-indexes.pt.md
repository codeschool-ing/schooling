---
title: Mais de uma coluna, e por que a ordem decide tudo
version: 1
---

```sql
CREATE INDEX ON orders (customer_id, placed_at);
```

Um índice sobre duas colunas. **Não** é a mesma coisa que dois índices, e a ordem em que você
escreveu as colunas decide quais consultas ele consegue atender.

A cópia ordenada é ordenada por `customer_id` primeiro, e por `placed_at` só **dentro** de cada
cliente. Então toda linha do cliente 2 fica junta, e as datas estão em ordem dentro dessa sequência
— e no índice como um todo as datas estão espalhadas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 344\" role=\"img\" aria-label=\"À esquerda, seis linhas de pedidos como a tabela as guarda, sem ordem nenhuma, cada uma mostrando um número de cliente e uma data. À direita, as mesmas seis como entradas num índice sobre customer_id e placed_at: elas estão ordenadas por cliente primeiro, então as duas linhas do cliente um ficam juntas, depois as duas do cliente dois, depois as duas do cliente três, e dentro de cada par as datas estão em ordem. Notas ao lado da lista da direita marcam as entradas de cada cliente como ficando juntas. Abaixo, uma faixa lista quais buscas este único índice atende: uma condição só sobre customer_id encontra uma sequência contígua de entradas; customer_id junto de uma faixa de datas encontra uma sequência menor dentro daquela; mas uma condição só sobre a data casa entradas espalhadas pelo índice inteiro, então ela não pode ser usada e a consulta vira uma varredura.\"><text x=\"14\" y=\"22\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">orders, como guardada</text>\n<rect x=\"14\" y=\"30\" width=\"210\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"24\" y=\"43\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=2   2026-03-04</text>\n<rect x=\"14\" y=\"56\" width=\"210\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"24\" y=\"69\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=1   2026-01-09</text>\n<rect x=\"14\" y=\"82\" width=\"210\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"24\" y=\"95\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=3   2026-02-11</text>\n<rect x=\"14\" y=\"108\" width=\"210\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"24\" y=\"121\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=1   2026-05-02</text>\n<rect x=\"14\" y=\"134\" width=\"210\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"24\" y=\"147\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=2   2026-01-22</text>\n<rect x=\"14\" y=\"160\" width=\"210\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"24\" y=\"173\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=3   2026-04-30</text>\n<text x=\"14\" y=\"208\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sem ordem nenhuma</text>\n<text x=\"300\" y=\"22\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">index (customer_id, placed_at)</text>\n<rect x=\"300\" y=\"30\" width=\"250\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"310\" y=\"43\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c=1   2026-01-09</text>\n<rect x=\"300\" y=\"56\" width=\"250\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"310\" y=\"69\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c=1   2026-05-02</text>\n<rect x=\"300\" y=\"82\" width=\"250\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"310\" y=\"95\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c=2   2026-01-22</text>\n<rect x=\"300\" y=\"108\" width=\"250\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"310\" y=\"121\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c=2   2026-03-04</text>\n<rect x=\"300\" y=\"134\" width=\"250\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"310\" y=\"147\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c=3   2026-02-11</text>\n<rect x=\"300\" y=\"160\" width=\"250\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"310\" y=\"173\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c=3   2026-04-30</text>\n<text x=\"300\" y=\"208\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">cliente primeiro, depois a data</text>\n<text x=\"566\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=1 juntos</text>\n<text x=\"566\" y=\"108\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">c=2 juntos</text>\n<text x=\"566\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">c=3 juntos</text>\n<line x1=\"14\" y1=\"232\" x2=\"706\" y2=\"232\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n<text x=\"14\" y=\"256\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Quais buscas este índice atende</text>\n<text x=\"14\" y=\"278\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">customer_id = 2</text><text x=\"230\" y=\"278\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma sequência contígua de entradas</text>\n<text x=\"14\" y=\"300\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">customer_id = 2 AND placed_at &gt;</text><text x=\"230\" y=\"300\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma sequência menor dentro dela</text>\n<text x=\"14\" y=\"322\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">placed_at &gt; sozinho</text><text x=\"230\" y=\"322\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">espalhado pelo índice, então é varredura</text>\n</svg>", "caption": "Um índice sobre duas colunas é ordenado pela primeira e só então pela segunda. A primeira coluna, ou a primeira e a segunda, encontram uma sequência contígua. A segunda sozinha não encontra nada contíguo."}
```

## A regra do prefixo à esquerda

> **Um índice em `(a, b, c)` serve a uma consulta que filtra por `a`, por `a` e `b`, ou por `a` e
> `b` e `c`. Ele não faz nada por uma consulta que filtra só por `b`, ou só por `c`.**

É a regra inteira, e todo outro conselho desta seção decorre dela. Um índice em
`(customer_id, placed_at)` cobre três destes e não o quarto:

```sql
WHERE customer_id = 2                              -- sim
WHERE customer_id = 2 AND placed_at > DATE '…'     -- sim, e é para isso que ele existe
WHERE customer_id = 2 ORDER BY placed_at           -- sim, e sem precisar ordenar
WHERE placed_at > DATE '…'                         -- não
```

Duas consequências sobre as quais vale agir:

**Não acrescente um índice em `(a)` quando você tem um em `(a, b)`.** O mais largo já serve a toda
consulta que o estreito serviria. É um dos dois duplicados da seção anterior.

**Acrescente um em `(b)` se você consulta `b` sozinho.** O composto não ajuda ali, e nenhuma
reordenação faz um índice servir ao mesmo tempo a `a` sozinho e a `b` sozinho.

## Qual coluna vem primeiro

A regra que acerta quase sempre:

> **Igualdade primeiro, depois a faixa.**

```sql
WHERE status = 'paid' AND placed_at > DATE '2026-01-01'
```

Com `(status, placed_at)` o índice salta para o bloco dos pedidos pagos e lê para a frente pelas
datas em ordem — uma sequência contígua, e ele para quando as datas acabam.

Com `(placed_at, status)` ele salta para a primeira data e depois precisa percorrer **toda linha
desde janeiro**, conferindo o status de cada uma, porque dentro de uma faixa de datas os status não
estão em ordem nenhuma. As linhas devolvidas são as mesmas; o trabalho não.

O enunciado geral: **assim que o índice bate numa faixa, as colunas depois dela só podem ser
conferidas, não buscadas.** Então ponha toda coluna comparada com `=` antes da comparada com `<`,
`>` ou `BETWEEN`, e ponha no máximo uma coluna de faixa.

## Ordenar vem de graça, e o `LIMIT` faz isso importar

Um índice é uma estrutura ordenada, então ele consegue fornecer um `ORDER BY` sem ordenar nada:

```sql
SELECT * FROM orders WHERE customer_id = 2 ORDER BY placed_at DESC LIMIT 10;
```

Com `(customer_id, placed_at)` o banco caminha até o cliente 2, lê as dez últimas entradas de trás
para a frente, e para. Sem ele, acha todo pedido daquele cliente, ordena tudo, e joga fora todos
menos dez.

Essa diferença é pequena em dez linhas e enorme em dez mil, e é o mecanismo por trás do que a aula
4 disse sobre paginação: **o `LIMIT` só é barato quando a ordem que ele pede é uma ordem que o
índice já tem.**

Ler um índice de trás para a frente é de graça, então `(a, b)` serve a `ORDER BY a, b` e a
`ORDER BY a DESC, b DESC` igualmente. Ele **não** serve a `ORDER BY a, b DESC` — direções mistas
precisam que o índice seja declarado assim:

```sql
CREATE INDEX ON orders (customer_id, placed_at DESC);
```

## Quantas colunas

Cada coluna deixa o índice maior, o que significa menos entradas por bloco e mais blocos a ler.
Duas ou três é onde quase todo o valor está. Um índice de seis colunas costuma ser alguém
acrescentando uma coluna por chamado, e ele serve às mesmas consultas que um de duas serviria
custando mais em toda escrita.

E se você se pegar querendo `(a, b)` e `(b, a)` os dois, são dois índices e às vezes é a resposta
certa — mas confira antes se a segunda consulta é uma que alguém roda, porque este é exatamente o
formato que a seção anterior chamou de imposto permanente sobre as escritas.
