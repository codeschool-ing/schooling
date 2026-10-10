---
title: Atraso de replicação, e ler as próprias escritas
version: 1
---

O primário confirma uma transação, diz ao cliente que terminou e manda a mudança para as réplicas
**depois**. Até uma réplica aplicá-la, ela responde com o mundo como era antes. Esse intervalo é o
**atraso de replicação** (*replication lag*), e ele nunca é zero: no melhor caso é o tempo de mandar
alguns kilobytes e aplicá-los, bem abaixo de um milissegundo numa máquina só.

Atrasos abaixo de um milissegundo são difíceis de ver, então esta seção cria um longo o bastante
para assistir. O `compose.yaml` passa o `DELAY` para o `recovery_min_apply_delay` da réplica, uma
configuração do PostgreSQL que faz uma réplica esperar antes de aplicar cada mudança. Dois segundos
fazem o papel de uma réplica que ficou para trás, como as reais ficam: sob uma rajada de escritas,
durante uma consulta longa na réplica, ou através de uma rede lenta para outra região.

```
ana@lab:~/tickets$ DELAY=2s docker compose up -d replica
 Container tickets-db-1 Running 
 Container tickets-replica-1 Recreate 
 Container tickets-replica-1 Recreated 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Starting 
 Container tickets-replica-1 Started 
ana@lab:~/tickets$ curl -s -X POST localhost:8080/events/7/tickets; echo
{"event": 7, "seat": 1, "code": "90ae233034a624a3"}
ana@lab:~/tickets$ curl -s localhost:8080/events/7; echo
{"name": "Show 7", "left": 1000000, "host": "b4849ff3119f"}
ana@lab:~/tickets$ sleep 2
ana@lab:~/tickets$ curl -s localhost:8080/events/7; echo
{"name": "Show 7", "left": 999999, "host": "b4849ff3119f"}
```

A venda do lugar 1 do show 7 deu certo. A página do show 7, lida **logo em seguida** na réplica,
ainda diz um milhão de lugares; dois segundos depois diz um a menos. Nada falhou, e nada vai
registrar um erro sobre isso. **O comprador acabou de comprar um ingresso e a bilheteria diz que ele
nunca foi vendido.**

Essa é a surpresa mais comum que as réplicas causam, e ela tem nome: a garantia que se perdeu é a
de **ler as próprias escritas** (*read-your-writes*). Um usuário que escreveu alguma coisa espera
vê-la na próxima leitura, seja lá o que os outros vejam.

## Mantendo a garantia

Quatro jeitos, do mais grosseiro ao mais preciso:

- **Ler os próprios dados do primário.** Depois de uma venda, as próximas páginas do comprador leem
  do primário; as de todos os outros leem das réplicas. Simples, e só funciona se o programa souber
  quais leituras são "as próprias".
- **Ler do primário por um tempo depois de escrever.** Guardar a hora da última escrita do usuário,
  na sessão ou num cookie, e mandar as leituras dele para o primário pelos próximos segundos. Os
  segundos são um palpite sobre o pior atraso.
- **Esperar a réplica alcançar.** Toda mudança no log tem uma posição, e o programa pode verificar
  que uma réplica aplicou pelo menos a posição da última escrita do usuário antes de ler dela. A
  próxima parte mostra isso.
- **Fazer o primário esperar as réplicas.** A aula 3 faz isso, e mede quanto custa.

## Esperando uma posição

A posição de uma mudança no log é o seu **LSN**, número de sequência do log (*log sequence
number*). Leia a posição do primário logo depois de uma escrita, e pergunte à réplica se ela já
reproduziu até ali:

```
ana@lab:~/tickets$ curl -s -X POST localhost:8080/events/8/tickets; echo
{"event": 8, "seat": 1, "code": "47c7c69c20b6f517"}
ana@lab:~/tickets$ docker compose exec db psql -U tickets -Atc 'SELECT pg_current_wal_lsn()'
0/3001778
ana@lab:~/tickets$ docker compose exec replica psql -U tickets -Atc "SELECT pg_last_wal_replay_lsn() >= '0/3001778'"
f
ana@lab:~/tickets$ sleep 2
ana@lab:~/tickets$ docker compose exec replica psql -U tickets -Atc "SELECT pg_last_wal_replay_lsn() >= '0/3001778'"
t
```

A venda foi gravada em `0/3001778`. Perguntada na hora, a réplica ainda não chegou lá, `f`; dois
segundos depois, `t`. Um programa faz a mesma verificação e espera um instante, ou manda a leitura
para o primário. É exato, e custa um valor de estado por usuário: a posição da última escrita dele,
carregada na sessão.

As três primeiras são decisões no programa, não configurações no banco. **A replicação tira um
problema de consistência do banco e o põe no código que lê dele**, que é a troca que esta aula
inteira continua fazendo de formas diferentes.

Antes de seguir, devolva a réplica a atraso zero recriando-a sem a variável:
`docker compose up -d replica`.
