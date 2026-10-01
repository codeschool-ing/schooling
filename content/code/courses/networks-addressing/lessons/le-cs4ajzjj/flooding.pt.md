---
title: Um destino desconhecido vai para todo lado
version: 1
---

Um switch recebe um quadro para um endereço que não está na tabela. Ele não pode descartar o
quadro, porque o destino talvez exista e só não tenha falado ainda, e não pode escolher uma porta,
porque não conhece nenhuma. **Então ele manda o quadro por todas as portas, menos aquela por onde
chegou.** Isso se chama **inundação** (*flooding*), e é o switch se comportando, por um quadro,
exatamente como o hub da aula 1.

A captura abaixo mostra os dois casos lado a lado. A tabela foi esvaziada, e depois o pc1 pingou o
servidor uma vez para os dois serem aprendidos. Então o pc3 iniciou o tcpdump, filtrado para ICMP,
e o deixou rodando oito segundos enquanto o pc1 fazia duas coisas. Pingou o servidor mais duas
vezes, um destino que o switch conhece. Depois pingou 10.20.10.99, após ser informado à mão (`ip
neigh add`) de que esse endereço mora em `02:00:00:00:00:99`, um endereço MAC que nenhuma placa do
laboratório tem. O tcpdump imprimiu quando parou, por isso a saída dele vem depois dos pings:

```
ana@pc1:~$ ping -c 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 12.026/12.026/12.026/0.000 ms
ana@pc1:~$ ping -c 2 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.784/5.258/9.733/4.474 ms
root@pc1:~# ip neigh add 10.20.10.99 lladdr 02:00:00:00:00:99 dev eth0
ana@pc1:~$ ping -c 2 -W 1 -q 10.20.10.99
PING 10.20.10.99 (10.20.10.99) 56(84) bytes of data.

--- 10.20.10.99 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1066ms

root@pc3:~# timeout 8 tcpdump -n -e -i eth0 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:58:22.560076 02:25:70:bc:29:c6 > 02:00:00:00:00:99, ethertype IPv4 (0x0800), length 98: 10.20.10.21 > 10.20.10.99: ICMP echo request, id 79, seq 1, length 64
08:58:23.625757 02:25:70:bc:29:c6 > 02:00:00:00:00:99, ethertype IPv4 (0x0800), length 98: 10.20.10.21 > 10.20.10.99: ICMP echo request, id 79, seq 2, length 64

2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

**O pc3 viu dois quadros, e os dois são para `02:00:00:00:00:99`.** Os dois pings ao servidor, cuja
porta o switch conhecia, nem chegaram ao cabo do pc3, exatamente como na aula 1. Os dois pings ao
endereço inventado chegaram, porque o switch não tinha entrada para ele e inundou cada quadro por
todas as portas: para o pc3, para o pc2, para o servidor e para o roteador. Ninguém respondeu, e o
ping informa `100% packet loss`.

Agora a tabela:

```
root@sw1:~# bridge fdb show br br0 dynamic | grep -c .
2
root@sw1:~# bridge fdb show br br0 | grep 02:00:00:00:00:99
```

**Continuam duas entradas, e o endereço inventado não é uma delas.** O switch viu dois quadros
*para* `02:00:00:00:00:99` e não aprendeu nada com eles, porque aprende pelas origens e nenhum
quadro veio *desse* endereço. Então ele vai inundar cada quadro para ele enquanto alguém continuar
mandando.

## Quando a inundação é normal, e quando é sintoma

Quase toda inundação é breve e inofensiva. O primeiro quadro para uma máquina que não falou é
inundado, a máquina responde, a resposta ensina ao switch a porta dela, e todo quadro seguinte vai
para uma porta só. Numa rede em que todos falam com frequência, um destino desconhecido dura um
quadro.

Duas coisas a fazem durar mais, e as duas valem reconhecer:

- **Um destino que fica calado.** Um equipamento que recebe tráfego e não envia nada por mais
  tempo que o de envelhecimento sai da tabela, e o que é mandado para ele é inundado para todas as
  portas até ele falar de novo.
- **Uma tabela cheia.** Um switch sem espaço para um endereço novo inunda todo quadro para ele.
  Essa é a ameaça contra a qual a seção de segurança de porta se defende.

**Broadcasts são inundados de propósito**, e não por ignorância: um quadro para
`ff:ff:ff:ff:ff:ff` é para todos, e o switch o manda para todo lado porque é isso que ele pede. Até
onde vai esse "todo lado" é o domínio de broadcast, duas seções adiante.
