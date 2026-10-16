---
title: Escolhendo consistência: replicação síncrona
version: 1
---

Com **replicação síncrona**, o primário não diz a um cliente que uma escrita foi gravada até o standby
confirmar que tem a mudança em disco. Perder o primário então não perde nada sobre o que um cliente foi
avisado, e é por isso que essa é a configuração para dados que não podem se perder. Ligue; `*` quer
dizer "qualquer standby":

```
ana@vm:~/lab/cap$ $P -c "ALTER SYSTEM SET synchronous_standby_names = '*'" -c "SELECT pg_reload_conf()"
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@vm:~/lab/cap$ $P -c "SELECT client_addr, state, sync_state FROM pg_stat_replication"
 client_addr |   state   | sync_state 
-------------+-----------+------------
 172.18.0.3  | streaming | sync
(1 row)
```

`sync_state` agora é `sync`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Duas sequências de uma escrita do cliente ao primário e ao standby. Síncrona: o primário grava, manda a mudança ao standby, espera a confirmação do standby, e só então diz ao cliente que está gravado. Assíncrona: o primário grava e avisa o cliente na hora; a mudança chega ao standby depois.\"><defs><marker id=\"l8-sync-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l8-sync-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">síncrona</text><rect x=\"20\" y=\"46\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cliente</text><path d=\"M65 74 L65 266\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"135\" y=\"46\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">primário</text><path d=\"M180 74 L180 266\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"250\" y=\"46\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">standby</text><path d=\"M295 74 L295 266\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M68 96 L177 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-sync-ah-phosphor)\"></path><text x=\"122.5\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UPDATE</text><path d=\"M183 126 L292 126\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-sync-ah-phosphor)\"></path><text x=\"237.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">WAL</text><path d=\"M292 166 L183 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l8-sync-ah-phosphor)\"></path><text x=\"237.5\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">gravado</text><path d=\"M177 206 L68 206\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l8-sync-ah-phosphor)\"></path><text x=\"122.5\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">COMMIT</text><text x=\"530\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">assíncrona</text><rect x=\"370\" y=\"46\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"415\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cliente</text><path d=\"M415 74 L415 266\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"485\" y=\"46\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">primário</text><path d=\"M530 74 L530 266\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"600\" y=\"46\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"645\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">standby</text><path d=\"M645 74 L645 266\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M418 96 L527 96\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-sync-ah-amber)\"></path><text x=\"472.5\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UPDATE</text><path d=\"M527 126 L418 126\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l8-sync-ah-amber)\"></path><text x=\"472.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">COMMIT</text><path d=\"M533 176 L642 176\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-sync-ah-amber)\"></path><text x=\"587.5\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">WAL, depois</text></svg>", "caption": "A replicação síncrona responde ao cliente depois de a cópia confirmar; a assíncrona responde antes. A diferença é uma ida e volta em todo commit, e o que uma partição faz com cada uma.", "same": ["standby"]}
```

## A partição

`docker network disconnect` tira o standby da rede do laboratório, o que é uma partição sem mais nada de
errado: os dois servidores estão de pé, e nenhum alcança o outro. Então tente vender um pacote de café,
com `timeout 5` para o shell desistir depois de cinco segundos:

```
ana@vm:~/lab/cap$ docker network disconnect cap_default cap-standby-1
ana@vm:~/lab/cap$ timeout 5 $P -c "UPDATE stock SET units = 11 WHERE sku = 'coffee'"; echo "exit code $?"

exit code 124
ana@vm:~/lab/cap$ $P -c "SELECT pid, wait_event, query FROM pg_stat_activity WHERE wait_event = 'SyncRep'"
 pid | wait_event |                      query                       
-----+------------+--------------------------------------------------
 106 | SyncRep    | UPDATE stock SET units = 11 WHERE sku = 'coffee'
(1 row)

ana@vm:~/lab/cap$ $P -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    12
(1 row)

ana@vm:~/lab/cap$ $S -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    12
(1 row)
```

**A escrita não voltou.** Depois de cinco segundos o `timeout` matou o cliente, código de saída 124, e o
primário continua segurando a atualização: `pg_stat_activity` mostra que ela espera em `SyncRep`, por um
standby que não consegue responder. Os dois servidores ainda mostram 12 pacotes, porque a transação que
espera não fica visível para mais ninguém até a espera terminar.

Essa é a escolha **C** do CAP, feita por uma configuração: em vez de aceitar uma escrita que não consegue
copiar, o primário para de aceitar escritas, **e para esse dado o sistema fica indisponível enquanto a
partição durar.** As leituras continuam funcionando dos dois lados, e concordam.

## Quando a rede volta

Reconecte o standby:

```
ana@vm:~/lab/cap$ docker network connect cap_default cap-standby-1
ana@vm:~/lab/cap$ $P -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    11
(1 row)

ana@vm:~/lab/cap$ $S -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    11
(1 row)
```

O standby alcançou o primário, confirmou a mudança, e o primário terminou a transação que estava
esperando: os dois agora dizem 11. **O cliente que a mandou nunca ficou sabendo**: tinha desistido e ido
embora. Do ponto de vista dele a venda falhou, e no banco ela deu certo. É a incerteza da aula 2 de novo,
e a resposta é de novo uma chave de idempotência, para o retry do cliente ser reconhecido como a mesma
venda.

Configurações de produção costumam suavizar a parada nomeando dois ou mais standbys e exigindo a resposta
de qualquer um, `ANY 1 (s1, s2)`, para um standby perdido não parar as escritas; perder todos ainda para.
