---
title: I/O tagarela, e a consulta N+1
version: 1
---

A página de histórico de pedidos mostra os pedidos de um cliente com os itens. O jeito fácil de escrevê-la
pede os pedidos, depois, para cada pedido, pede os itens. O outro jeito pede uma vez, com um join:

```
ana@vm:~/lab/perf$ $P history-n1 c-7
history-n1: 10 queries, 45 rows, 133 bytes, 45 ms
ana@vm:~/lab/perf$ $P history-join c-7
history-join: 1 queries, 36 rows, 226 bytes, 6 ms
```

**Dez consultas levaram 45 milissegundos; uma levou 6.** O banco quase não fez nada nos dois casos: são
consultas minúsculas em tabelas pequenas. A diferença são dez idas e voltas contra uma, a uns quatro
milissegundos e meio cada pelo proxy e pelo driver. O cliente `c-7` tem nove pedidos; um cliente com cem
esperaria meio segundo pela versão fácil, e uma tela da equipe que lista os pedidos do dia de todo mundo
poderia mandar milhares.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas linhas do tempo da mesma página de histórico de pedidos. Em cima, dez idas e voltas ao banco uma depois da outra, uma para os pedidos e uma para os itens de cada um dos nove pedidos, cada uma pagando o atraso da rede. Embaixo, uma ida e volta com um join, pagando o atraso uma vez.\"><defs><marker id=\"l16-chatty-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">N+1: 10 consultas, 45 ms</text><rect x=\"30\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"58\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">pedidos</text><rect x=\"92\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">itens 1</text><rect x=\"154\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"182\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">itens 2</text><rect x=\"216\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"244\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">itens 3</text><rect x=\"278\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"306\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">itens 4</text><rect x=\"340\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"368\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">itens 5</text><rect x=\"402\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">itens 6</text><rect x=\"464\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"492\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">itens 7</text><rect x=\"526\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"554\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">itens 8</text><rect x=\"588\" y=\"52\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"616\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">itens 9</text><text x=\"30\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">join: 1 consulta, 6 ms</text><rect x=\"30\" y=\"142\" width=\"56\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"58\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">join</text><path d=\"M30 200 L680 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l16-chatty-ah-wire)\"></path><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo; cada caixa é pelo menos uma ida e volta</text></svg>", "caption": "I/O tagarela paga a ida e volta uma vez por pergunta. A maior parte dos 45 milissegundos é espera pela rede, não trabalho no banco.", "same": ["join"]}
```

Essa forma tem nome próprio, a **consulta N+1**: uma consulta para uma lista, depois mais uma para cada um
dos N itens dela. Raramente é escrita de propósito. Um ORM a escreve quando o código anda de um objeto para
as relações dele (`for order in customer.orders: order.items`) e cada relação é carregada **sob demanda**
(*lazy loading*), no primeiro uso. O código parece um laço sobre objetos em memória, e é um laço sobre a
rede.

As correções são todas jeitos de perguntar uma vez:

- **Um join**, como acima, quando a página precisa das linhas juntas.
- **Uma consulta por nível**, com `WHERE order_id = ANY(%s)` e a lista de ids: duas consultas em vez de
  N+1, e o que o **carregamento antecipado** (*eager loading*) de um ORM faz (`select_related` e
  `prefetch_related` no Django, `includes` no Rails, `JOIN FETCH` no JPA).
- **Lotes**, para escritas: um `INSERT` com muitas linhas, ou `executemany`, como o seed do laboratório
  faz.

O mesmo antipadrão existe entre serviços, e lá custa mais. Uma página que chama o serviço de estoque uma
vez por produto da cesta paga uma ida e volta HTTP de cada vez, o que a aula 2 mediu; a correção é a
mesma, um endpoint que recebe uma lista.
