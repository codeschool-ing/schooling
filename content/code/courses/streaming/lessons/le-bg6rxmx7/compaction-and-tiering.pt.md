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

@@fig:l17-compact@@

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
