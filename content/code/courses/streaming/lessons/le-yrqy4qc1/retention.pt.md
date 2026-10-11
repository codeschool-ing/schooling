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

@@fence@@

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

@@fence@@

Vinte mil vendas encheram três segmentos. Os nomes são os offsets base: o primeiro segmento guarda os
offsets 0 a 7080, o segundo começa no 7081 e o terceiro, o ativo, no 14354.

Agora limite o tópico a um mebibyte por partição:

@@fence@@

Nada acontece na hora. **O broker verifica a retenção a cada cinco minutos**
(`log.retention.check.interval.ms`, uma configuração do broker), então uma mudança vale na próxima
verificação. Espere até cinco minutos, e então:

@@fence@@

O offset mais antigo agora é 7081. **O primeiro segmento foi apagado inteiro**, e com ele as 7 081
vendas que tinha; o log start offset do tópico passou para o offset base do segundo segmento. A regra
do `retention.bytes` é: enquanto a partição menos o seu segmento mais antigo ainda passar do limite,
apague o segmento mais antigo. Dois segmentos cheios de um mebibyte e um ativo pela metade, menos o
mais antigo, ainda passam de um mebibyte, então o primeiro saiu; tirando também o segundo, só sobraria
o segmento ativo, abaixo do limite, então o segundo ficou. O segmento ativo nunca é candidato.

A listagem mostra um detalhe: o arquivo do segmento apagado ainda está lá, com `.deleted` acrescentado
ao nome. Um minuto depois (`file.delete.delay.ms`) ele some, e o tópico começa no 7081:

@@fence@@

A primeira mensagem desde o começo agora é o offset 7081, a venda `rec-007082` do Recife. **Um
consumidor que não tinha lido as primeiras 7 081 vendas as perdeu**, e nada o avisou: esse é o custo
da retenção, e é por isso que a lição 16 acompanha quão atrasados estão os consumidores.

@@fig:l3-segments@@

A retenção por tempo funciona do mesmo jeito, um segmento de cada vez: um segmento fechado sai quando
a mensagem mais nova dele fica mais velha que `retention.ms`. Duas consequências vêm de o segmento ser
a unidade. Uma mensagem pode sobreviver à sua retenção por até a vida de um segmento, porque espera o
segmento inteiro expirar; com os padrões, isso é até uma semana a mais. E um tópico com um
`retention.ms` pequeno mas o `segment.bytes` padrão de um gibibyte guarda tudo até esse gibibyte
encher, a menos que o `segment.ms` feche segmentos antes.
