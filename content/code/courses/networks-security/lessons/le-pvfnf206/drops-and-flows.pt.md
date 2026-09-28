---
title: Lendo descartes e fluxos
version: 1
---

Quatro pacotes foram recusados, então o log de descartes tem quatro linhas. Uma delas, inteira:

```
root@fw:~# wc -l /var/log/lab/drops.json
4 /var/log/lab/drops.json
root@fw:~# head -1 /var/log/lab/drops.json | jq .
{
  "timestamp": "2026-09-28T18:52:30.943369-0300",
  "dvc": "Netfilter",
  "raw.pktlen": 60,
  "raw.pktcount": 1,
  "oob.prefix": "forward-drop",
  "oob.time.sec": 1790632350,
  "oob.time.usec": 943369,
  "oob.mark": 0,
  "oob.ifindex_in": 1939,
  "oob.ifindex_out": 1945,
  "oob.hook": 2,
  "raw.mac_len": 14,
  "oob.family": 2,
  "oob.protocol": 2048,
  "raw.label": 0,
  "raw.type": 1,
  "raw.mac.addrlen": 6,
  "ip.protocol": 6,
  "ip.tos": 0,
  "ip.ttl": 63,
  "ip.totlen": 60,
  "ip.ihl": 5,
  "ip.csum": 2260,
  "ip.id": 37733,
  "ip.fragoff": 16384,
  "src_port": 43936,
  "dest_port": 5432,
  "tcp.seq": 2289721423,
  "tcp.ackseq": 0,
  "tcp.window": 64240,
  "tcp.offset": 0,
  "tcp.reserved": 0,
  "tcp.urg": 0,
  "tcp.ack": 0,
  "tcp.psh": 0,
  "tcp.rst": 0,
  "tcp.syn": 1,
  "tcp.fin": 0,
  "tcp.res1": 0,
  "tcp.res2": 0,
  "tcp.csum": 40881,
  "oob.in": "eth2",
  "oob.out": "eth3",
  "src_ip": "192.168.10.20",
  "dest_ip": "192.168.20.30"
}
```

A maioria desses campos descreve os cabeçalhos do pacote, e alguns carregam quase todo o sentido: a hora,
o prefixo que nomeia a regra, as interfaces por onde ele entrou e por onde teria saído, e os dois
endereços e portas. `tcp.syn` é 1 e `tcp.ack` é 0: é o primeiro pacote de uma conexão que nunca
aconteceu. As mesmas quatro linhas, reduzidas a esses campos:

```
root@fw:~# jq -c '[.timestamp, .src_ip, .dest_ip, .dest_port, ."oob.in", ."oob.out"]' /var/log/lab/drops.json
["2026-09-28T18:52:30.943369-0300","192.168.10.20","192.168.20.30",5432,"eth2","eth3"]
["2026-09-28T18:52:32.063164-0300","203.0.113.50","192.0.2.80",22,"eth0","eth1"]
["2026-09-28T18:52:33.066979-0300","203.0.113.50","192.0.2.53",22,"eth0","eth1"]
["2026-09-28T18:52:34.071430-0300","203.0.113.50","192.168.20.30",5432,"eth0","eth3"]
```

A primeira é o laptop tentando o banco de dados, o que a política nunca permitiu; as outras três são
`remote`, com um segundo de intervalo, em três portas e dois segmentos. **Um segundo de intervalo em
três portas é uma varredura (scan)**, por menor que seja.

Os registros de fluxo (flow records) são escritos depois, e essa é a primeira coisa a saber sobre eles.
O registro de uma conexão é escrito quando o firewall a **esquece**, não quando ela fecha: uma conexão
TCP fechada fica na tabela por dois minutos, e o kernel percebe que ela expirou até um minuto depois
disso. O script de captura esperou três minutos antes disto:

```
root@fw:~# wc -l /var/log/lab/flows.json
7 /var/log/lab/flows.json
root@fw:~# jq -c 'select(.src_ip == "203.0.113.50") | {start: ."flow.start.sec", end: ."flow.end.sec", src: .src_ip, dst: .dest_ip, dport: ."orig.l4.dport", sent: ."orig.raw.pktlen", received: ."reply.raw.pktlen"}' /var/log/lab/flows.json
{"start":1790632352,"end":1790632472,"src":"203.0.113.50","dst":"192.0.2.80","dport":80,"sent":402,"received":734}
{"start":1790632351,"end":1790632471,"src":"203.0.113.50","dst":"192.0.2.80","dport":80,"sent":398,"received":437}
```

Duas conversas de `remote` para a loja, ambas na porta 80, ambas permitidas. `start` e `end` estão em
segundos desde 1970: 1790632351 é 18:52:31 em São Paulo, e `end` é exatamente 120 segundos depois nas
duas, que são os dois minutos de memória e não a duração da conversa. As requisições em si levaram
milissegundos. `sent` e `received` são bytes em cada sentido; o segundo fluxo recebeu 734 bytes contra
os 437 do primeiro, porque uma página 404 é mais longa que a página inicial do laboratório.

**As tentativas recusadas não estão aqui.** Uma conexão que o firewall descarta nunca entra na tabela
como entrada confirmada, então nunca produz um registro de fluxo. Os fluxos dizem o que aconteceu; o
log de descartes diz o que foi barrado. Quem defende precisa dos dois, e nenhum contém o outro.

A pergunta que a aula 19 fez, quais pares de máquinas de fato usam uma regra, é uma contagem sobre
fluxos:

```
root@fw:~# jq -r '[.src_ip, .dest_ip, ."orig.l4.dport"] | @tsv' /var/log/lab/flows.json | sort | uniq -c | sort -rn
      3 192.0.2.80	192.168.20.10	8080
      2 203.0.113.50	192.0.2.80	80
      1 192.168.10.20	192.168.20.10	8080
      1 192.168.10.20	192.0.2.80	80
```

Três conversas do proxy para a aplicação, duas de `remote` para a loja, uma do laptop para cada. Em um
firewall real, uma semana disso por regra mostra os pares que a usam, e uma regra que permite um
segmento inteiro usado por duas máquinas é uma regra a estreitar.
