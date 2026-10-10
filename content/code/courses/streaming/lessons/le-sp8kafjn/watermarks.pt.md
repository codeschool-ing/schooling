---
title: Watermarks
version: 1
---

**Um watermark é um horário W, levado junto com o stream, que quer dizer: eventos com horário
anterior a W não são mais esperados.** Quando W passa do fim de uma janela, a janela está completa até
onde o processador vai acreditar, e o resultado dela pode ser emitido.

O jeito comum de calcular um é o mais simples que poderia funcionar, e é o que o Flink chama de
desordem limitada (bounded out-of-orderness):

```python
watermark = latest_event_time_seen - bound
```

O limite é o quanto o processador aceita que os eventos estejam fora de ordem. Com um limite de dois
minutos, um processador que acabou de ver uma venda das 09:12:30 põe o watermark em 09:10:30, e isso
passa do fim da janela das 09:05 às 09:10, que é emitida. Uma venda que aconteceu antes das 09:10:30
e chega depois deste momento está **atrasada**: ela está atrás do watermark, e o processador já
disse que não a esperava.

Duas propriedades o tornam utilizável:

- **Ele só anda para a frente.** Uma venda das 09:08:50 chegando depois de uma das 09:13:05 não puxa
  o watermark para trás, porque o horário mais recente visto continua sendo 09:13:05. Se ele voltasse,
  uma janela já emitida estaria aberta de novo, e "emitida" não quereria dizer nada.
- **Ele é feito de tempos de evento.** Leia o mesmo tópico amanhã e o watermark passa das 09:10 no
  mesmo registro, então as mesmas janelas fecham com o mesmo conteúdo. Nada nele depende de quando o
  processador roda ou de quão rápido.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Um gráfico com as doze vendas em ordem de chegada na horizontal e o tempo do evento na vertical. Cada venda é um ponto; uma linha em degraus dois minutos abaixo do ponto mais alto até então é o watermark, e ela nunca desce. As duas vendas cuja janela o watermark já tinha passado quando chegaram, 09:08:50 e 09:04:30, estão marcadas como descartadas. Linhas horizontais em 09:05, 09:10, 09:15 e 09:20 são fins de janela, e cada janela é emitida na chegada em que o watermark cruza o fim dela pela primeira vez.\" data-fig=\"l11-watermark\"><line x1=\"90\" y1=\"310\" x2=\"640\" y2=\"310\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"90\" y1=\"310\" x2=\"90\" y2=\"40\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"82\" y=\"289.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:00</text><text x=\"82\" y=\"237.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:05</text><line x1=\"90\" y1=\"237.3\" x2=\"640\" y2=\"237.3\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"82\" y=\"185.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:10</text><line x1=\"90\" y1=\"185.4\" x2=\"640\" y2=\"185.4\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"82\" y=\"133.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:15</text><line x1=\"90\" y1=\"133.5\" x2=\"640\" y2=\"133.5\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"82\" y=\"81.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:20</text><line x1=\"90\" y1=\"81.5\" x2=\"640\" y2=\"81.5\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"646\" y=\"133.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fins de janela</text><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tempo do evento</text><text x=\"365.0\" y=\"346\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">vendas na ordem em que chegaram</text><text x=\"110.0\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"156.36363636363637\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"202.72727272727275\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"249.0909090909091\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"295.4545454545455\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"341.8181818181818\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"388.1818181818182\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"434.54545454545456\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8</text><text x=\"480.90909090909093\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">9</text><text x=\"527.2727272727273\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"573.6363636363636\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">11</text><text x=\"620.0\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12</text><path d=\"M 92.0 303.1 L 128.0 303.1 L 128.0 287.5 L 138.36363636363637 287.5 L 174.36363636363637 287.5 L 174.36363636363637 269.3 L 184.72727272727275 269.3 L 220.72727272727275 269.3 L 220.72727272727275 258.1 L 231.0909090909091 258.1 L 267.0909090909091 258.1 L 267.0909090909091 244.2 L 277.4545454545455 244.2 L 313.4545454545455 244.2 L 313.4545454545455 180.2 L 323.8181818181818 180.2 L 359.8181818181818 180.2 L 359.8181818181818 174.1 L 370.1818181818182 174.1 L 406.1818181818182 174.1 L 406.1818181818182 174.1 L 416.54545454545456 174.1 L 452.54545454545456 174.1 L 452.54545454545456 162.9 L 462.90909090909093 162.9 L 498.90909090909093 162.9 L 498.90909090909093 91.9 L 509.27272727272725 91.9 L 545.2727272727273 91.9 L 545.2727272727273 91.9 L 555.6363636363636 91.9 L 591.6363636363636 91.9 L 591.6363636363636 69.4 L 602.0 69.4 L 638.0 69.4\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"642.0\" y=\"69.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">watermark</text><circle cx=\"110.0\" cy=\"282.3\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"156.36363636363637\" cy=\"266.7\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"202.72727272727275\" cy=\"248.6\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"249.0909090909091\" cy=\"237.3\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"295.4545454545455\" cy=\"223.5\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"341.8181818181818\" cy=\"159.4\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"388.1818181818182\" cy=\"153.4\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"434.54545454545456\" cy=\"197.5\" r=\"4.5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"434.54545454545456\" y=\"212.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">descartada</text><circle cx=\"480.90909090909093\" cy=\"142.1\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"527.2727272727273\" cy=\"71.2\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"573.6363636363636\" cy=\"242.5\" r=\"4.5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"573.6363636363636\" y=\"257.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">descartada</text><circle cx=\"620.0\" cy=\"48.7\" r=\"4.5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle></svg>", "caption": "O watermark segue o tempo do evento mais recente dois minutos atrás e nunca volta. Uma venda abaixo dele cuja janela já terminou está atrasada.", "same": ["watermark"]}
```

## Uma heurística, e o tipo perfeito

O limite é um palpite sobre o stream, e o palpite pode errar para os dois lados. Pequeno demais, e
entregas lentas comuns chegam atrás do watermark e são tratadas como atrasadas. Grande demais, e toda
janela espera mais do que precisava, por eventos que nunca viriam. Um watermark calculado assim se
chama **heurístico**, porque é uma estimativa.

Um watermark **perfeito** só é possível onde a origem conhece a própria ordem: um único caixa
escrevendo na própria partição, na ordem das vendas, sem guardar nada, poderia dizer ao processador
exatamente até onde chegou. Sistemas reais juntam muitas origens, guardam e repetem envios, então
quase todo watermark na prática é heurístico, e o limite certo é uma medida, que é a seção sobre como
escolhê-lo.

## Quem o carrega

No Flink o watermark é um elemento especial que viaja dentro do stream, das origens por todos os
operadores, e um operador com várias entradas repassa o menor dos watermarks delas. O Spark Structured
Streaming calcula um watermark por consulta a partir do tempo de evento mais recente visto, com o
limite dado por `withWatermark("at", "2 minutes")`, que a lição 12 usa. O Kafka Streams mantém um
**stream time** por tarefa, o maior timestamp visto, e o **grace period** dele é o limite: uma janela
aceita registros até o stream time passar do fim dela mais o grace. Três vocabulários, uma ideia: **o
tempo de evento mais recente, menos um limite, andando só para a frente.**
