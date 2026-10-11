---
title: Retenção, um segmento de cada vez
version: 1
---

**O Kafka apaga mensagens antigas apagando segmentos inteiros, os mais antigos primeiro, e nunca
toca no ativo.** Um tópico recebe por quanto tempo guardar os dados, ou quanto deles, e de tempos em
tempos o broker procura segmentos fechados que já passaram inteiros desse limite e os remove. Não
existe apagar uma mensagem, nem apagar uma mensagem porque ela foi lida: ler nunca removeu nada, e a
retenção não liga para quem leu o quê.

Estas são as configurações que decidem isso, como `sales` as tem:

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --describe --all --topic sales | grep -E "retention.(ms|bytes)|segment.(ms|bytes)|cleanup"
  cleanup.policy=delete sensitive=false synonyms={DEFAULT_CONFIG:log.cleanup.policy=delete}
  delete.retention.ms=86400000 sensitive=false synonyms={DEFAULT_CONFIG:log.cleaner.delete.retention.ms=86400000}
  local.retention.bytes=-2 sensitive=false synonyms={DEFAULT_CONFIG:log.local.retention.bytes=-2}
  local.retention.ms=-2 sensitive=false synonyms={DEFAULT_CONFIG:log.local.retention.ms=-2}
  retention.bytes=-1 sensitive=false synonyms={DEFAULT_CONFIG:log.retention.bytes=-1}
  retention.ms=604800000 sensitive=false synonyms={}
  segment.bytes=1073741824 sensitive=false synonyms={DEFAULT_CONFIG:log.segment.bytes=1073741824}
  segment.ms=604800000 sensitive=false synonyms={}
```

| configuração | padrão aqui | o que ela decide |
|---|---|---|
| `cleanup.policy` | `delete` | apagar segmentos antigos; `compact` é a próxima seção |
| `retention.ms` | 604800000, sete dias | um segmento fechado cuja mensagem mais nova é mais velha que isso sai |
| `retention.bytes` | −1, sem limite | por partição: os segmentos mais antigos saem enquanto o resto ainda passa disso |
| `segment.bytes` | 1073741824, um gibibyte | quando o segmento ativo é fechado por tamanho |
| `segment.ms` | 604800000, sete dias | quando ele é fechado por idade, mesmo pequeno |

Os `synonyms` ao lado de cada valor dizem de onde ele veio: um valor configurado no tópico, ou o
padrão do broker. **A retenção é uma propriedade do tópico**, então `sales` pode guardar uma semana
enquanto um tópico de auditoria guarda um ano.

## Vendo um segmento sair

Um segmento de um gibibyte levaria muito tempo para encher de vendas, então crie um tópico cujos
segmentos fecham em um mebibyte, o mínimo que o Kafka permite, e encha-o com vinte mil vendas:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic old-sales --partitions 1 --config segment.bytes=1048576
Created topic old-sales.
ubuntu@stream:~/work$ python tills.py --topic old-sales --count 20000 --rate 0
sent 20000 sales to old-sales, the last one at 19:30:14
ubuntu@stream:~/work$ ls ~/kafka-data/node1/log/old-sales-0/*.log
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000000000.log
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000007081.log
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000014354.log
```

Vinte mil vendas encheram três segmentos. Os nomes são os offsets base: o primeiro segmento guarda os
offsets 0 a 7080, o segundo começa no 7081 e o terceiro, o ativo, no 14354.

Agora limite o tópico a um mebibyte por partição:

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --alter --topic old-sales --add-config retention.bytes=1048576
Completed updating config for topic old-sales.
```

Nada acontece na hora. **O broker verifica a retenção a cada cinco minutos**
(`log.retention.check.interval.ms`, uma configuração do broker), então uma mudança vale na próxima
verificação. Espere até cinco minutos, e então:

```
ubuntu@stream:~/work$ kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic old-sales --time earliest
old-sales:0:7081
ubuntu@stream:~/work$ ls ~/kafka-data/node1/log/old-sales-0/*.log*
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000000000.log.deleted
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000007081.log
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000014354.log
```

O offset mais antigo agora é 7081. **O primeiro segmento foi apagado inteiro**, e com ele as 7 081
vendas que tinha; o log start offset do tópico passou para o offset base do segundo segmento. A regra
do `retention.bytes` é: enquanto a partição menos o seu segmento mais antigo ainda passar do limite,
apague o segmento mais antigo. Dois segmentos cheios de um mebibyte e um ativo pela metade, menos o
mais antigo, ainda passam de um mebibyte, então o primeiro saiu; tirando também o segundo, só sobraria
o segmento ativo, abaixo do limite, então o segundo ficou. O segmento ativo nunca é candidato.

A listagem mostra um detalhe: o arquivo do segmento apagado ainda está lá, com `.deleted` acrescentado
ao nome. Um minuto depois (`file.delete.delay.ms`) ele some, e o tópico começa no 7081:

```
ubuntu@stream:~/work$ ls ~/kafka-data/node1/log/old-sales-0/*.log*
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000007081.log
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000014354.log
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic old-sales --from-beginning --max-messages 1 --formatter-property print.offset=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
Offset:7081	{"sale": "rec-007082", "shop": "recife", "book": "bk-08", "qty": 2, "cents": 17980, "at": "2026-03-03T05:40:00-03:00"}
Processed a total of 1 messages
```

A primeira mensagem desde o começo agora é o offset 7081, a venda `rec-007082` do Recife. **Um
consumidor que não tinha lido as primeiras 7 081 vendas as perdeu**, e nada o avisou: esse é o custo
da retenção, e é por isso que a lição 16 acompanha quão atrasados estão os consumidores.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 185\" role=\"img\" aria-label=\"A partição old-sales-0 como três segmentos em fila: o primeiro, fechado em um mebibyte, guarda os offsets 0 a 7080, o segundo, também fechado em um mebibyte, 7081 a 14353, e o segmento ativo a partir de 14354, ainda sendo escrito. Com retention.bytes em um mebibyte, o primeiro segmento é apagado inteiro, e o log start offset vai de 0 para 7081. O segmento ativo nunca é apagado.\" data-fig=\"l3-segments\"><defs><marker id=\"l3-segments-ah-726\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"30\" y=\"70\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"130\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00000000000000000000.log</text><text x=\"130\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">offsets 0 a 7080</text><text x=\"130\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fechado em 1 MiB</text><rect x=\"260\" y=\"70\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00000000000000007081.log</text><text x=\"360\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">offsets 7081 a 14353</text><text x=\"360\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fechado em 1 MiB</text><rect x=\"490\" y=\"70\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00000000000000014354.log</text><text x=\"590\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a partir de 14354</text><text x=\"590\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ainda crescendo</text><text x=\"130\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">apagado inteiro</text><text x=\"590\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">ativo, sendo escrito</text><line x1=\"262\" y1=\"40\" x2=\"262\" y2=\"66\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l3-segments-ah-726)\"></line><text x=\"262\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">log start offset: 0 antes, 7081 depois</text></svg>", "caption": "A retenção remove inteiro o segmento fechado mais antigo; o offset mais antigo salta para o offset base do segmento seguinte."}
```

A retenção por tempo funciona do mesmo jeito, um segmento de cada vez: um segmento fechado sai quando
a mensagem mais nova dele fica mais velha que `retention.ms`. Duas consequências vêm de o segmento ser
a unidade. Uma mensagem pode sobreviver à sua retenção por até a vida de um segmento, porque espera o
segmento inteiro expirar; com os padrões, isso é até uma semana a mais. E um tópico com um
`retention.ms` pequeno mas o `segment.bytes` padrão de um gibibyte guarda tudo até esse gibibyte
encher, a menos que o `segment.ms` feche segmentos antes.
