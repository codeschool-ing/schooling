---
title: One address in front of three servers
version: 1
---

The other approach puts the decision in a **proxy**: the application connects to one fixed address,
and the proxy forwards each new connection to whichever server is the primary now. **HAProxy** is
the usual one, and it learns who the primary is by asking Patroni. Every Patroni node answers HTTP
on its REST port, and the path `/primary` returns **200** on the leader and **503** everywhere else:

```
ana@vm:~$ for p in 8008 8009 8010; do curl -s -o /dev/null -w "$p %{http_code}\n" http://127.0.0.1:$p/primary; done
8008 200
8009 503
8010 503
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The application on the left connects to HAProxy on port 5000. HAProxy checks each of three nodes every two seconds by asking its Patroni for /primary: pg1 answers 200 and is up, pg2 and pg3 answer 503 and are down for this port. New connections on port 5000 go only to pg1.\"><defs><marker id=\"l19p-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"l19p-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">application</text><rect x=\"230\" y=\"80\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"305\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">HAProxy</text><text x=\"305\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:5000</text><path d=\"M152 115 L228 115\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19p-pa)\"></path><text x=\"190\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">new connections</text><rect x=\"520\" y=\"30\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">pg1</text><text x=\"625\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/primary 200</text><text x=\"625\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">up</text><path d=\"M382 115 L450 53 L518 53\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19p-ph)\"></path><rect x=\"520\" y=\"95\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pg2</text><text x=\"625\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/primary 503</text><text x=\"625\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">down</text><path d=\"M382 115 L450 118 L518 118\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><rect x=\"520\" y=\"160\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pg3</text><text x=\"625\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/primary 503</text><text x=\"625\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">down</text><path d=\"M382 115 L450 183 L518 183\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"450\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">checks every 2 s</text></svg>", "caption": "HAProxy in front of a Patroni cluster: it asks every node whether it is the primary, and sends new connections on port 5000 only to the one that says yes."}
```

Install HAProxy from Ubuntu's packages:

```sh
sudo apt install -y haproxy
```

Like PgBouncer in lesson 18, the package runs a service of its own; this lesson runs its own HAProxy
as you, from `~/haproxy`, so that it can be changed without `sudo`. Save this as
`~/haproxy/haproxy.cfg`:

```schooling-example
{"language": "cfg", "file": "haproxy.cfg", "parts": [{"code": "global\n    maxconn 200\n    pidfile /home/ana/haproxy/haproxy.pid\n", "note": "Settings for the process itself: its process-ID file, beside the configuration."}, {"code": "defaults\n    mode tcp\n    timeout connect 4s\n    timeout client 30m\n    timeout server 30m\n    timeout check 2s\n", "note": "`tcp` mode passes PostgreSQL's protocol through untouched. The client and server timeouts are long, because a database connection is idle for most of its life and HAProxy would otherwise cut it."}, {"code": "listen primary\n    bind 127.0.0.1:5000\n    option httpchk GET /primary\n    http-check expect status 200", "note": "Port 5000 always leads to the primary. Each server is checked every two seconds on its Patroni port, and counts as up only when `/primary` answers 200."}, {"code": "    default-server inter 2s fall 2 rise 2 on-marked-down shutdown-sessions\n    server pg1 127.0.0.1:5441 check port 8008\n    server pg2 127.0.0.1:5442 check port 8009\n    server pg3 127.0.0.1:5443 check port 8010\n", "note": "`fall 2` marks a server down after two failed checks, `rise 2` up after two good ones. `shutdown-sessions` closes the connections still open to a server the moment it is marked down, so that no client keeps writing to a primary that is no longer one."}, {"code": "listen replicas\n    bind 127.0.0.1:5001\n    balance roundrobin\n    option httpchk GET /replica\n    http-check expect status 200\n    default-server inter 2s fall 2 rise 2\n    server pg1 127.0.0.1:5441 check port 8008\n    server pg2 127.0.0.1:5442 check port 8009\n    server pg3 127.0.0.1:5443 check port 8010\n", "note": "Port 5001 spreads connections over the replicas, for reads that can be a little behind: lesson 13's stale reads, by design."}, {"code": "listen stats\n    bind 127.0.0.1:7000\n    mode http\n    stats enable\n    stats uri /", "note": "A status page on port 7000, which also answers as CSV for scripts."}]}
```

Start it with `-D`, which sends it to the background, and ask the status page which servers each side
considers up, then connect through both ports:

```
ana@vm:~$ haproxy -D -f ~/haproxy/haproxy.cfg
ana@vm:~$ curl -s 'http://127.0.0.1:7000/;csv' | cut -d, -f1,2,18 | grep -E '^(primary|replicas),pg'
primary,pg1,UP
primary,pg2,DOWN
primary,pg3,DOWN
replicas,pg1,DOWN
replicas,pg2,UP
replicas,pg3,UP
ana@vm:~$ psql -h 127.0.0.1 -p 5000 -U postgres -XAt shop -c 'SELECT inet_server_port(), pg_is_in_recovery()'
5441|f
ana@vm:~$ psql -h 127.0.0.1 -p 5001 -U postgres -XAt shop -c 'SELECT inet_server_port(), pg_is_in_recovery()'
5442|t
ana@vm:~$ psql -h 127.0.0.1 -p 5001 -U postgres -XAt shop -c 'SELECT inet_server_port(), pg_is_in_recovery()'
5443|t
```

Each server appears twice, once per side. On the primary side only `pg1` is `UP`, because only its
Patroni answers 200 to `/primary`; on the replica side it is the other way round. Port 5000 led to
5441, out of recovery, and two connections to port 5001 went to 5442 and then 5443, both replicas, in
turn.

HAProxy is now one more thing that has to be up, so production runs two of them, or one on every
application server, each pointing at all three nodes.
