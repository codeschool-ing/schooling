---
title: Uma marcação é um pedido, não um serviço
version: 1
---

O primeiro passo, reconhecer o que importa, é mais fácil se o próprio pacote disser. Todo cabeçalho IPv4
tem um byte para isso, o segundo, que o `tcpdump` ainda chama de `tos`, type of service. **Os seis bits
de cima são o DSCP, Differentiated Services Code Point, e dão nome a uma classe**; os dois de baixo são da
notificação de congestionamento (ECN) e ficam de fora aqui.

Alguns valores são combinados no mercado inteiro, que é a razão de existir um código:

| nome | DSCP | o byte inteiro | para |
|---|---|---|---|
| EF, expedited forwarding | 46 | `0xb8` | voz |
| AF41 | 34 | `0x88` | vídeo interativo |
| CS6 | 48 | `0xc0` | protocolos de roteamento |
| CS0, padrão | 0 | `0x00` | todo o resto, melhor esforço |

A terceira coluna é a que as ferramentas imprimem, porque mostram o byte inteiro. Deslocar seis bits
duas casas para a esquerda multiplica por quatro: **46 × 4 = 184, que é `0xb8`**. O `ping -Q` também
recebe o byte inteiro, então um ping que pede para ser tratado como voz é `ping -Q 0xb8`. Eis um,
`ping -c 1 -Q 0xb8 192.0.2.21` em `laptop`, capturado do lado do provedor, no uplink de `hq`:

```
ana@isp:~$ sudo tcpdump -n -v -i eth0 -c 2 icmp
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
18:13:11.065092 IP (tos 0xb8, ttl 63, id 8227, offset 0, flags [DF], proto ICMP (1), length 84)
    203.0.113.2 > 192.0.2.21: ICMP echo request, id 45272, seq 1, length 64
18:13:11.065115 IP (tos 0xb8, ttl 63, id 10711, offset 0, flags [none], proto ICMP (1), length 84)
    192.0.2.21 > 203.0.113.2: ICMP echo reply, id 45272, seq 1, length 64
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

`tos 0xb8` no pedido, então a marcação atravessou `hq` intacta, e o NAT, que reescreveu a origem para
`203.0.113.2`, não mexeu nela. A resposta também leva `0xb8`, porque o Linux copia o byte de um echo
request na resposta. **Nada no caminho fez nada com ela.** O roteador do provedor leu o byte, imprimiu e
encaminhou o pacote exatamente como encaminha qualquer outro.

## Uma marcação sem fila por trás

O que a marcação compra no uplink congestionado da seção anterior, onde ainda há uma fila só para tudo?
Este ping rodou durante o mesmo upload, alguns segundos depois do que ia sem marcação:

```
ana@laptop:~$ ping -c 5 -q -Q 0xb8 192.0.2.21 | tail -n 1
rtt min/avg/max/mdev = 0.055/20.045/26.474/10.067 ms
```

A pior resposta levou 26 ms, que é a mesma fila de antes. Uma das cinco voltou em 0,055 ms, então
encontrou a fila vazia por um instante, e o upload já a tinha enchido de novo na seguinte. As médias, 20 ms
com marcação contra 65 ms sem, parecem uma diferença e não são. O ping sem marcação começou dois segundos
depois do início do upload e pegou uma resposta de 221 ms, num momento em que a fila estava quase cheia.
Uma média vezes cinco é a soma, então as outras quatro respostas sem marcação ficaram em (5 × 65,122 −
221,652) ÷ 4, uns **26 ms**, e as quatro lentas com marcação em (5 × 20,045 − 0,055) ÷ 4, uns **25 ms**.

**Uma marcação é um rótulo, e um rótulo não faz nada até que algo seja configurado para lê-lo.** Um
roteador com uma fila só envia os pacotes na ordem em que chegaram, diga o que disserem sobre si mesmos. A
marcação é um pedido, e a próxima seção monta a fila que o atende.
