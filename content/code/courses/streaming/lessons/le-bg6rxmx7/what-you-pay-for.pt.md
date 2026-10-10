---
title: Pelo que um stream é cobrado
version: 1
---

**O custo de um batch acompanha o trabalho; o custo de um stream acompanha o relógio.** Um job
noturno que roda por vinte minutos paga vinte minutos de máquina, e um dia calmo custa menos que um
dia cheio. Um stream paga pelos brokers e pelos consumidores todas as horas de todos os dias, porque
eles precisam estar lá quando a próxima venda chegar, e ninguém sabe quando vai ser. Quase tudo o
que surpreende numa conta de streaming vem de esquecer essa diferença.

A conta tem três partes, e cada uma cresce com uma coisa diferente.

## Computação: sempre ligada

Os brokers, os consumidores, os motores de processamento das lições 12 e 13, e o que quer que os
vigie. Cada um é um processo com memória reservada e uma máquina embaixo, chegue a próxima venda no
próximo segundo ou nas próximas oito horas. **A computação é dimensionada pelo pico e paga no vale.**
Um grupo de consumidores dimensionado para que a manhã de sábado esvazie em minutos fica quase
parado na terça à noite, e custa o mesmo.

## Armazenamento: vazão vezes retenção vezes cópias

Um broker guarda toda mensagem até a retenção removê-la, e guarda em cada réplica. Então o disco
que um tópico precisa é a multiplicação de quatro números:

| fator | o que o define | para as vendas da Ponto Final, mais adiante nesta lição |
|---|---|---|
| mensagens por dia | o negócio | vendas registradas nas cinco lojas |
| bytes por mensagem, em disco | a mensagem e a compressão dela | medido, não chutado |
| dias guardados | `retention.ms` | até onde um reprocessamento precisa voltar |
| cópias | o fator de replicação | três, como na lição 5 |

**Nenhum dos quatro é pequeno por acaso, e cada um é uma decisão.** A retenção é a que as pessoas
definem uma vez e esquecem. Uma semana basta para a maioria dos reprocessamentos; um ano de vendas
guardado no Kafka porque ninguém mudou o padrão é uma conta de disco por um arquivo que ninguém lê,
e o lugar dele é um object storage ou o warehouse.

@@fig:l17-formula@@

## Rede: entrada, saída e no meio

Todo byte escrito chega uma vez de um produtor, viaja até cada réplica seguidora e sai uma vez para
cada grupo de consumidores que o lê. Um tópico escrito a um megabyte por segundo, com três réplicas
e quatro grupos lendo, movimenta um megabyte de entrada, dois entre brokers e quatro de saída:
**sete vezes o que foi escrito**.

Dentro de um data center esse tráfego costuma não ser cobrado. **Entre zonas de disponibilidade
costuma ser**, nos dois sentidos, e um cluster espalhado por três zonas por segurança, como a lição 5
defende, manda duas de cada três cópias de réplica através de uma fronteira de zona. Consumidores que
leem de um líder em outra zona somam a isso. O Kafka permite que um consumidor leia de uma seguidora
na própria zona (`client.rack` no consumidor, um `replica.selector.class` nos brokers), e essa
configuração existe só por causa dessa conta.

## O que ela não inclui

As pessoas. Um stream é operado o tempo todo, como a lição 16 mostrou: lag para vigiar, cartas
mortas para ler, partições para rebalancear, atualizações que não podem parar tudo. Uma equipe que
dá conta disso é um custo que raramente aparece na comparação com um job noturno, e muitas vezes é o
maior deles.
