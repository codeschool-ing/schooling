---
title: O que acorda alguém, e o que espera a manhã
version: 1
---

As três últimas seções mostraram uns trinta números. **O erro é alertar sobre todos eles**, e ele é
cometido com boas intenções. Todo número que um dia precedeu um incidente ganha um limite. Seis meses
depois o telefone toca duas vezes por noite por coisas que se resolveram sozinhas, e quem o segura
aprendeu a dispensar o alerta. A aula 16 de `observability` chama isso de fadiga de alertas e
dá a regra que esta seção aplica: **acione alguém por um sintoma que precisa de uma pessoa agora;
ponha a causa num painel, onde a pessoa olha depois de acionada.**

## As duas perguntas

Um sinal merece acionar alguém quando a resposta às duas é sim:

1. **Alguém está sendo prejudicado agora, ou há dados prestes a se perder?** Usuários esperando,
   escritas recusadas, uma cópia dos dados que não vai existir depois da próxima falha.
2. **Há algo que uma pessoa precisa fazer, logo, que o sistema não vai fazer sozinho?**

Um cache em 97% da memória falha na primeira: é assim que um cache com limite se parece. Um
secundário 18 segundos atrás também falha, numa tarde tranquila. O mesmo secundário 18 horas atrás
passa nas duas, porque o próximo failover perde essas horas e ninguém além de uma pessoa vai
ressincronizá-lo. **A maioria dos sinais de um banco vai para um painel; os poucos que acionam alguém
são os que falam de perder dados ou recusar trabalho.**

Bancos dobram a regra de "sintomas, não causas" num ponto, e vale dizer isso em voz alta. Atraso de
replicação, um nó fora e um disco enchendo são causas; os usuários ainda não sentem nada. Acionam
alguém mesmo assim, porque o sintoma a que levam é perda de dados ou uma queda que não se desfaz
depois que chega.

## MongoDB

| acionar alguém | pôr num painel |
|---|---|
| nenhum membro é `PRIMARY`, ou menos da maioria está saudável: escritas estão sendo recusadas | `opcounters` como taxas, e `connections.current` contra `available` |
| o atraso de um secundário chegando perto da janela do oplog, as horas de histórico que o primário guarda: passado dela, o secundário precisa de ressincronização completa | atraso de replicação em segundos, para cada secundário |
| operações na fila (`qrw`, `arw`) por minutos, junto com latência p99 acima do que a aplicação prometeu | percentuais de cache usado e sujo, e com que frequência threads da aplicação estão expulsando páginas |
| o disco de algum membro enchendo num ritmo que chega a cheio em menos de um dia | consultas lentas por minuto, do log, e as dez piores por formato |

## Redis

| acionar alguém | pôr num painel |
|---|---|
| sob `noeviction`, `used_memory` em `maxmemory`: escritas falhando com `OOM` | `used_memory` contra `maxmemory`, para um cache |
| uma réplica desconectada, ou a diferença em bytes dela crescendo por minutos | `evicted_keys` como taxa, e a taxa de acerto |
| `rejected_connections` subindo: clientes estão sendo recusados | `connected_clients`, `instantaneous_ops_per_sec` |
| o servidor sem responder a `PING` | entradas do slow log por minuto, e o que o `LATENCY DOCTOR` diz |

O cache e o banco são o mesmo servidor com alertas opostos. O Redis como cache **pode** expulsar, e
a taxa de acerto é um número de desempenho. O Redis como única casa de um dado (aula 14) não deve,
e uma expulsão ali é um dado apagado pelo servidor de propósito.

## Cassandra

| acionar alguém | pôr num painel |
|---|---|
| um nó `DN` por mais que `max_hint_window`, 3 horas por padrão: passado disso, os outros nós param de guardar hints e só o repair devolve as escritas que ele perdeu | carga por nó do `nodetool status`, para equilíbrio |
| `MUTATION_REQ` ou `READ_REQ` descartados num ritmo constante | pending por estágio do `tpstats` |
| latência p99 de leitura ou escrita no coordenador acima do limite combinado por vários minutos | os histogramas completos de latência |
| leituras recusadas no `tombstone_failure_threshold` | tombstones por slice e a maior partição, por tabela |
| compactações pendentes crescendo por horas, ou disco acima do espaço livre de que a compactação precisa | SSTables por leitura |

## Tirando os números de lá: exporters

Ninguém aciona plantão a partir de um `nodetool` digitado à mão. Um sistema de monitoramento coleta
os mesmos números numa agenda, guarda o histórico e avalia as regras. Com o Prometheus, que a aula 5
de `observability` ensina, o caminho comum é um **exporter** por produto: um processo pequeno que
pede as estatísticas ao banco e as publica no formato de texto do Prometheus.

| produto | o exporter mais usado | o que ele lê |
|---|---|---|
| MongoDB | `mongodb_exporter`, mantido pela Percona | `serverStatus`, `replSetGetStatus` e companhia: os documentos desta aula |
| Redis | `redis_exporter` | as seções do `INFO`, linha a linha |
| Cassandra | o JMX exporter do Prometheus, rodando como agente Java dentro do nó | as métricas JMX que o próprio `nodetool` lê |

**Nenhum dos três foi instalado para este curso**, e nenhum é necessário para ele: tudo o que
publicam é o que os comandos desta aula imprimiram, com outro nome. Nomes e padrões mudam entre
versões, então leia o que você instalar contra o campo de onde ele diz vir, do jeito que a coluna do
`mongostat` foi lida contra o `rs.status()`.

As regras de alerta em si pertencem a quem opera o serviço. O jeito útil de escrevê-las é o da
aula 15 de `observability`: um SLO para as operações que importam à loja, a latência e os erros que
os usuários veem, e um acionamento quando o orçamento de erro está queimando. As tabelas acima são a
metade do banco disso, a parte que diz que há dados em risco antes que algum usuário perceba.
