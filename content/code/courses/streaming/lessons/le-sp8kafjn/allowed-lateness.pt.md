---
title: Atraso permitido
version: 1
---

**O atraso permitido mantém o estado de uma janela por um tempo depois que o watermark a passou, para
que um evento atrasado ainda possa atualizar um resultado já emitido.** O watermark decide quando uma
janela é informada pela primeira vez; o atraso permitido decide quando ela é esquecida. São duas
configurações porque respondem a duas perguntas: quanto esperar antes de dizer algo, e quanto tempo
continuar ouvindo depois de dizer.

Com cinco minutos de atraso permitido:

```
ubuntu@stream:~/work$ python watermark.py --lateness 5
```

Tudo é igual até a venda 8. A janela das 09:05 foi emitida na venda 6 com duas vendas, como antes.
Quando a venda 8 chega, o watermark está em 09:11:05 e o fim da janela mais cinco minutos é 09:15:00,
então a janela ainda está guardada. A venda é somada e o programa informa **uma atualização atrasada:
09:05 às 09:10 agora tem três vendas e 21.380 centavos**, o número que a lição 10 tirou da lista
completa. A venda 11 continua descartada: a janela dela terminou às 09:05, mais cinco minutos dá
09:10, e o watermark tinha passado disso muito antes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma linha do tempo do watermark, de 09:05 a 09:16. A janela de 09:05 a 09:10 fica aberta até o watermark chegar a 09:10, quando o resultado é emitido. Com cinco minutos de atraso permitido, ela é mantida até o watermark chegar a 09:15, e uma venda atrasada que chegue nesse trecho a atualiza. Depois de 09:15 a janela é esquecida e uma venda para ela está atrasada demais.\" data-fig=\"l11-lifecycle\"><defs><marker id=\"l11-lifecycle-ah-4762\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">janela 09:05 a 09:10, atraso permitido de 5 minutos</text><rect x=\"40\" y=\"92\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aberta: vendas são contadas</text><rect x=\"290\" y=\"92\" width=\"250\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">emitida, ainda mantida: uma venda atrasada a atualiza</text><rect x=\"540\" y=\"92\" width=\"130.0000000000001\" height=\"36\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"605.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">esquecida: atrasada demais</text><line x1=\"40\" y1=\"150\" x2=\"670.0000000000001\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#l11-lifecycle-ah-4762)\"></line><line x1=\"40\" y1=\"147\" x2=\"40\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"40\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:05</text><line x1=\"90\" y1=\"147\" x2=\"90\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"90\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:06</text><line x1=\"140\" y1=\"147\" x2=\"140\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"140\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:07</text><line x1=\"190\" y1=\"147\" x2=\"190\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"190\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:08</text><line x1=\"240\" y1=\"147\" x2=\"240\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"240\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:09</text><line x1=\"290\" y1=\"147\" x2=\"290\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"290\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:10</text><line x1=\"340\" y1=\"147\" x2=\"340\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"340\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:11</text><line x1=\"390\" y1=\"147\" x2=\"390\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"390\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:12</text><line x1=\"440\" y1=\"147\" x2=\"440\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"440\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:13</text><line x1=\"490\" y1=\"147\" x2=\"490\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"490\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:14</text><line x1=\"540\" y1=\"147\" x2=\"540\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"540\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:15</text><line x1=\"590\" y1=\"147\" x2=\"590\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"590\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:16</text><text x=\"670.0000000000001\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">watermark</text><line x1=\"290\" y1=\"82\" x2=\"290\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><text x=\"290\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">emitir</text><line x1=\"540\" y1=\"82\" x2=\"540\" y2=\"92\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><text x=\"540\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">esquecer</text></svg>", "caption": "O limite decide quando uma janela é emitida pela primeira vez; o atraso permitido decide quando ela é esquecida. No meio, um evento atrasado é uma atualização.", "same": ["watermark"]}
```

## O que uma atualização atrasada custa lá na frente

O processador agora emite a janela das 09:05 duas vezes, e isso é o "emitir a cada atualização" da
lição 10, entrando pela porta dos fundos. Quem lê a saída precisa saber disso:

- Um leitor que **anexa** cada resultado como uma linha nova agora tem duas linhas para 09:05, e uma
  soma da coluna conta as vendas 4 e 5 duas vezes. Um e-mail que disse "duas vendas" já foi e continua
  errado.
- Um leitor que faz **upsert** pela janela troca dois por três, e a tabela fica certa. As escritas
  idempotentes da lição 8 são o que torna seguro repetir isso.

Então o atraso permitido não sai de graça para quem lê, e a escolha é de quem cuida das duas pontas:
um painel que faz upsert aguenta horas de atraso permitido; um envio de notas fiscais que saem uma
vez só não aguenta nenhum, e precisa tratar os eventos atrasados de outro jeito.

## O que custa ao processador

Toda janela fica guardada pelo atraso permitido depois que o watermark a passa. Com janelas de cinco
minutos e cinco minutos de atraso permitido, uma janela a mais por chave fica aberta a cada momento;
com uma hora de atraso permitido, doze. Para cinco lojas isso não é nada. Para sessões por cliente, é
a diferença entre um armazenamento que cabe na memória e um que não cabe, a mesma conta de chaves
vezes janelas da lição 10.

## Os nomes

No Flink, `allowedLateness(Duration)` numa janela, separado do limite do watermark. No Kafka Streams o
**grace period** faz os dois papéis: uma janela aceita registros até o stream time passar do fim dela
mais o grace, e emite atualizações conforme elas vêm, a não ser que seja instruída a esperar. No
Spark o atraso do watermark é também o atraso permitido, e o modo de saída decide se as atualizações
são emitidas, o que a lição 12 mostra. Botões diferentes, as mesmas duas perguntas.
