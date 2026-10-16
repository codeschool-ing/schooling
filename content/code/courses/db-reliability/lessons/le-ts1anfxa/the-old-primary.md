---
title: The primary that comes back
version: 1
---

The crashed machine reboots, and its PostgreSQL starts, as it is configured to on boot:

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

**Two primaries.** The old one has no `standby.signal`; nothing in its data directory says anything
happened, so it started as what it was, a primary, and accepted an order. Each server has handed out
id **50034**, to two different customers. An application with a connection to each, or a load
balancer that sends some requests here and some there, writes to both, and from this moment the
shop's data is two histories that can never be merged by a program:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A horizontal history on timeline 1 up to order 50001. There it forks. The upper branch is the promoted standby on port 5434, timeline 2, where order 50034 belongs to customer 52. The lower branch is the old primary on port 5432, rebooted and still on timeline 1, where order 50034 belongs to customer 53. The two branches never meet again.\"><defs><marker id=\"l15t-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"l15t-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M20 110 L250 110\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"30\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">timeline 1</text><circle cx=\"250\" cy=\"110\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"250\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">order 50001</text><path d=\"M256 106 L330 55 L690 55\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#l15t-ph)\"></path><path d=\"M256 114 L330 165 L690 165\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#l15t-am)\"></path><text x=\"345\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">5434, promoted</text><text x=\"560\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">timeline 2</text><rect x=\"470\" y=\"62\" width=\"170\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"555\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">50034: customer 52</text><text x=\"345\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">5432, the old primary</text><text x=\"560\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">timeline 1</text><rect x=\"470\" y=\"132\" width=\"170\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"555\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">50034: customer 53</text><text x=\"330\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">two histories, never merged</text></svg>", "caption": "Split-brain after a reboot: the promoted standby and the old primary each took writes, and each gave id 50034 to a different customer."}
```

This is **split-brain**, and it took nothing more exotic than a reboot. The rule that follows is the
third question's: **a failed primary must never come back as a primary.** On a single machine that
means making sure it does not start, or starts as a standby; on real hosts it means removing it from
service before it can return, which is what lesson 17 calls fencing.

## Why not a script

The steps in this lesson are short, and the temptation is a script on the standby that promotes it
when the primary stops answering. That script answers the first question with "I cannot reach it",
and on the day the network between the two breaks and both machines stay up, it produces exactly the
picture above, with no reboot needed. An automatic failover is only safe when something other than the
two servers decides, and lesson 16 builds that.
