---
title: O delete que volta
version: 1
---

A regra da última seção, rodar repair em todo nó dentro de `gc_grace_seconds`, soa como faxina. Esta
seção a quebra de propósito e vê uma linha apagada voltar. **Duas configurações foram encurtadas para
isso acontecer em minutos e não em dias, e a aula diz quais**:

- a tabela é criada **`WITH gc_grace_seconds = 60`**, um minuto em vez de dez dias;
- o hinted handoff é **desligado em todos os nós** com `nodetool disablehandoff`. Isso faz o papel de
  um nó que ficou fora mais que `max_hint_window`, três horas por padrão, depois do que ninguém
  guarda mais as escritas que ele perdeu.

Todo o resto é o comportamento comum do Cassandra 5.0.9.

## A linha, o delete, e um nó que o perdeu

Uma lista de desejos da Ana com dois itens, gravada em `ALL` para os três nós terem os dois, e os
hints desligados:

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE TABLE shop.wishlist (customer text, sku text, PRIMARY KEY (customer, sku)) WITH gc_grace_seconds = 60;
cqlsh> CONSISTENCY ALL
Consistency level set to ALL.
cqlsh> INSERT INTO shop.wishlist (customer, sku) VALUES ('ana@example.com', 'KB-101');
cqlsh> INSERT INTO shop.wishlist (customer, sku) VALUES ('ana@example.com', 'MN-330');
cqlsh> exit
ana@vm:~$ for n in c1 c2 c3; do docker exec $n nodetool disablehandoff; done
ana@vm:~$ docker exec c1 nodetool statushandoff
Hinted handoff is not running
```

Pare o `c3` e apague um item em `QUORUM`, que dá certo com `c1` e `c2`:

```
ana@vm:~$ docker stop c3
c3
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY QUORUM
Consistency level set to QUORUM.
cqlsh> DELETE FROM shop.wishlist WHERE customer = 'ana@example.com' AND sku = 'MN-330';
cqlsh> SELECT * FROM shop.wishlist WHERE customer = 'ana@example.com';

 customer        | sku
-----------------+--------
 ana@example.com | KB-101

(1 rows)
cqlsh> exit
```

A Ana tirou o monitor e a loja mostra um item. No `c1` e no `c2` o monitor agora tem uma lápide. No
`c3`, que estava fora, a linha do monitor continua lá, e com os hints desligados nada vai avisá-lo.

## Depois do período de carência

Espere mais que os 60 segundos da tabela, depois faça flush e compact nos dois nós que viram o delete:

```
ana@vm:~$ sleep 70
ana@vm:~$ for n in c1 c2; do docker exec $n nodetool flush shop wishlist; docker exec $n nodetool compact shop wishlist; done
ana@vm:~$ docker exec c1 sh -c "/opt/cassandra/tools/bin/sstabledump /var/lib/cassandra/data/shop/wishlist-*/*Data.db"
[
  {
    "table kind" : "REGULAR",
    "partition" : {
      "key" : [ "ana@example.com" ],
      "position" : 29
    },
    "rows" : [
      {
        "type" : "row",
        "position" : 29,
        "clustering" : [ "KB-101" ],
        "liveness_info" : { "tstamp" : "2026-10-10T19:59:26.214390Z" },
        "cells" : [ ]
      }
    ]
  }
]
```

**O despejo do `c1` tem o teclado e nada mais.** A linha do monitor e a lápide dela foram juntadas
pela compactação, a lápide era mais velha que `gc_grace_seconds`, e as duas foram descartadas. O `c1`
não sabe mais que o monitor esteve na lista da Ana, nem que foi tirado. O `c2` está igual.

## O nó volta

Ligue o `c3` e espere-o responder com um laço como o da aula 1:

```sh
until docker exec c3 cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done
```

```
ana@vm:~$ docker start c3
c3
ana@vm:~$ until docker exec c3 cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY ONE
Consistency level set to ONE.
cqlsh> SELECT * FROM shop.wishlist WHERE customer = 'ana@example.com';

 customer        | sku
-----------------+--------
 ana@example.com | KB-101

(1 rows)
cqlsh> exit
```

Uma leitura em `ONE` a partir do `c1` mostra um item, a resposta certa, porque perguntou ao `c1`.
Depois, o repair que as regras deste curso mandam rodar:

```
ana@vm:~$ docker exec c1 nodetool repair -full shop wishlist | grep -E "Starting repair|Repair completed"
[2026-10-10 20:01:25,369] Starting repair command #1 (5f764f60-c4e5-11f1-831b-f95588ceb72a), repairing keyspace shop with repair options (parallelism: parallel, primary range: false, incremental: false, job threads: 1, ColumnFamilies: [wishlist], dataCenters: [], hosts: [], previewKind: NONE, # of ranges: 48, pull repair: false, force repair: false, optimise streams: false, ignore unreplicated keyspaces: false, repairPaxos: true, paxosOnly: false)
[2026-10-10 20:01:26,371] Repair completed successfully
[2026-10-10 20:01:26,404] Repair completed successfully
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY ONE
Consistency level set to ONE.
cqlsh> SELECT * FROM shop.wishlist WHERE customer = 'ana@example.com';

 customer        | sku
-----------------+--------
 ana@example.com | KB-101
 ana@example.com | MN-330

(2 rows)
cqlsh> exit
```

**O monitor voltou.** O repair comparou as três réplicas, achou que o `c3` tinha uma linha que as outras
duas não tinham e, sem lápide em lugar nenhum para dizer que ela fora apagada, fez o que o repair faz
com uma linha que uma réplica tem e as outras não: copiou-a para elas. A lista de desejos da Ana agora
tem um item que ela tirou, nos três nós, e nada em log nenhum chama isso de erro. Uma leitura em `ALL` antes do repair é o outro caminho de volta para a linha, pelo
read repair da aula 19; esta execução foi direto ao repair.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 380\" role=\"img\" aria-label=\"Uma grade no tempo, uma linha por passo e uma coluna por nó, c1, c2 e c3. Passo 1: a linha da lista de desejos está nos três. Passo 2: o c3 é parado e o delete em QUORUM grava uma lápide no c1 e no c2, enquanto o c3, fora, mantém a linha. Passo 3: passa o gc_grace_seconds. Passo 4: a compactação no c1 e no c2 descarta a lápide e a linha debaixo dela, sem deixar nada. Passo 5: o c3 volta com a linha, e um repair a copia para o c1 e o c2, então a linha apagada está de volta nos três.\"><text x=\"312\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c1</text><text x=\"457\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c2</text><text x=\"602\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c3</text><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1. gravada em ALL</text><rect x=\"250\" y=\"44\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"312.5\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linha</text><rect x=\"395\" y=\"44\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"457.5\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linha</text><rect x=\"540\" y=\"44\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"602.5\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linha</text><text x=\"20\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2. c3 para; DELETE em QUORUM</text><rect x=\"250\" y=\"108\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"312.5\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lápide</text><rect x=\"395\" y=\"108\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"457.5\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lápide</text><rect x=\"540\" y=\"108\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"602.5\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linha, parado</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. passa o gc_grace_seconds</text><rect x=\"250\" y=\"172\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"312.5\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lápide</text><rect x=\"395\" y=\"172\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"457.5\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lápide</text><rect x=\"540\" y=\"172\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"602.5\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linha, parado</text><text x=\"20\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4. flush e compact no c1, c2</text><rect x=\"250\" y=\"236\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"312.5\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nada</text><rect x=\"395\" y=\"236\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"457.5\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nada</text><rect x=\"540\" y=\"236\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"602.5\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linha, parado</text><text x=\"20\" y=\"318\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5. c3 volta; repair</text><rect x=\"250\" y=\"300\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"312.5\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linha de novo</text><rect x=\"395\" y=\"300\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"457.5\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linha de novo</text><rect x=\"540\" y=\"300\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"602.5\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linha</text><text x=\"20\" y=\"362\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a linha velha do c3 não encontra lápide, então vence</text></svg>", "caption": "O delete que volta. Depois que a lápide é expurgada nos nós que viram o delete, não sobra nada para dizer à linha velha do nó que retorna que ela foi apagada."}
```

## O que deu errado de fato

Não foi o repair: ele fez seu trabalho com o que recebeu. Nem o delete. **A falha é que a lápide
expirou antes de chegar a toda réplica**, e em produção isso acontece quando uma destas coisas é
verdade por mais que `gc_grace_seconds`:

- um nó está fora e depois é religado com os dados antigos;
- o repair não roda, ou roda em alguns nós e não em outros, ou falha toda noite sem ninguém notar;
- `gc_grace_seconds` foi baixado para as lápides sumirem mais rápido, e o calendário de repair não foi
  apertado junto.

Com os padrões que o laboratório encurtou, dez dias e três horas, a janela é larga mas o mecanismo é o
mesmo. Uma loja veria um pedido cancelado reaparecer, um endereço apagado de um cliente voltar, ou um
item vendido retornar ao estoque. A aula 19 trata da maquinaria que impede isso, e de manter o repair
rodando para que impeça.

Antes de seguir, arrume o cluster: `for n in c1 c2 c3; do docker exec $n nodetool enablehandoff;
done` liga os hints de novo. Reiniciar um nó faz o mesmo, já que o `disablehandoff` só dura até o
processo reiniciar.
