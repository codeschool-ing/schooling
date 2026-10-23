---
title: Como aparecem uma porta descartada e uma recusada
version: 1
---

**Um conjunto de regras é uma afirmação até um cliente ser recusado por ele.** Pergunte de novo do
outro lado. A partir do `desk`, que não é uma máquina administrativa, e do `admin`, que é:

```
ana@desk:~$ for p in 21 22 80; do nc -zv -w2 web $p; done
nc: connect to web (192.168.60.10) port 21 (tcp) timed out: Operation now in progress
nc: connect to web (192.168.60.10) port 22 (tcp) timed out: Operation now in progress
Connection to web (192.168.60.10) 80 port [tcp/http] succeeded!
ana@admin:~$ nc -zv -w2 web 22; ssh web hostname
Connection to web (192.168.60.10) 22 port [tcp/ssh] succeeded!
web
ana@web:~$ sudo ss -Htln | awk '{print $4}' | wc -l
6
```

FTP e SSH agora esgotam o tempo a partir do `desk`; o portal responde. A partir do `admin`, o SSH
funciona. E no `web` nada mudou: o último comando conta seis listeners, exatamente como antes. Os
serviços continuam lá, inalcançáveis, e é por isso que a remoção da aula 1 e este filtro andam
juntos.

O contador no fim da chain mostra o que a policy descartou:

```
ana@web:~$ sudo nft list chain inet host input
table inet host {
	chain input {
		type filter hook input priority filter; policy drop;
		iif "lo" accept
		ct state established,related accept
		ct state invalid drop
		icmp type echo-request accept
		tcp dport 80 accept
		ip saddr { 192.168.60.30, 192.168.60.40 } tcp dport 22 accept
		counter packets 4 bytes 240
	}
}
```

Quatro pacotes de 60 bytes: uma tentativa de conexão na porta 21 e uma na 22, cada uma enviada duas
vezes, porque um cliente que não ouve nada tenta de novo antes de desistir.

## Descartar ou recusar

Um pacote descartado não recebe resposta, e o cliente espera até o próprio tempo limite:

```
ana@desk:~$ time nc -zv -w3 web 21
nc: connect to web (192.168.60.10) port 21 (tcp) timed out: Operation now in progress

real	0m3.006s
user	0m0.003s
sys	0m0.000s
```

Três segundos, o tempo limite que o `-w3` pediu. A alternativa é **recusar**: a máquina responde que
a porta está inalcançável, e o cliente desiste na hora. Troque a última linha por `counter reject` e
tente de novo:

```
ana@web:~$ sed "s/^\t\tcounter$/\t\tcounter reject/" nftables.conf > reject.conf && grep reject reject.conf && sudo nft -f reject.conf
		counter reject
ana@desk:~$ time nc -zv -w3 web 21
nc: connect to web (192.168.60.10) port 21 (tcp) failed: Connection refused

real	0m0.003s
user	0m0.000s
sys	0m0.003s
ana@desk:~$ sudo nmap -Pn -p 21,22,23,80,111 web | grep tcp
21/tcp  filtered ftp
22/tcp  filtered ssh
23/tcp  filtered telnet
80/tcp  open     http
111/tcp filtered rpcbind
```

O `nc` falha em três milissegundos com `Connection refused`, onde antes esperou três segundos. O `nmap`
continua chamando as portas de `filtered`, e o motivo vale saber: o `reject` manda uma mensagem ICMP
de *porta inalcançável*, e o `nmap` a lê como um firewall respondendo pela porta. Uma porta sem
listener e sem firewall responde com um reset de TCP, que o `nmap` informa como `closed`, como a
última varredura da aula 1 mostrou para UDP.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l05-drop-reject\" aria-label=\"A mesma tentativa de conexão na porta 21, respondida de dois jeitos, numa linha do tempo. Com drop, o desk manda um pedido de conexão, não ouve nada, manda de novo depois de um segundo e desiste quando acaba o próprio tempo limite de três segundos. Com reject, o desk manda um pedido, o web responde na hora com porta inalcançável, e o desk informa conexão recusada em milissegundos.\"><defs><marker id=\"l05-drop-reject-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l05-drop-reject-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">drop</text><path d=\"M120.0 80.0 L680.0 80.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">reject</text><path d=\"M120.0 180.0 L680.0 180.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M120.0 205.0 L120.0 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"120.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 s</text><path d=\"M306.7 205.0 L306.7 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"306.7\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 s</text><path d=\"M493.3 205.0 L493.3 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"493.3\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 s</text><path d=\"M680.0 205.0 L680.0 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"680.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 s</text><path d=\"M120.0 80.0 L120.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-drop-reject-dh-ah-paper-dim)\"></path><text x=\"124.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SYN</text><path d=\"M306.7 80.0 L306.7 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-drop-reject-dh-ah-paper-dim)\"></path><text x=\"310.7\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SYN</text><text x=\"676.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">tempo esgotado</text><text x=\"460.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">silêncio</text><path d=\"M120.0 180.0 L120.0 155.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-drop-reject-dh-ah-paper-dim)\"></path><text x=\"124.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SYN</text><path d=\"M134.0 150.0 L134.0 175.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l05-drop-reject-dh-ah-phosphor)\"></path><text x=\"144.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">porta inalcançável: recusada na hora</text></svg>", "caption": "O drop faz o cliente esperar o próprio tempo limite. O reject responde.", "same": ["0 s", "1 s", "2 s", "3 s"]}
```

| | o cliente vê | serve para |
|---|---|---|
| **descartar** | silêncio, depois o próprio tempo limite | um endereço que a internet alcança: uma varredura fica mais lenta e aprende menos |
| **recusar** | uma recusa imediata | uma rede interna, onde quem está depurando uma conexão merece uma resposta rápida e honesta |

Nenhum dos dois esconde a máquina: o portal continua aberto na 80, e um host que responde numa porta é
um host. No `web`, fica o descarte. A próxima seção faz isso sobreviver a um reboot.
