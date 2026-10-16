---
title: O primário que volta
version: 1
---

A máquina que caiu reinicia, e o PostgreSQL dela sobe, como está configurado para fazer no boot:

```
ana@vm:~$ sudo pg_ctlcluster 16 main start
Removed stale pid file.
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory                 Log file
16  main    5432 online postgres /var/lib/postgresql/16/main    /var/log/postgresql/postgresql-16-main.log
16  standby 5434 online postgres /var/lib/postgresql/16/standby /var/log/postgresql/postgresql-16-standby.log
shop=# SELECT pg_is_in_recovery();
 pg_is_in_recovery 
-------------------
 f
(1 row)

shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (53, 5300, now()) RETURNING id;
  id   
-------
 50034
(1 row)

INSERT 0 1
ana@vm:~$ psql -XAt shop -c "SELECT id, customer_id FROM orders WHERE id > 50000 ORDER BY id"
50001|51
50034|53
ana@vm:~$ psql -XAt -p 5434 shop -c "SELECT id, customer_id FROM orders WHERE id > 50000 ORDER BY id"
50001|51
50034|52
```

**Dois primários.** O antigo não tem `standby.signal`; nada no diretório de dados dele diz que alguma
coisa aconteceu, então ele subiu como o que era, um primário, e aceitou um pedido. Cada servidor
entregou o id **50034**, a dois clientes diferentes. Uma aplicação com uma conexão para cada um, ou um
load balancer que manda algumas requisições para cá e outras para lá, escreve nos dois, e a partir
deste momento os dados do shop são duas histórias que nenhum programa consegue juntar:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Uma história horizontal na timeline 1 até o pedido 50001. Ali ela se bifurca. O ramo de cima é o standby promovido na porta 5434, timeline 2, onde o pedido 50034 é do cliente 52. O ramo de baixo é o primário antigo na porta 5432, reiniciado e ainda na timeline 1, onde o pedido 50034 é do cliente 53. Os dois ramos nunca mais se encontram.\"><defs><marker id=\"l15t-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"l15t-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M20 110 L250 110\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"30\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">timeline 1</text><circle cx=\"250\" cy=\"110\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"250\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pedido 50001</text><path d=\"M256 106 L330 55 L690 55\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#l15t-ph)\"></path><path d=\"M256 114 L330 165 L690 165\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#l15t-am)\"></path><text x=\"345\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">5434, promovido</text><text x=\"560\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">timeline 2</text><rect x=\"470\" y=\"62\" width=\"170\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"555\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">50034: cliente 52</text><text x=\"345\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">5432, o primário antigo</text><text x=\"560\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">timeline 1</text><rect x=\"470\" y=\"132\" width=\"170\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"555\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">50034: cliente 53</text><text x=\"330\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">duas histórias, nunca mescladas</text></svg>", "caption": "Split-brain depois de um reboot: o standby promovido e o primário antigo receberam escritas, e cada um deu o id 50034 a um cliente diferente.", "same": ["timeline 1", "timeline 2"]}
```

Isso é **split-brain**, e não precisou de nada mais exótico do que um reboot. A regra que vem daí é a
da terceira pergunta: **um primário que falhou nunca pode voltar como primário.** Numa máquina só, isso
quer dizer garantir que ele não suba, ou que suba como standby; em hosts de verdade, quer dizer tirá-lo
de serviço antes que ele possa voltar, o que a lição 17 chama de fencing.

## Por que não um script

Os passos desta lição são curtos, e a tentação é um script no standby que o promove quando o primário
para de responder. Esse script responde à primeira pergunta com "não consigo alcançá-lo", e no dia em
que a rede entre os dois cai e as duas máquinas continuam de pé, ele produz exatamente a figura acima,
sem precisar de reboot. Um failover automático só é seguro quando alguma coisa além dos dois servidores
decide, e a lição 16 constrói isso.
