---
title: O que qualquer um num segmento consegue ouvir
version: 1
---

**Sniffing** é ler o tráfego que passa por uma interface de rede, inclusive o tráfego endereçado a
outras máquinas. Quem defende faz isso o tempo todo: um sensor de detecção de intrusão (aula 14) não
faz outra coisa. Qualquer outro que consiga isso no mesmo segmento lê exatamente o que o sensor lê,
então a pergunta que vale fazer é **o que há ali para ler**.

No seu laboratório esta aula começa com `sudo bash nslab.sh reset`, com a política da empresa
carregada no `fw` por `nft -f baseline.nft`. O laboratório tem um sensor ligado à DMZ, sem
endereço próprio:

```
root@sensor:~# ip -br addr show eth0
eth0@if70        UP             
```

`UP` e nenhum endereço. Ele escuta e nunca fala, que é como um sensor deve ser conectado. Agora um
cliente na internet pede uma página à loja por **HTTP puro**, levando um cookie de sessão, e o sensor
registra o segmento. Cada gravação desta aula é iniciada no `sensor`, como root, um instante antes de
o cliente agir, e para sozinha depois de oito segundos; o filtro no fim é o tráfego que ela guarda.
Esta é `http.pcap` com `tcp port 80`; as seguintes são `dns.pcap` com `udp port 53` e `tls.pcap` com
`tcp port 443`:

```sh
setsid timeout 8 tcpdump -i eth0 -s0 -w /root/http.pcap tcp port 80 </dev/null >/dev/null 2>&1 &
```

```
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" -b "session=7f3a9c2e" http://www.example.com/orders
404
root@sensor:~# tcpdump -r http.pcap -n -A 2>/dev/null | grep -aoE "GET /[^ ]* HTTP/1.1|Host: .*|User-Agent: .*|Cookie: .*" | uniq
GET /orders HTTP/1.1
Host: www.example.com
User-Agent: curl/8.5.0
Cookie: session=7f3a9c2e
```

A página é um `404`; isso não importa. **Tudo o que o cliente enviou está legível**: qual página, em
qual site, com qual programa, e o cookie de sessão que prova à aplicação quem o cliente é. Qualquer
um que consiga ler o segmento pode copiar esse cookie, e a última seção desta aula diz quanto isso
vale para ele.

O DNS também é texto puro:

```
ana@remote:~$ dig +short @192.0.2.53 www.example.com
192.0.2.80
root@sensor:~# tcpdump -r dns.pcap -n 2>/dev/null | cut -d" " -f2-
IP 203.0.113.50.60300 > 192.0.2.53.53: 45084+ [1au] A? www.example.com. (56)
IP 192.0.2.53.53 > 203.0.113.50.60300: 45084* 1/0/1 A 192.0.2.80 (60)
```

A pergunta e a resposta, por inteiro: quem perguntou, por qual nome e que endereço voltou. Agora a
mesma requisição à loja, por HTTPS, registrada do mesmo jeito:

```
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" -b "session=7f3a9c2e" https://www.example.com/orders
404
root@sensor:~# tcpdump -r tls.pcap -n -A 2>/dev/null | grep -caE "GET /|Cookie: "
0
root@sensor:~# tcpdump -r tls.pcap -n 2>/dev/null | wc -l
17
```

Dezessete pacotes atravessaram o segmento, e **nenhum deles contém a requisição ou o cookie** de
nenhuma forma que alguém lendo o segmento possa usar. Os nomes e os tamanhos ainda aparecem, que são
os metadados da aula 2; o que foi dito, não.

**A defesa contra o sniffing não é impedi-lo, coisa que ninguém pode prometer em todo segmento. É
garantir que não haja nada que valha a pena ler.** Anote todo protocolo da empresa que ainda leva uma
senha, um cookie ou um documento em claro. As próximas seções desta aula tratam de como um atacante
entra num segmento que não era para ele ouvir.
