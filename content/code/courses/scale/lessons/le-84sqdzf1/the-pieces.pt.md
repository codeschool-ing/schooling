---
title: As peças e onde elas rodam
version: 1
---

Quatro tipos de coisa participam, e cada um roda no seu lugar:

1. **O SDK, dentro de cada serviço.** A bilheteria e o payments criam spans enquanto trabalham, e
   entregam os prontos a um processador de spans, que os junta em lotes.
2. **O exportador, também dentro de cada serviço**, que manda cada lote por OTLP a um endereço, em
   segundo plano. Um pedido nunca espera seus spans serem enviados.
3. **O Collector, um contêiner à parte**, que recebe OTLP de todo serviço, pode descartar, amostrar,
   enriquecer e juntar em lotes, e encaminha a um ou mais back ends.
4. **O back end**, aqui o **Jaeger**, que guarda os rastros e responde consultas sobre eles, numa
   página web e por uma API.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois serviços à esquerda, a bilheteria e o payments, cada um com o SDK do OpenTelemetry dentro, um processador de lotes e um exportador OTLP. Os dois mandam os spans por OTLP a um único Collector no meio, que os junta em lotes e os encaminha ao Jaeger à direita, onde os rastros são guardados e consultados.\"><rect x=\"20\" y=\"30\" width=\"220\" height=\"80\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">tickets</text><rect x=\"36\" y=\"62\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"81\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">spans do SDK</text><rect x=\"136\" y=\"62\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"181\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lote + OTLP</text><path d=\"M126 79 L134 79\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M134 79 L127.7 82.0 L127.7 76.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M240 70 L318 125\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M318 125 L311.1 123.9 L314.6 118.9 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><rect x=\"20\" y=\"140\" width=\"220\" height=\"80\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">payments</text><rect x=\"36\" y=\"172\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"81\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">spans do SDK</text><rect x=\"136\" y=\"172\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"181\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lote + OTLP</text><path d=\"M126 189 L134 189\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M134 189 L127.7 192.0 L127.7 186.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M240 180 L318 125\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M318 125 L314.6 131.1 L311.1 126.1 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"279\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">OTLP</text><rect x=\"320\" y=\"95\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"395\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">collector</text><text x=\"395\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">recebe · junta · manda</text><path d=\"M470 125 L548 125\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M548 125 L541.7 128.0 L541.7 122.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><rect x=\"550\" y=\"95\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"625\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">jaeger</text><text x=\"625\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">guarda · consulta</text><text x=\"625\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:16686</text></svg>", "caption": "Os spans saem de cada serviço em lotes, se encontram no Collector e são guardados no Jaeger."}
```

Todo serviço poderia mandar direto ao Jaeger, e num laboratório funcionaria. O Collector está ali
pelo mesmo motivo que um balanceador de carga: ele é **o único lugar que muda quando o back end
muda**. É também onde a amostragem entre serviços, a remoção de atributos sensíveis e as novas
tentativas são configuradas uma vez, em vez de em cada programa. Em produção ele costuma rodar duas
vezes: um Collector pequeno ao lado de cada serviço, ou em cada máquina, e um conjunto de Collectors
atrás deles.

## Um span, com precisão

Um **rastro** (*trace*) é o caminho inteiro de um pedido. Ele é feito de **spans**, cada um uma
unidade de trabalho com:

- um **id de rastro**, compartilhado por todos os spans do rastro, e um **id de span** próprio;
- o **id do span pai**, vazio na raiz, que é o que transforma os spans numa árvore;
- um **nome**, um **tipo** (`SERVER` para trabalho feito respondendo a um pedido, `CLIENT` para uma
  chamada a outro serviço, `INTERNAL` para o resto), um começo e um fim;
- **atributos**: pares de chave e valor que o descrevem, como a rota e o status;
- **eventos** com hora, como uma exceção registrada, e um **status**.

As métricas da aula 7 diziam que as vendas levavam 120 ms no percentil 95. Um rastro de uma venda diz
como esses milissegundos foram gastos, e em qual serviço.
