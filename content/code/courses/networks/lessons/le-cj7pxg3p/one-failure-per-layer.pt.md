---
title: Quatro falhas, quatro mensagens
version: 1
---

O modelo mostra o seu valor quando algo quebra, porque **cada camada falha com a sua mensagem**. O
laptop foi quebrado quatro vezes, uma por camada, e vale a pena reconhecer cada mensagem de relance.

Camadas 1 e 2, o enlace. Derrubar a interface é o que um cabo desconectado parece para o sistema:

```
ana@laptop:~$ sudo ip link set eth0 down
ana@laptop:~$ ping -c 2 192.0.2.80
ping: connect: Network is unreachable
ana@laptop:~$ ip -br link show eth0
eth0@if107       DOWN           52:54:00:a8:0a:14 <BROADCAST,MULTICAST> 
```

O `Network is unreachable` voltou na hora, sem nenhum pacote enviado: sem enlace não há rota, e o
sistema sabe que não tem para onde mandar nada. O `LOWER_UP` sumiu das flags.

Camadas 2 e 3, o vizinho. `192.168.10.99` está dentro do `/24` do escritório, então o laptop tenta
ARP, e ninguém responde:

```
ana@laptop:~$ ping -c 2 192.168.10.99
PING 192.168.10.99 (192.168.10.99) 56(84) bytes of data.
From 192.168.10.20 icmp_seq=1 Destination Host Unreachable
From 192.168.10.20 icmp_seq=2 Destination Host Unreachable

--- 192.168.10.99 ping statistics ---
2 packets transmitted, 0 received, +2 errors, 100% packet loss, time 1014ms
pipe 2
```

`Destination Host Unreachable` **vindo do próprio endereço do laptop**, `192.168.10.20`: o laptop está
avisando que a própria pergunta de ARP ficou sem resposta. A máquina está desligada, desconectada ou
não existe.

Camada 4, a porta. A rota funciona e o servidor está de pé, mas nada escuta na 8080:

```
ana@laptop:~$ curl -sS http://www.example.com:8080/
curl: (7) Failed to connect to www.example.com port 8080 after 6 ms: Couldn't connect to server
```

Camada 7, o nome. Um erro de digitação, `ww` no lugar de `www`:

```
ana@laptop:~$ curl -sS https://ww.example.com/
curl: (6) Could not resolve host: ww.example.com
```

Nada foi enviado a servidor web nenhum: o nome nunca virou endereço. E mais uma, em que **todas as
camadas funcionaram** e a resposta ainda assim foi não:

```
ana@laptop:~$ curl -sI https://www.example.com/prices
HTTP/2 404 
server: nginx/1.24.0 (Ubuntu)
date: Fri, 25 Sep 2026 16:06:01 GMT
content-type: text/html
content-length: 162
```

| mensagem | camada | onde olhar |
|---|---|---|
| `Network is unreachable` | 1 a 3, esta máquina | o cabo, o Wi-Fi, o endereço, a rota |
| `Destination Host Unreachable` vindo de você mesmo | 2 e 3, o enlace | a outra máquina está desligada ou não existe |
| `Connection refused` | 4, a outra máquina | o serviço não está rodando, ou está em outra porta |
| um timeout, nenhuma resposta | 3 ou 4, no caminho | um firewall, aula 3 |
| `Could not resolve host` | 7, DNS | o nome, ou o servidor de DNS, aula 4 |
| `404`, `500` e outros códigos HTTP | 7, a aplicação | o próprio site: a rede está bem |

**A última linha é a que mais economiza tempo.** Um erro HTTP quer dizer que o caminho inteiro
funcionou, e reiniciar o roteador não conserta uma página que não existe.
