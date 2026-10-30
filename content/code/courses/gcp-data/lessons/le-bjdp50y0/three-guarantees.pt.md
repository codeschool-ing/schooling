---
title: No máximo uma vez, pelo menos uma vez, exatamente uma vez
version: 1
---

**Uma garantia de entrega responde a uma pergunta: quando um consumidor morre, o que acontece com a
mensagem em que ele estava trabalhando?** Todo consumidor do Pub/Sub faz duas coisas com uma
mensagem. Faz o trabalho, como somar um pagamento ao total de um cliente, e confirma a mensagem, o que
diz ao Pub/Sub para não entregá-la de novo. Uma queda pode cair entre as duas, e a ordem das duas
decide a resposta.

**Primeiro o ack, depois o trabalho, é no máximo uma vez** (*at most once*). Se o processo morre
depois do ack e antes do trabalho, o Pub/Sub já esqueceu a mensagem e o trabalho nunca acontece: a
mensagem se perde, em silêncio, e nada é feito duas vezes. **Primeiro o trabalho, depois o ack, é pelo
menos uma vez** (*at least once*). Se o processo morre depois do trabalho e antes do ack, o prazo de
ack acaba, a mensagem é entregue de novo e o trabalho é feito uma segunda vez: nada se perde, e
algumas coisas são feitas duas vezes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Duas ordens dos mesmos dois passos, com uma queda entre eles. Linha de cima, no máximo uma vez: o consumidor dá ack na mensagem, cai, e o trabalho nunca é alcançado; o Pub/Sub não entrega a mensagem de novo, então ela se perde. Linha de baixo, pelo menos uma vez: o consumidor faz o trabalho, cai antes do ack, e a mensagem é entregue de novo depois do prazo, então o trabalho é feito duas vezes.\" data-fig=\"l20-orders\"><text x=\"20.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">no máximo uma vez</text><rect x=\"150.0\" y=\"30.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ack</text><line x1=\"262.0\" y1=\"50.0\" x2=\"290.0\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"296.0,50.0 290.0,53.0 290.0,47.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"298.0\" y=\"30.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"328.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">queda</text><line x1=\"360.0\" y1=\"50.0\" x2=\"388.0\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"394.0,50.0 388.0,53.0 388.0,47.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"396.0\" y=\"30.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"456.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">trabalho</text><text x=\"456.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nunca alcançado</text><line x1=\"518.0\" y1=\"50.0\" x2=\"546.0\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"552.0,50.0 546.0,53.0 546.0,47.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"554.0\" y=\"30.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"629.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">reinício: não volta</text><text x=\"629.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">perdida</text><text x=\"20.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pelo menos uma vez</text><rect x=\"150.0\" y=\"130.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">trabalho</text><line x1=\"262.0\" y1=\"150.0\" x2=\"290.0\" y2=\"150.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"296.0,150.0 290.0,153.0 290.0,147.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"298.0\" y=\"130.0\" width=\"60.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"328.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">queda</text><line x1=\"360.0\" y1=\"150.0\" x2=\"388.0\" y2=\"150.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"394.0,150.0 388.0,153.0 388.0,147.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"396.0\" y=\"130.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"456.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ack</text><text x=\"456.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nunca alcançado</text><line x1=\"518.0\" y1=\"150.0\" x2=\"546.0\" y2=\"150.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"552.0,150.0 546.0,153.0 546.0,147.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"554.0\" y=\"130.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"629.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">reinício: entregue de novo</text><text x=\"629.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">feito duas vezes</text></svg>", "caption": "A ordem do trabalho e do ack decide o que uma queda entre eles faz.", "same": ["ack"]}
```

**Exatamente uma vez não é uma terceira ordem.** Nenhum arranjo dos dois passos sobrevive a uma queda
entre eles, porque o trabalho cai num sistema, um banco de dados, um bucket ou um banco de verdade, e
o ack em outro, o Pub/Sub, e nenhuma escrita única cobre os dois. Exatamente uma vez (*exactly once*)
é uma propriedade do pipeline inteiro, construída de um de dois jeitos. Ou o trabalho e o registro de
tê-lo feito viram uma escrita atômica só, no mesmo sistema, ou o trabalho fica **idempotente**, de
modo que fazê-lo duas vezes deixa o mesmo resultado que fazê-lo uma. Aí a entrega pelo menos uma vez
produz efeitos exatamente uma vez, e é isso que esta aula constrói.

## O ack é por mensagem, e não há posição

**O Pub/Sub não guarda offset para um consumidor anotar.** Um log como uma partição do Kafka guarda as
mensagens numa fila, e um consumidor registra até onde já chegou nela: um número, gravado de tempos em
tempos, e tudo depois dele é lido de novo depois de uma queda. Uma assinatura não tem fila. Cada
mensagem é confirmada sozinha, em qualquer ordem, e o Pub/Sub acompanha quais ainda estão fora. Isso
faz da unidade de um duplicado uma mensagem, e não um trecho do log: o que volta depois de uma queda são
exatamente as mensagens puxadas e não confirmadas, e nada que foi confirmado antes delas. Também
significa que não há posição para voltar à mão. Ler de novo é um `seek`, para um horário ou para um
snapshot, a ferramenta da aula 19, e a terceira seção desta aula a usa.

## O que o Pub/Sub promete

| entrega | promete | então o consumidor precisa |
|---|---|---|
| pull, unário ou streaming | pelo menos uma vez: uma mensagem sem ack a tempo é entregue de novo | tolerar duplicados |
| push | pelo menos uma vez: qualquer resposta que não seja 2xx, ou nenhuma a tempo, é um nack | fazer o endpoint idempotente |
| assinatura ordenada | pelo menos uma vez, e uma nova entrega traz de volta também as mensagens seguintes da chave | tolerar duplicados, em ordem |
| pull com entrega exatamente uma vez | nenhuma nova entrega depois de um ack bem-sucedido, nem enquanto o prazo vale | ainda tolerar os duplicados do publicador |

A última linha é o assunto da última seção desta aula, e a última coluna dela é o motivo de a
história não acabar ali. **Pelo menos uma vez é o padrão porque é o que não perde nada.** Duplicados
podem ser tirados depois; uma mensagem confirmada antes de o trabalho ser feito se foi para sempre. No
máximo uma vez só serve para dado que pode se perder, como uma métrica que a próxima amostra substitui.
Tudo o que a Quitanda conta, pagamentos primeiro, é consumido pelo menos uma vez. Então todo
consumidor disso precisa responder à pergunta da próxima seção: de onde vêm os duplicados, e como
separar um deles de um segundo evento real que por acaso parece igual?
