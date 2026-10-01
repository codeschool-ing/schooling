---
title: Recusada ou filtrada
version: 1
---

"A conexão falhou" cobre duas situações bem diferentes, e a captura as separa nos primeiros dois
segundos. **Uma conexão recusada é uma resposta. Uma filtrada é um silêncio.**

Nas duas transcrições abaixo a captura rodou num segundo terminal, iniciada antes do `curl`; ela vem
em segundo lugar porque foi impressa quando terminou.

Nada escuta na porta 81 de `web1`:

```
ana@laptop:~$ curl -sS http://192.0.2.21:81/
curl: (7) Failed to connect to 192.0.2.21 port 81 after 0 ms: Couldn't connect to server
ana@laptop:~$ tshark -n -i eth0 -c 2 -f "host 192.0.2.21 and tcp port 81"
Capturing on 'eth0'
2 packets captured
    1 0.000000000 192.168.10.20 → 192.0.2.21   TCP 74 37486 → 81 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=1552613313 TSecr=0 WS=1024
    2 0.000072428   192.0.2.21 → 192.168.10.20 TCP 54 81 → 37486 [RST, ACK] Seq=1 Ack=1 Win=0 Len=0
```

O laptop mandou um SYN, e **72 microssegundos depois o próprio kernel de `web1` respondeu com RST,
ACK**: existe uma máquina neste endereço, ela recebeu o SYN, e nada escuta naquela porta. O `curl`
informou `Couldn't connect to server` `after 0 ms`. Uma conexão recusada é rápida, e prova que o
caminho da rede funciona até o host.

A porta 8080 de `web1` foi fechada de outro jeito: uma regra de firewall em `web1` descarta tudo o que
é mandado a ela, sem uma palavra.

```
ana@laptop:~$ curl -sS --max-time 5 http://192.0.2.21:8080/
curl: (28) Connection timed out after 5002 milliseconds
ana@laptop:~$ tshark -n -i eth0 -c 3 -f "host 192.0.2.21 and tcp port 8080"
Capturing on 'eth0'
3 packets captured
    1 0.000000000 192.168.10.20 → 192.0.2.21   TCP 74 53664 → 8080 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=3344973941 TSecr=0 WS=1024
    2 1.021559067 192.168.10.20 → 192.0.2.21   TCP 74 [TCP Retransmission] 53664 → 8080 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=3344974963 TSecr=0 WS=1024
    3 2.045518527 192.168.10.20 → 192.0.2.21   TCP 74 [TCP Retransmission] 53664 → 8080 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=3344975987 TSecr=0 WS=1024
```

**Nenhuma resposta, então o laptop tentou de novo**: o mesmo SYN, marcado `[TCP Retransmission]` pelo
Wireshark, um segundo depois do primeiro e de novo um segundo depois disso. A captura parou em três
pacotes; o laptop continuou tentando até o `curl` desistir em 5002 milissegundos, os cinco segundos que
o `--max-time 5` permitia. Sem esse limite o `curl` teria esperado muito mais, e a pessoa na frente
dele também.

| | recusada | filtrada |
|---|---|---|
| no fio | SYN, depois RST do host | SYN, depois o mesmo SYN de novo |
| com que rapidez | na hora | depois do timeout do próprio cliente |
| o `curl` diz | `Couldn't connect to server` | `Connection timed out` |
| o que prova | o host está no ar, a porta está fechada | algo descartou o SYN, ou a resposta dele |

**A segunda coluna não diz onde o pacote morreu.** Visto do cliente, o silêncio parece igual em quatro casos: um firewall no servidor descartou o SYN, um firewall no caminho o descartou, o servidor está desligado ou o SYN-ACK se perdeu na volta. A captura estreita a pergunta para "nenhuma resposta chegou aqui"; capturar na outra
ponta, como a aula 12 fez em `web1`, é o que diz se o SYN chegou. E um firewall pode ser configurado
para rejeitar em vez de descartar, respondendo com um reset próprio, e aí uma porta filtrada parece
recusada. Nada neste laboratório foi montado assim.
