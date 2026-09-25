---
title: Levando outra conexão por dentro do SSH
version: 1
---

O servidor do escritório tem uma pequena página web mostrando o estado dos backups. Ela só escuta em
`127.0.0.1`, o servidor falando consigo mesmo, então nada na rede a alcança:

```
ana@laptop:~$ curl -sS -m 3 http://192.168.10.10:8080/
curl: (7) Failed to connect to 192.168.10.10 port 8080 after 0 ms: Couldn't connect to server
ana@server:~$ ss -tln | grep 8080
LISTEN 0      5          127.0.0.1:8080      0.0.0.0:*          
ana@laptop:~$ eval $(ssh-agent) >/dev/null
ana@laptop:~$ ssh-add
Enter passphrase for /home/ana/.ssh/id_ed25519: 
Identity added: /home/ana/.ssh/id_ed25519 (ana@laptop)
ana@laptop:~$ ssh -f -N -L 8080:127.0.0.1:8080 office
ana@laptop:~$ curl -s http://127.0.0.1:8080/
<h1>Office server: backups</h1>
<p>Last backup: finished.</p>
```

O `curl` do laptop foi recusado, e o `ss` mostra por quê: `127.0.0.1:8080`, e não `0.0.0.0:8080`.
`ssh -L 8080:127.0.0.1:8080 office` transforma a porta 8080 do próprio laptop numa porta para dentro do
servidor. O que se conecta a ela é levado dentro da conexão SSH, e o sshd, no servidor, conecta a
`127.0.0.1` porta 8080 do outro lado. O `-f` manda o ssh para o segundo plano e o `-N` não roda comando
nenhum, porque o túnel é tudo o que se quer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Um encaminhamento de porta local. No laptop, o curl pede 127.0.0.1 porta 8080, onde escuta o cliente ssh iniciado com -L. O cliente leva o pedido dentro da conexão cifrada com a porta 22 do servidor. No servidor, o sshd abre uma conexão para 127.0.0.1 porta 8080, a página de backups, que só escuta ali. Uma conexão direta do laptop para 192.168.10.10 porta 8080 é recusada.\"><defs><marker id=\"tn-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"210\" height=\"170\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"22\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><rect x=\"500\" y=\"20\" width=\"210\" height=\"170\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"512\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server</text><rect x=\"22\" y=\"50\" width=\"190\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"71\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curl 127.0.0.1:8080</text><rect x=\"120\" y=\"126\" width=\"90\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"132\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ssh -L</text><rect x=\"512\" y=\"126\" width=\"80\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"524\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sshd</text><rect x=\"512\" y=\"50\" width=\"190\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"522\" y=\"71\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">página de backups, 127.0.0.1:8080</text><path d=\"M165 84 L165 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tn-ah)\"></path><path d=\"M210 143 L510 143\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\" marker-end=\"url(#tn-ah)\"></path><text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">cifrado, dentro da conexão com a porta 22</text><path d=\"M552 126 L552 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tn-ah)\"></path><path d=\"M212 67 L510 67\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tn-ah)\" stroke-dasharray=\"5 4\"></path><text x=\"360\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">192.168.10.10:8080: recusada</text><text x=\"360\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">-L 8080:127.0.0.1:8080</text></svg>", "caption": "Do outro lado do -L, 127.0.0.1 quer dizer o próprio servidor, porque é lá que o sshd faz a última conexão. A página nunca escutou na rede, e continua sem escutar."}
```

Leia as três partes como *porta local* : *destino* : *porta do destino*, onde **o destino é visto a
partir do servidor**. `127.0.0.1` quer dizer o próprio servidor; o endereço de outra máquina ali
chegaria a uma máquina que só o servidor enxerga.

Dois parentes não foram rodados para esta aula. O `-R` é o espelho: uma porta no servidor leva de volta
ao cliente, e é assim que alguém atrás de um NAT oferece um caminho de entrada sem regra no router. O
`-D 1080` transforma o ssh num proxy SOCKS, e um navegador configurado para usá-lo navega a partir do
servidor. Os dois são úteis, e os dois levam tráfego por um firewall que não foi escrito esperando por
eles, e é por isso que alguns servidores proíbem o encaminhamento com `AllowTcpForwarding no`.
