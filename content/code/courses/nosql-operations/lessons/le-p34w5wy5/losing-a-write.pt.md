---
title: Perdendo uma escrita confirmada, de propósito
version: 1
---

A aula 1 prometeu esta seção: o Redis com réplicas pende para PA/EL, e aqui ele abre mão da
consistência na sua frente. **Uma escrita que o primário confirmou com `OK` desaparece, e nenhum comando
devolve erro.** Para isso é preciso uma partição, e não uma queda, porque um primário que caiu não
aceita mais nada; um primário isolado das réplicas e dos Sentinels, mas ainda alcançável por um
cliente, aceita tudo.

## A partição

`docker network disconnect` tira um contêiner da rede sem pará-lo. O `docker exec` ainda alcança o
processo lá dentro, como um cliente do mesmo lado de um link quebrado alcançaria:

```
ana@vm:~$ docker exec $primary redis-cli SET order:2001 paid
OK
ana@vm:~$ docker network disconnect nosql $primary
ana@vm:~$ docker exec $primary redis-cli SET order:2002 paid
OK
ana@vm:~$ docker exec $primary redis-cli GET order:2002
paid
```

O pedido 2001 foi gravado antes do corte e replicado. **O pedido 2002 foi gravado depois, respondeu
`OK` e pode ser lido no primário.** Até onde o cliente sabe, está guardado. As réplicas do primário e
todos os Sentinels estão do outro lado do corte, e cinco segundos depois o declaram fora do ar e
promovem uma réplica que nunca ouviu falar do pedido 2002.

## A rede volta

```
ana@vm:~$ old=$primary; primary=$(docker exec sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name shop | head -1); echo "old $old, new $primary"
old redis-2, new redis-3
ana@vm:~$ docker network connect nosql $old
ana@vm:~$ docker exec $old redis-cli INFO replication | grep -E "^(role|master_host|master_link_status):"
role:slave
master_host:redis-3
master_link_status:up
ana@vm:~$ docker exec $old redis-cli GET order:2002

ana@vm:~$ docker exec $primary redis-cli GET order:2002

ana@vm:~$ docker exec $old redis-cli GET order:2001
paid
ana@vm:~$ docker logs $old 2>&1 | grep -E "Full resync|Flushing old data"
1:S 10 Oct 2026 20:12:59.124 * Full resync from master: 0b1275213a56b27ef078aba47f45f4e75c32e5eb:0
1:S 10 Oct 2026 20:12:59.126 * MASTER <-> REPLICA sync: Flushing old data
1:S 10 Oct 2026 20:14:12.334 * Full resync from master: 2872a33f314c48a2f8dca8d2e0169739767a3cc0:7490468
1:S 10 Oct 2026 20:14:12.450 * MASTER <-> REPLICA sync: Flushing old data
```

Quando o primário antigo voltou à rede, o Sentinel o transformou em réplica do novo primário, e uma
réplica recebe o conjunto de dados do primário dela: o log diz **full resync**, e depois **flushing old
data**. O segundo par de linhas, às 20:14:12, é a volta; o primeiro é de quando o `redis-2` começou
como réplica, no início da aula. O pedido 2002 não está mais no primário antigo, nem no novo, nem em
lugar nenhum. O pedido 2001, gravado antes do corte, está em todos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"Dois momentos. Durante a partição: o redis-2, primário antigo, está isolado com os pedidos 2001 e 2002, e respondeu OK aos dois; do outro lado do corte, o redis-3 foi promovido e tem só o pedido 2001, com o redis-1 como réplica. Depois que a partição se desfaz: o redis-2 voltou como réplica do redis-3, recebeu uma cópia completa e tem só o pedido 2001. O pedido 2002 não existe em lugar nenhum.\"><defs><marker id=\"l15lost-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">durante a partição</text><rect x=\"20\" y=\"40\" width=\"140\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">redis-2</text><text x=\"90.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">primário antigo, isolado</text><text x=\"90.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2001  2002</text><line x1=\"175\" y1=\"30\" x2=\"175\" y2=\"130\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"5 4\"></line><rect x=\"190\" y=\"40\" width=\"140\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"260.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">redis-3</text><text x=\"260.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">promovido</text><text x=\"260.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2001</text><rect x=\"190\" y=\"150\" width=\"140\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"260.0\" y=\"167.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">redis-1</text><text x=\"260.0\" y=\"182.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">réplica dele</text><text x=\"90\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">SET 2002: OK</text><text x=\"525\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">depois que volta</text><rect x=\"380\" y=\"40\" width=\"140\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">redis-3</text><text x=\"450.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">primário</text><text x=\"450.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2001</text><rect x=\"540\" y=\"40\" width=\"140\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">redis-2</text><text x=\"610.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">réplica: cópia completa</text><text x=\"610.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2001</text><rect x=\"380\" y=\"150\" width=\"140\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"167.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">redis-1</text><text x=\"450.0\" y=\"182.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">réplica</text><line x1=\"520\" y1=\"75\" x2=\"538\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l15lost-ah-paper-dim)\"></line><text x=\"610\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">pedido 2002: sumiu</text><text x=\"350\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhum comando devolveu erro</text></svg>", "caption": "A escrita respondeu OK do lado errado do corte. Quando o corte se desfaz, o primário antigo recebe inteiros os dados do novo primário, e a escrita que só ele tinha vai embora com os dados antigos.", "same": ["SET 2002: OK"]}
```

Nada está errado com este Redis. Ele fez o que a replicação assíncrona faz numa partição, e é a escolha
do CAP da aula 1 feita por um sistema real: o primário isolado continuou disponível e abriu mão da
consistência.

## `WAIT`: saber, não impedir

`WAIT n timeout` bloqueia o cliente até `n` réplicas confirmarem as escritas anteriores dele, ou até o
timeout, em milissegundos, passar, e responde quantas confirmaram. Rodado contra o primário saudável,
com duas configurações de segurança que o próximo bloco explica:

```
ana@vm:~$ docker exec -it $primary redis-cli
127.0.0.1:6379> CONFIG SET min-replicas-to-write 1
OK
127.0.0.1:6379> CONFIG SET min-replicas-max-lag 10
OK
127.0.0.1:6379> SET order:2003 paid
OK
127.0.0.1:6379> WAIT 2 1000
(integer) 2
ana@vm:~$ docker network disconnect nosql $primary
```

O `WAIT 2 1000` respondeu 2: as duas réplicas têm o pedido 2003. Agora o mesmo primário, isolado de
novo:

```
ana@vm:~$ docker exec -it $primary redis-cli
127.0.0.1:6379> SET order:2004 paid
OK
127.0.0.1:6379> WAIT 1 2000
(integer) 0
(2.00s)
127.0.0.1:6379> GET order:2004
"paid"
127.0.0.1:6379> SET order:2005 paid
(error) NOREPLICAS Not enough good replicas to write.
```

O `SET order:2004` ainda respondeu `OK`. O `WAIT 1 2000` esperou os seus dois segundos e respondeu
**0**: nenhuma réplica o tem. **O `WAIT` não desfez a escrita**: o `GET` a mostra no primário, de onde o
próximo failover vai jogá-la fora exatamente como o pedido 2002. O que o `WAIT` dá é conhecimento: a
aplicação fica sabendo que esta escrita está em risco, e pode dizer ao cliente que o pedido não está
confirmado em vez de mostrar um recibo. A documentação do Redis diz com todas as letras que o `WAIT` não
torna o Redis fortemente consistente: uma réplica que confirmou ainda pode perder a escrita num failover
dela própria.

## `min-replicas-to-write`: encolhendo a janela

As duas configurações da primeira sessão são a outra metade. **`min-replicas-to-write 1` com
`min-replicas-max-lag 10` faz o primário recusar escritas quando menos de uma réplica lhe respondeu nos
últimos 10 segundos.** Doze segundos depois do corte, o `SET order:2005` foi recusado com `NOREPLICAS`.
Um primário isolado para de aceitar escritas que não consegue replicar.

Isso não fecha a janela, a limita: nos primeiros segundos depois de um corte, antes de o atraso passar
do limite, o primário ainda aceita escritas que vão se perder, o pedido 2004 entre elas. Um
`min-replicas-max-lag` menor encolhe a janela e faz o primário recusar escritas também em soluços comuns
da rede. É o PACELC de novo, ajustado por dois números.
