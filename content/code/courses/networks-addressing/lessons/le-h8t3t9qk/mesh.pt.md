---
title: A malha, e quanto custa contar
version: 2
---

Uma **malha completa** tem um cabo entre cada par de aparelhos. Pegue o anel da seção anterior e
acrescente as duas diagonais, r1 a r3 e r2 a r4, e quatro roteadores viram uma malha completa: cada
um tem um cabo até cada um dos outros três.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"O cenário mesh do laboratório: os mesmos quatro roteadores num quadrado, mais as duas diagonais, r1 a r3 em 10.20.0.16/30 e r2 a r4 em 10.20.0.20/30. O cabo entre r1 e r2 é cortado, e o caminho passa a ser r1, r3 em 10.20.0.18, r2 em 10.20.0.5.\"><rect x=\"120\" y=\"22\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"155.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><path d=\"M155.0 56 L155.0 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"380\" y=\"22\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><path d=\"M415.0 56 L415.0 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M190.0 137.0 L380.0 137.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"206.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.1</text><text x=\"364.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.2</text><text x=\"285.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">corte</text><path d=\"M279.0 129.0 L291.0 145.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M291.0 129.0 L279.0 145.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M415.0 154.0 L415.0 250.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"401.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.5</text><text x=\"401.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.6</text><path d=\"M380.0 267.0 L190.0 267.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"364.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.9</text><text x=\"206.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.10</text><path d=\"M155.0 250.0 L155.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"169.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.13</text><text x=\"169.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.14</text><path d=\"M189.0 154.0 L381.0 250.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"235.1\" y=\"164.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.17</text><text x=\"344.8\" y=\"219.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.18</text><path d=\"M381.0 154.0 L189.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"344.8\" y=\"184.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.21</text><text x=\"235.1\" y=\"239.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.22</text><rect x=\"120\" y=\"120\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"155.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><rect x=\"380\" y=\"120\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r2</text><rect x=\"380\" y=\"250\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r3</text><rect x=\"120\" y=\"250\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"155.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r4</text><rect x=\"520\" y=\"110\" width=\"188\" height=\"120\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"532\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">antes do corte</text><text x=\"532\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1, r2</text><text x=\"532\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">depois do corte</text><text x=\"532\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1, r3, r2</text></svg>", "caption": "O mesmo anel com as duas diagonais: seis cabos, um entre cada par de quatro roteadores. Depois do mesmo corte, o desvio pega a diagonal até o r3, um roteador a menos do que o anel precisou."}
```

A malha é o arquivo do anel com as duas diagonais a mais, e OSPF nelas também. Salve-a como
`~/netlab/mesh.sh` e monte com `sudo bash ~/netlab/netlab.sh up mesh`:

```bash
# ~/netlab/mesh.sh: the ring of ring.sh with its two diagonals added, so every
# router has a cable to every other one: 10.20.0.16/30 joins r1 and r3, and
# 10.20.0.20/30 joins r2 and r4.
local n
for n in r1 r2 r3 r4; do node $n router; done
node pc1; node pc2
link r1 eth1 r2 eth1; addr r1 eth1 10.20.0.1/30;  addr r2 eth1 10.20.0.2/30
link r2 eth2 r3 eth2; addr r2 eth2 10.20.0.5/30;  addr r3 eth2 10.20.0.6/30
link r3 eth3 r4 eth3; addr r3 eth3 10.20.0.9/30;  addr r4 eth3 10.20.0.10/30
link r4 eth4 r1 eth4; addr r4 eth4 10.20.0.13/30; addr r1 eth4 10.20.0.14/30
link pc1 eth0 r1 eth0; addr pc1 eth0 10.20.1.10/24; addr r1 eth0 10.20.1.1/24; gw pc1 10.20.1.1
link pc2 eth0 r2 eth0; addr pc2 eth0 10.20.2.10/24; addr r2 eth0 10.20.2.1/24; gw pc2 10.20.2.1
link r1 eth5 r3 eth5; addr r1 eth5 10.20.0.17/30; addr r3 eth5 10.20.0.18/30
link r2 eth6 r4 eth6; addr r2 eth6 10.20.0.21/30; addr r4 eth6 10.20.0.22/30
ospf_p2p r1 10.255.0.1 "eth1 eth4 eth5"; ospf_p2p r2 10.255.0.2 "eth1 eth2 eth6"
ospf_p2p r3 10.255.0.3 "eth2 eth3 eth5"; ospf_p2p r4 10.255.0.4 "eth3 eth4 eth6"
wait_for 90 ip netns exec pc1 ping -c1 -W1 10.20.2.10
```

O r1 agora tem três cabos para a rede em vez de dois. O novo é a `eth5`, na diagonal até o r3:

```
root@r1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth1@if183       UP             10.20.0.1/30 fe80::a6:80ff:fe20:1354/64 
eth4@if190       UP             10.20.0.14/30 fe80::76:f0ff:fedf:fe66/64 
eth0@if192       UP             10.20.1.1/24 fe80::1f:23ff:fee7:e9d5/64 
eth5@if195       UP             10.20.0.17/30 fe80::7:c2ff:fe64:4ef/64 
```

Com tudo funcionando, nada muda para o pc1. O cabo direto até o r2 continua sendo o caminho mais
curto:

```
ana@pc1:~$ traceroute -n 10.20.2.10
traceroute to 10.20.2.10 (10.20.2.10), 30 hops max, 60 byte packets
 1  10.20.1.1  4.085 ms  0.335 ms  0.432 ms
 2  10.20.0.2  0.297 ms  0.538 ms  0.280 ms
 3  10.20.2.10  1.310 ms  0.324 ms  0.398 ms
```

Depois, o mesmo experimento do anel: trinta pings, um a cada meio segundo, e o mesmo cabo cortado,
r1 a r2, enquanto eles rodam.

```
root@r1:~# ip link set eth1 down
ana@pc1:~$ ping -c 30 -i 0.5 -q 10.20.2.10
PING 10.20.2.10 (10.20.2.10) 56(84) bytes of data.

--- 10.20.2.10 ping statistics ---
30 packets transmitted, 27 received, 10% packet loss, time 14574ms
rtt min/avg/max/mdev = 0.555/1.138/2.445/0.382 ms
```

**Voltaram 27 de 30: 10% de perda, três pings.** O anel perdeu 19 com o mesmo corte. E o caminho novo
é mais curto que o desvio do anel:

```
ana@pc1:~$ traceroute -n 10.20.2.10
traceroute to 10.20.2.10 (10.20.2.10), 30 hops max, 60 byte packets
 1  10.20.1.1  0.952 ms  0.202 ms  0.171 ms
 2  10.20.0.18  0.321 ms  0.218 ms  0.145 ms
 3  10.20.0.5  0.365 ms  0.284 ms  0.211 ms
 4  10.20.2.10  0.338 ms  0.442 ms  0.232 ms
```

r1, depois `10.20.0.18` — o r3, alcançado pela diagonal — depois o r2 em `10.20.0.5`. **Três
roteadores em vez dos quatro do anel**, porque a malha tinha um cabo que já fazia a maior parte do
caminho.

Cuidado com a comparação. Cada cenário rodou uma vez, e quantos pings um corte custa depende de quão
rápido os roteadores percebem e recalculam, que é o assunto da aula 16 e que este laboratório acelera
de propósito. O que as duas execuções mostram de forma confiável é a forma: **uma malha tem mais
caminhos alternativos, e o desvio é mais curto**. Nesta malha de quatro roteadores, quaisquer dois
cabos podem falhar e todo roteador ainda alcança todos os outros, enquanto o anel se partiu com dois
cortes.

## Contando cabos

O preço da malha é cabo, e ele cresce mais rápido do que as pessoas esperam. Cada um dos *n*
aparelhos precisa de um cabo até cada um dos outros *n − 1*, e cada cabo liga dois aparelhos, então
uma malha completa precisa de

**n × (n − 1) / 2 cabos.**

| aparelhos | cabos numa malha completa | cabos num anel |
|---|---|---|
| 4 | 6 | 4 |
| 10 | 45 | 10 |
| 50 | 1225 | 50 |

Quatro roteadores são os seis do laboratório. Dez são 45, o que já é um armário que ninguém quer
etiquetar. Cinquenta são 1.225 cabos, e cada roteador precisaria de 49 portas para eles. Acrescentar o
quinquagésimo primeiro aparelho quer dizer cinquenta cabos novos, um até cada aparelho que já estava
lá.

Então ninguém monta uma malha completa num escritório. **Uma malha parcial** é o que as redes reais
usam: uma malha entre os poucos aparelhos cuja falha prejudicaria todo mundo — os roteadores do
núcleo, os links entre data centers — e algo mais barato em todo o resto. Uma malha completa aparece
onde a conta é pequena e o risco é alto: dois ou três roteadores de núcleo, ou um punhado de sedes
ligadas por túneis, o tipo de link que a aula 4 monta.

Há um segundo custo, mais discreto. Com mais caminhos, os roteadores têm mais a calcular e você tem
mais a ler: a tabela de rotas de uma malha é mais difícil de prever de olho, e um defeito num caminho
reserva pode ficar escondido até o dia em que ele for necessário. A aula 6 dá nome a isso:
redundância que nunca foi testada.
