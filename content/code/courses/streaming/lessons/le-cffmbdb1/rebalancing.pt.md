---
title: Rebalanceamento, de três jeitos
version: 1
---

**Um rebalanceamento é o grupo distribuindo de novo as suas partições, e ele acontece toda vez que um
membro entra ou sai.** Iniciar uma cópia, parar uma, uma cópia cair, uma cópia lenta demais para chamar
`poll`: cada coisa dessas muda os membros, e as partições são redistribuídas. Enquanto uma partição
está sendo movida, nenhum membro a lê. Quanto isso dura, e quantas partições param enquanto acontece,
depende do protocolo.

Para ver só as atribuições, sem vendas passando na tela, use um tópico vazio:

@@fence@@

Em cada um dos três experimentos abaixo, inicie o `a`, depois o `b` alguns segundos mais tarde,
depois pare o `b` com Ctrl+C, espere alguns segundos e pare o `a`.

## Eager: todo mundo devolve tudo

O **protocolo classic** com a estratégia `range`, o arranjo mais antigo, é chamado de **eager**: a
cada rebalanceamento todo membro abre mão de todas as suas partições, e depois recebe um conjunto
novo.

@@fence@@

@@fence@@

Quando o `b` entrou, o `a` devolveu as três partições e recebeu de volta a 0 e a 1; o `b` recebeu a 2.
Quando o `b` saiu, o `a` devolveu a 0 e a 1 e recebeu as três. **As partições 0 e 1 nunca precisaram
mudar de dono, e pararam mesmo assim**, duas vezes. Com três partições isso custa um instante; com
duzentas partições e cinquenta membros, todo membro parando a cada entrada é uma pausa que o grupo
inteiro sente, e um deploy que reinicia os membros um a um causa uma pausa por membro.

## Cooperativo: só para o que muda

O mesmo protocolo classic com a estratégia `cooperative-sticky` é **incremental**: um membro só abre
mão das partições que vão para outro, e continua lendo o resto.

@@fence@@

@@fence@@

Quando o `b` entrou, o `a` abriu mão só da partição 0 e ficou com a 1 e a 2 o tempo todo. Num protocolo
incremental os callbacks informam mudanças em vez do conjunto inteiro: `assigned []` quer dizer "nada
de novo para você nesta rodada", e o primeiro `assigned []` do `b` é a rodada em que a partição 0 foi
liberada pelo `a` antes de poder ser repassada. Quando o `b` saiu, o `a` recebeu a 0 de volta, e o
`revoked` final dele lista as três porque ele estava encerrando.

## O protocolo consumer: o broker decide

O Kafka 4 traz um protocolo novo, do KIP-848, aquele que o console consumer da lição 1 vivia
mencionando. No protocolo classic os membros negociam a atribuição entre si, por meio de um deles
escolhido como líder, e cada mudança é uma rodada de entrar e sincronizar. No **protocolo consumer** o
coordenador de grupos do broker calcula a atribuição e diz a cada membro o que acrescentar e o que
largar, membro a membro, sem uma rodada que todos precisem terminar. O cliente Python o suporta com
`group.protocol=consumer`:

@@fence@@

Isso foi com o `a` e o `b` rodando. Os ids dos membros têm outra forma, porque quem os emite é o
coordenador, e as partições estão divididas em duas e uma, como antes:

@@fence@@

@@fence@@

O `a` abriu mão só da partição 2, o `b` a pegou, e quando o `b` saiu, o `a` a recebeu de volta. O mesmo
comportamento incremental do cooperative-sticky, decidido num lugar só. Com o protocolo consumer a
configuração `partition.assignment.strategy` nem se aplica, e é por isso que o `consumer.py` só a
configura no `classic`.

| | quem calcula a atribuição | o que para durante uma mudança |
|---|---|---|
| classic, `range` (eager) | o membro líder do grupo | toda partição de todo membro |
| classic, `cooperative-sticky` | o membro líder do grupo | só as partições que mudam de dono |
| consumer (KIP-848) | o coordenador de grupos do broker | só as partições que mudam de dono |

**Para uma aplicação nova no Kafka 4, o protocolo consumer é o que escolher**, desde que toda
biblioteca cliente do grupo o suporte. O librdkafka 2.16, por baixo do cliente Python usado aqui,
suporta, como a execução acima mostra.

@@fig:l4-rebalance@@
