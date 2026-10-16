---
title: Compactação e armazenamento em camadas, dois jeitos de guardar menos
version: 1
---

A retenção por tempo joga fora as mensagens mais antigas, diga o que disserem. Dois outros arranjos
guardam dados por mais tempo sem pagar por tudo ao preço do disco de um broker.

## Compactação: guardar o último valor de cada chave

**Um tópico compactado é limitado pelo número de chaves, não pelo tempo.** Com
`cleanup.policy=compact`, o cleaner do broker remove toda mensagem que uma mensagem posterior com a
mesma chave substituiu, então o tópico tende a uma mensagem por chave: o estado atual de cada uma. A
lição 3 viu isso acontecer.

Isso serve para um tópico que guarda estado em vez de histórico. O estoque por livro da Ponto Final,
publicado como uma mensagem com a chave do livro toda vez que muda, são oito chaves, não importa
quantas vendas houver: depois da limpeza, o tópico tem oito mensagens e algumas recentes que o
cleaner ainda não alcançou. As vendas em si nunca poderiam ser compactadas, porque cada venda é um
fato próprio; compactar por loja guardaria uma venda por loja e jogaria o dia fora.

A compactação tem custos próprios, e eles não estão no disco:

- **O cleaner trabalha.** Ele lê e reescreve segmentos em segundo plano, o que é tempo de processador
  e leitura de disco em cada broker, na proporção da frequência com que as chaves mudam.
- **"Último valor" só faz sentido com chave.** Uma mensagem sem chave não pode ser compactada, e um
  tópico compactado a recusa.
- **Uma chave apagada precisa de um tombstone**, uma mensagem com a chave e sem valor, e o próprio
  tombstone é guardado por `delete.retention.ms` (um dia por padrão) para que os consumidores vejam a
  remoção.

Retenção e compactação se combinam: `cleanup.policy=compact,delete` guarda o último valor por chave
e também descarta tudo o que for mais antigo que a retenção.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Em cima, um tópico de atualizações de estoque com a chave do livro, na ordem em que foram escritas: bk-01, bk-02, bk-01, bk-03, bk-02, bk-01. Embaixo, o mesmo tópico depois da compactação: só a última mensagem de cada chave fica, bk-03, bk-02 e bk-01, nos offsets originais.\" data-fig=\"l17-compact\"><defs><marker id=\"l17-compact-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">antes da limpeza</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">depois da limpeza</text><rect x=\"150\" y=\"40\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"189.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"189.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">bk-01: 12</text><rect x=\"238\" y=\"40\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"277.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"277.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">bk-02: 7</text><rect x=\"326\" y=\"40\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"365.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"365.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">bk-01: 11</text><rect x=\"414\" y=\"40\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"453.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"453.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bk-03: 4</text><rect x=\"414\" y=\"130\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"453.0\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"453.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bk-03: 4</text><line x1=\"453.0\" y1=\"84\" x2=\"453.0\" y2=\"126\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l17-compact-ah-0)\"></line><rect x=\"502\" y=\"40\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"541.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"541.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bk-02: 6</text><rect x=\"502\" y=\"130\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"541.0\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"541.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bk-02: 6</text><line x1=\"541.0\" y1=\"84\" x2=\"541.0\" y2=\"126\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l17-compact-ah-0)\"></line><rect x=\"590\" y=\"40\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"629.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"629.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bk-01: 9</text><rect x=\"590\" y=\"130\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"629.0\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"629.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bk-01: 9</text><line x1=\"629.0\" y1=\"84\" x2=\"629.0\" y2=\"126\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l17-compact-ah-0)\"></line><text x=\"277\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">substituída por um valor posterior</text></svg>", "caption": "A compactação guarda o último valor de cada chave: o tópico é limitado pelas chaves, não pelo tempo."}
```

## Armazenamento em camadas: segmentos antigos num lugar mais barato

**O armazenamento em camadas (tiered storage) move segmentos fechados do disco do broker para um
object storage**, o tipo de armazenamento que os provedores de nuvem vendem por gigabyte-mês a uma
fração do preço de um disco rápido, e mantém localmente só os segmentos recentes. Consumidores que
leem dados recentes são servidos pelo disco local como antes; um consumidor reprocessando o mês
passado é servido pelo object storage, mais devagar.

O Kafka tem isso desde a versão 3.6 e o declarou pronto para produção na 3.9:
`remote.log.storage.system.enable` nos brokers, `remote.storage.enable` no tópico, e duas
configurações de retenção em vez de uma, `local.retention.ms` para o disco do broker e
`retention.ms` para o todo. O que o Kafka não traz é a peça que conversa com um object storage
específico; isso é um plugin, do fornecedor do armazenamento ou de terceiros. **O armazenamento em
camadas não foi executado neste curso**: o laboratório não tem object storage, e instalar um plugin
para escrever num diretório local demonstraria a configuração e não a economia.

A aritmética da seção anterior é onde ele compensa. Quando a retenção é longa e os reprocessamentos
são raros, a maior parte dos bytes é antiga e quase nunca lida; movê-los para um armazenamento mais
barato corta a maior linha da conta. Quando a retenção é de uma semana e todo consumidor lê em
minutos, a economia é pequena e o plugin é mais uma coisa para operar.

| arranjo | limitado por | serve para |
|---|---|---|
| `delete` (o padrão) | tempo, ou bytes por partição | eventos, histórico, tudo o que é reprocessado dentro da retenção |
| `compact` | o número de chaves | estado atual por chave: estoque, preços, o endereço de um cliente |
| em camadas | tempo, a dois preços | retenção longa com leituras raras da parte antiga |
