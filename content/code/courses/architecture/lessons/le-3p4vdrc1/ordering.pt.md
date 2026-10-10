---
title: Ordem, a promessa mais suposta
version: 1
---

Os pedidos da Quitanda produzem três eventos em sequência: `OrderCreated`, `OrderPaid`, `OrderShipped`.
Um consumidor que guarda o status do pedido os aplica na ordem em que os recebe. **Se os recebe fora de
ordem, o status termina errado e nada relata erro**: um pedido aplicado como criado, enviado e depois pago
termina o dia como "pago", um passo atrás da realidade, e o cliente fica sabendo que o pacote não saiu.

## Onde a ordem se perde

Um broker mantém a ordem só ao longo de um caminho de um produtor até um consumidor. Cada um destes a
quebra:

| causa | o que acontece |
| --- | --- |
| consumidores concorrentes numa fila | a aula 6 mostrou o pedido 10 terminando antes do 9: cada consumidor trabalha no seu ritmo |
| uma reentrega | uma mensagem devolvida depois de uma queda volta atrás de mensagens publicadas depois dela |
| retries no produtor | uma publicação repetida pode cair depois da seguinte, a não ser que o cliente impeça |
| várias partições | o Kafka mantém a ordem dentro de uma partição e nenhuma entre elas |
| vários produtores | dois serviços publicando sobre um pedido não têm relógio comum |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Três eventos de um pedido, criado, pago e enviado, numa fila. Dois consumidores concorrentes os pegam: o consumidor 1 pega criado e enviado, o consumidor 2 pega pago mas é mais lento, então enviado é aplicado antes de pago. Embaixo, a correção: com o id do pedido como chave, os três vão para uma partição e um consumidor, em ordem.\"><defs><marker id=\"l7-order-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">uma fila, dois consumidores concorrentes</text><rect x=\"40\" y=\"48\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">criado</text><rect x=\"130\" y=\"48\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pago</text><rect x=\"220\" y=\"48\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">enviado</text><rect x=\"360\" y=\"44\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumidor 1: 1, 3</text><rect x=\"530\" y=\"44\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumidor 2: 2, lento</text><text x=\"360\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">aplicados: criado, enviado, pago</text><text x=\"26\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">chave pelo id do pedido</text><rect x=\"40\" y=\"168\" width=\"290\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partição 2: criado, pago, enviado</text><rect x=\"430\" y=\"168\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">um consumidor, em ordem</text><path d=\"M332 190 L428 190\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7-order-ah-phosphor)\"></path></svg>", "caption": "Consumidores concorrentes reordenam os eventos de um pedido. Usar o id do pedido como chave manda todos os eventos de um pedido a um consumidor, na ordem em que foram escritos."}
```

## Mantendo a ordem que importa

**Ordem quase nunca é necessária de forma global, só por entidade**: os eventos de um pedido, as
movimentações de estoque de um produto. Essa promessa mais estreita é barata de manter:

- **Chave pela entidade.** No Kafka, o id do pedido como chave da mensagem manda todos os eventos de um
  pedido para uma partição, lida por um consumidor do grupo, na ordem em que foram escritos. O
  paralelismo vem de pedidos diferentes caírem em partições diferentes. O grupo de mensagens da SQS FIFO
  e as sessões do Service Bus são a mesma ideia.
- **Um consumidor por fluxo de eventos que precisa ficar em ordem.** A opção *single active consumer*
  de uma fila no RabbitMQ deixa vários consumidores se conectarem e só um receber por vez, com os outros
  de reserva.
- **Deixar o consumidor capaz de perceber.** Cada evento carrega uma versão ou número de sequência da sua
  entidade, e o consumidor aplica um evento só se for o próximo, segurando ou descartando os mais
  velhos. Isso funciona mesmo onde o transporte não mantém a ordem, e combina naturalmente com
  idempotência: uma versão já aplicada é uma duplicata.

## E o que fazer em vez disso

Muitos consumidores nem precisam de ordem se cada evento carregar o estado completo em vez de uma
mudança. "O pedido 41 agora está enviado, com estes itens, neste horário" pode ser aplicado em qualquer
ordem se o consumidor guardar o evento com o timestamp ou a versão mais recente e ignorar os mais
velhos. **Projetar eventos para a ordem não importar costuma ser mais barato do que garanti-la**, e a
aula 9 volta à ideia como última escrita vence.
