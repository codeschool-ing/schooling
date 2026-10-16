---
title: PACELC: a escolha feita quando nada está quebrado
version: 1
---

Partições são raras; na maior parte do tempo a rede funciona. O CAP não tem nada a dizer sobre esse
tempo, e Daniel Abadi apontou em 2012 que a troca mais frequente mora ali. Ele estendeu a pergunta do
teorema para o **PACELC**: se há uma **P**artição, escolha disponibilidade (**A**) ou **C**onsistência;
senão (**E**, de *else*), escolha **L**atência ou **C**onsistência.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma árvore de decisão. A primeira pergunta é se há uma partição. Se sim, o sistema escolhe entre disponibilidade e consistência, que é o CAP. Se não, ainda escolhe, entre latência e consistência, que é a parte do senão do PACELC.\"><defs><marker id=\"l8-pacelc-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l8-pacelc-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"260\" y=\"30\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">há uma partição?</text><rect x=\"60\" y=\"130\" width=\"260\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"190\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">sim: disponibilidade</text><text x=\"190\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ou consistência (CAP)</text><rect x=\"400\" y=\"130\" width=\"260\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">não: latência</text><text x=\"530\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">ou consistência (ELC)</text><path d=\"M320 76 L210 128\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-pacelc-ah-amber)\"></path><path d=\"M400 76 L510 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-pacelc-ah-phosphor)\"></path><text x=\"190\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">raro: quando a rede quebra</text><text x=\"530\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sempre: em toda requisição</text></svg>", "caption": "PACELC: se há Partição, escolha Disponibilidade ou Consistência; Senão, escolha Latência ou Consistência. A segunda escolha é feita em toda requisição."}
```

A metade do "senão" é a replicação síncrona das seções anteriores, vista num dia bom. Todo commit síncrono
espera uma ida e volta até o standby, com partição ou sem. Cronometre 500 commits separados em cada modo:

```
ana@vm:~/lab/cap$ $P -c "ALTER SYSTEM SET synchronous_standby_names = '*'" -c "SELECT pg_reload_conf()" > /dev/null
ana@vm:~/lab/cap$ time (for i in $(seq 500); do echo "UPDATE stock SET units = units WHERE sku = 'coffee';"; done | $P -q)

real	0m0.755s
user	0m0.108s
sys	0m0.053s
ana@vm:~/lab/cap$ $P -c "ALTER SYSTEM RESET synchronous_standby_names" -c "SELECT pg_reload_conf()" > /dev/null
ana@vm:~/lab/cap$ time (for i in $(seq 500); do echo "UPDATE stock SET units = units WHERE sku = 'coffee';"; done | $P -q)

real	0m0.566s
user	0m0.101s
sys	0m0.071s
```

As mesmas 500 atualizações levaram 0,755 segundo com replicação síncrona e 0,566 com assíncrona, em dois
contêineres que estão na mesma máquina e se respondem numa fração de milissegundo. **Ponha o standby em
outro data center, a 30 ms de distância, e cada commit paga 30 ms a mais**, em toda escrita, todo dia,
quebre alguma coisa ou não. É o custo que um sistema paga o tempo todo para ter a consistência que quer
durante a partição rara.

## Onde ficam os sistemas reais

| sistema, como costuma ser configurado | durante uma partição | no resto do tempo |
| --- | --- | --- |
| PostgreSQL com standbys síncronos | consistência: as escritas esperam | consistência: todo commit espera uma ida e volta |
| PostgreSQL com standbys assíncronos | disponibilidade no primário; standbys desatualizados | latência: commits voltam na hora |
| Cassandra, DynamoDB com leituras eventualmente consistentes | disponibilidade | latência |
| DynamoDB com leituras fortemente consistentes | consistência para essas leituras | consistência, com custo maior por leitura |
| etcd, ZooKeeper, o armazenamento do Consul | consistência: o lado minoritário recusa | consistência: toda escrita espera uma maioria |

A última linha é a família que coordena outros sistemas, cuidando de eleições de líder e configuração, e
a aula 19 usa uma. Eles escolhem consistência nas duas metades de propósito, porque dois nós acreditando
ao mesmo tempo que são o líder é a falha que eles existem para impedir.
