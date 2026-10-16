---
title: Um endereço na frente de três servidores
version: 1
---

A outra abordagem põe a decisão num **proxy**: a aplicação conecta num endereço fixo, e o proxy
encaminha cada conexão nova para o servidor que for o primário naquele momento. O **HAProxy** é o
mais comum, e ele descobre quem é o primário perguntando ao Patroni. Todo nó Patroni responde HTTP na
sua porta REST, e o caminho `/primary` devolve **200** no líder e **503** em todos os outros:

```
ana@vm:~$ for p in 8008 8009 8010; do curl -s -o /dev/null -w "$p %{http_code}\n" http://127.0.0.1:$p/primary; done
8008 200
8009 503
8010 503
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A aplicação, à esquerda, conecta no HAProxy na porta 5000. O HAProxy checa cada um dos três nós a cada dois segundos, perguntando /primary ao Patroni de cada um: o pg1 responde 200 e está no ar, o pg2 e o pg3 respondem 503 e estão fora para essa porta. Conexões novas na porta 5000 vão só para o pg1.\"><defs><marker id=\"l19p-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"l19p-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">aplicação</text><rect x=\"230\" y=\"80\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"305\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">HAProxy</text><text x=\"305\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:5000</text><path d=\"M152 115 L228 115\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19p-pa)\"></path><text x=\"190\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">conexões novas</text><rect x=\"520\" y=\"30\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">pg1</text><text x=\"625\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/primary 200</text><text x=\"625\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">no ar</text><path d=\"M382 115 L450 53 L518 53\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19p-ph)\"></path><rect x=\"520\" y=\"95\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pg2</text><text x=\"625\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/primary 503</text><text x=\"625\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fora</text><path d=\"M382 115 L450 118 L518 118\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><rect x=\"520\" y=\"160\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pg3</text><text x=\"625\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/primary 503</text><text x=\"625\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fora</text><path d=\"M382 115 L450 183 L518 183\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"450\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">checa a cada 2 s</text></svg>", "caption": "O HAProxy na frente de um cluster do Patroni: ele pergunta a cada nó se ele é o primário e manda as conexões novas da porta 5000 só para o que responde que sim."}
```

Instale o HAProxy pelos pacotes do Ubuntu:

```sh
sudo apt install -y haproxy
```

Como o PgBouncer na lição 18, o pacote roda um serviço próprio; esta lição roda o seu próprio HAProxy
com o seu usuário, a partir de `~/haproxy`, para que dê para mudá-lo sem `sudo`. Salve isto como
`~/haproxy/haproxy.cfg`:

```schooling-example
{"language": "cfg", "file": "haproxy.cfg", "parts": [{"code": "global\n    maxconn 200\n    pidfile /home/ana/haproxy/haproxy.pid\n", "note": "Configurações do próprio processo: o arquivo com o ID do processo, ao lado da configuração."}, {"code": "defaults\n    mode tcp\n    timeout connect 4s\n    timeout client 30m\n    timeout server 30m\n    timeout check 2s\n", "note": "O modo `tcp` repassa o protocolo do PostgreSQL sem mexer nele. Os timeouts de cliente e de servidor são longos, porque uma conexão de banco passa a maior parte da vida ociosa e o HAProxy a cortaria."}, {"code": "listen primary\n    bind 127.0.0.1:5000\n    option httpchk GET /primary\n    http-check expect status 200", "note": "A porta 5000 sempre leva ao primário. Cada servidor é checado a cada dois segundos na sua porta do Patroni, e só conta como no ar quando `/primary` responde 200."}, {"code": "    default-server inter 2s fall 2 rise 2 on-marked-down shutdown-sessions\n    server pg1 127.0.0.1:5441 check port 8008\n    server pg2 127.0.0.1:5442 check port 8009\n    server pg3 127.0.0.1:5443 check port 8010\n", "note": "`fall 2` marca um servidor como fora depois de duas checagens com falha, `rise 2` como no ar depois de duas boas. `shutdown-sessions` fecha as conexões ainda abertas com um servidor no momento em que ele é marcado como fora, para que nenhum cliente continue escrevendo num primário que deixou de ser primário."}, {"code": "listen replicas\n    bind 127.0.0.1:5001\n    balance roundrobin\n    option httpchk GET /replica\n    http-check expect status 200\n    default-server inter 2s fall 2 rise 2\n    server pg1 127.0.0.1:5441 check port 8008\n    server pg2 127.0.0.1:5442 check port 8009\n    server pg3 127.0.0.1:5443 check port 8010\n", "note": "A porta 5001 distribui as conexões entre as réplicas, para leituras que podem estar um pouco atrasadas: as leituras desatualizadas da lição 13, de propósito."}, {"code": "listen stats\n    bind 127.0.0.1:7000\n    mode http\n    stats enable\n    stats uri /", "note": "Uma página de status na porta 7000, que também responde em CSV para scripts."}]}
```

Inicie com `-D`, que manda o processo para o background, pergunte à página de status quais servidores
cada lado considera no ar e depois conecte pelas duas portas:

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

Cada servidor aparece duas vezes, uma por lado. No lado do primário só o `pg1` está `UP`, porque só o
Patroni dele responde 200 a `/primary`; no lado das réplicas é o contrário. A porta 5000 levou à
5441, fora de recovery, e duas conexões na porta 5001 foram para a 5442 e depois para a 5443, as duas
réplicas, uma de cada vez.

O HAProxy agora é mais uma coisa que precisa estar no ar, então em produção rodam dois, ou um em cada
servidor de aplicação, cada um apontando para os três nós.
