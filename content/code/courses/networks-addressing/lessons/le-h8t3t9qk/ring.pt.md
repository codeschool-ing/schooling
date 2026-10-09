---
title: Um anel de roteadores, e um corte
version: 2
---

O anel desta seção não é a volta compartilhada do Token Ring. São quatro roteadores, **cada um ligado
a exatamente dois vizinhos**, cada cabo um link separado com sua própria rede pequena, uma `/30` (a
aula 12 explica a conta de uma `/30`: dois endereços utilizáveis, um para cada ponta). O pc1 fica
atrás do r1 e o pc2 atrás do r2. É a forma que uma operadora usa em volta de uma cidade, e o ponto
dela é exatamente a propriedade que falta à estrela: **há dois caminhos de qualquer roteador para
qualquer outro**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"O cenário ring do laboratório. Quatro roteadores num quadrado: r1 em cima à esquerda, r2 em cima à direita, r3 embaixo à direita, r4 embaixo à esquerda, cada um ligado aos dois do lado, cada cabo com sua própria /30. O pc1 fica atrás do r1 e o pc2 atrás do r2. Antes do corte, o pc1 chega ao pc2 por r1 e r2. O cabo entre r1 e r2 é cortado, e o caminho passa a ser r1, r4 em 10.20.0.13, r3 em 10.20.0.9, r2 em 10.20.0.5.\"><rect x=\"120\" y=\"22\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"155.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><path d=\"M155.0 56 L155.0 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"380\" y=\"22\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"39.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><path d=\"M415.0 56 L415.0 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M190.0 137.0 L380.0 137.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"206.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.1</text><text x=\"364.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.2</text><text x=\"285.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">corte</text><path d=\"M279.0 129.0 L291.0 145.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M291.0 129.0 L279.0 145.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M415.0 154.0 L415.0 250.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"401.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.5</text><text x=\"401.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.6</text><path d=\"M380.0 267.0 L190.0 267.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"364.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.9</text><text x=\"206.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.10</text><path d=\"M155.0 250.0 L155.0 154.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"169.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.13</text><text x=\"169.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.14</text><rect x=\"120\" y=\"120\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"155.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><rect x=\"380\" y=\"120\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r2</text><rect x=\"380\" y=\"250\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r3</text><rect x=\"120\" y=\"250\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"155.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r4</text><rect x=\"520\" y=\"110\" width=\"188\" height=\"120\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"532\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">antes do corte</text><text x=\"532\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1, r2</text><text x=\"532\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">depois do corte</text><text x=\"532\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1, r4, r3, r2</text></svg>", "caption": "O anel da aula 3. Os números ao lado de cada cabo são o último byte do endereço naquela ponta, os mesmos que o traceroute imprime: 10.20.0.13 é o r4, 10.20.0.9 é o r3, 10.20.0.5 é o r2."}
```

Este anel é uma rede própria. Salve-o como `~/netlab/ring.sh`:

```bash
# ~/netlab/ring.sh: four routers in a ring, each cable its own /30, and a PC
# behind r1 and another behind r2. OSPF finds the paths, with a hello every
# second so a broken cable is noticed in four seconds instead of forty.
#
#        pc1    pc2        10.20.0.0/30  r1-r2      10.20.0.8/30   r3-r4
#         |      |         10.20.0.4/30  r2-r3      10.20.0.12/30  r4-r1
#   r4 -- r1 -- r2         10.20.1.0/24  behind r1  10.20.2.0/24   behind r2
#    |           |
#    +--- r3 ----+
local n
for n in r1 r2 r3 r4; do node $n router; done
node pc1; node pc2
link r1 eth1 r2 eth1; addr r1 eth1 10.20.0.1/30;  addr r2 eth1 10.20.0.2/30
link r2 eth2 r3 eth2; addr r2 eth2 10.20.0.5/30;  addr r3 eth2 10.20.0.6/30
link r3 eth3 r4 eth3; addr r3 eth3 10.20.0.9/30;  addr r4 eth3 10.20.0.10/30
link r4 eth4 r1 eth4; addr r4 eth4 10.20.0.13/30; addr r1 eth4 10.20.0.14/30
link pc1 eth0 r1 eth0; addr pc1 eth0 10.20.1.10/24; addr r1 eth0 10.20.1.1/24; gw pc1 10.20.1.1
link pc2 eth0 r2 eth0; addr pc2 eth0 10.20.2.10/24; addr r2 eth0 10.20.2.1/24; gw pc2 10.20.2.1
ospf_p2p r1 10.255.0.1 "eth1 eth4"; ospf_p2p r2 10.255.0.2 "eth1 eth2"
ospf_p2p r3 10.255.0.3 "eth2 eth3"; ospf_p2p r4 10.255.0.4 "eth3 eth4"
wait_for 90 ip netns exec pc1 ping -c1 -W1 10.20.2.10
```

`ospf_p2p` é a função do `netlab.sh` que escreve a configuração OSPF de um roteador, e a aula 16
explica cada linha dela. A última linha espera até o pc1 alcançar o pc2, porque o OSPF leva alguns
segundos para achar os caminhos. Monte com `sudo bash ~/netlab/netlab.sh up ring`.

O r1 mostra seus cabos. `eth0` é a rede do pc1; `eth1` e `eth4` são os dois vizinhos no anel:

```
root@r1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth1@if171       UP             10.20.0.1/30 fe80::a6:80ff:fe20:1354/64 
eth4@if178       UP             10.20.0.14/30 fe80::76:f0ff:fedf:fe66/64 
eth0@if180       UP             10.20.1.1/24 fe80::1f:23ff:fee7:e9d5/64 
```

`10.20.0.1/30` dá para o r2 e `10.20.0.14/30` dá para o r4. (O sufixo no estilo `@if171` é o
laboratório aparecendo: é o número da interface na outra ponta do cabo virtual.) Com todos os cabos
funcionando, o pc1 chega ao pc2 pelo caminho curto, passando por r1 e r2:

```
ana@pc1:~$ traceroute -n 10.20.2.10
traceroute to 10.20.2.10 (10.20.2.10), 30 hops max, 60 byte packets
 1  10.20.1.1  4.786 ms  0.316 ms  0.270 ms
 2  10.20.0.2  0.260 ms  0.224 ms  0.190 ms
 3  10.20.2.10  0.954 ms  0.251 ms  0.419 ms
```

Dois roteadores, depois o pc2. O salto 1 é o endereço do r1 na rede do pc1, e o salto 2 é a ponta do
r2 no cabo r1–r2.

## O corte

Agora o pc1 começa trinta pings, um a cada meio segundo, com `-q` para imprimir só o resumo. Enquanto
eles rodam, o cabo entre r1 e r2 é cortado — a ponta dele no r1 é desligada. O ping terminou depois do
corte, então o resumo dele aparece depois do comando que cortou o cabo:

```
root@r1:~# ip link set eth1 down
ana@pc1:~$ ping -c 30 -i 0.5 -q 10.20.2.10
PING 10.20.2.10 (10.20.2.10) 56(84) bytes of data.

--- 10.20.2.10 ping statistics ---
30 packets transmitted, 11 received, +3 errors, 63.3333% packet loss, time 14590ms
rtt min/avg/max/mdev = 0.627/1.016/1.236/0.188 ms
```

**Voltaram 11 de 30**, uma perda de 63,3333% numa execução de 14590 ms. Os 19 perdidos saíram
enquanto a rede ainda decidia para onde o pc2 tinha ido; a dois pings por segundo, são uns nove
segundos e meio sem caminho, neste laboratório. `+3 errors` conta mensagens de erro ICMP que voltaram
no lugar de um eco: enquanto as rotas mudavam, um roteador respondeu que não tinha caminho até o pc2.
Depois o anel se recuperou sozinho, e ninguém mexeu no pc1, no pc2 ou numa tabela de rotas.

Quem mexeu? O traceroute depois do corte responde uma parte:

```
ana@pc1:~$ traceroute -n 10.20.2.10
traceroute to 10.20.2.10 (10.20.2.10), 30 hops max, 60 byte packets
 1  10.20.1.1  0.832 ms  0.361 ms  0.125 ms
 2  10.20.0.13  0.286 ms  0.235 ms  0.155 ms
 3  10.20.0.9  0.382 ms  0.162 ms  0.175 ms
 4  10.20.0.5  0.263 ms  0.203 ms  0.388 ms
 5  10.20.2.10  0.248 ms  0.414 ms  0.218 ms
root@r1:~# ip route show 10.20.2.0/24
10.20.2.0/24 nhid 22 via 10.20.0.13 dev eth4 proto ospf metric 20 
```

**Os pacotes agora dão a volta comprida**: r1, depois `10.20.0.13` (r4), `10.20.0.9` (r3) e
`10.20.0.5` (r2) — quatro roteadores em vez de dois. A figura acima tem esses endereços na ponta de
cada cabo. A rota no r1 diz o resto: `proto ospf` quer dizer que o protocolo de roteamento **OSPF** a
escreveu, apontando para o r4 pela `eth4`. Os roteadores ficam contando uns aos outros quais cabos
estão de pé, e quando um caiu eles calcularam o caminho pelo outro lado. A aula 16 explica como, e por
que levou os segundos que levou; este laboratório encurta os temporizadores do OSPF para um hello por
segundo, para que uma quebra seja percebida rápido.

## O que um anel compra e o que custa

- **Ele sobrevive a um corte.** Qualquer cabo pode falhar e todo roteador ainda alcança todos os
  outros.
- **Ele não sobrevive a dois.** Corte um segundo cabo em qualquer lugar e o anel vira duas correntes
  separadas; roteadores em lados opostos se perdem.
- **O desvio pode ser longo.** Num anel de quatro, um corte pode transformar um salto em três. Num
  anel de vinte roteadores, a volta depois de um corte pode atravessar dezenove cabos.
- **Ele custa um cabo por roteador**, o arranjo mais barato que tem algum segundo caminho.

Esse último ponto é por que as operadoras gostam de anéis para a fibra metropolitana: uma volta de
fibra em torno de uma cidade, e cada prédio nela tem duas saídas. A próxima seção acrescenta dois
cabos a este mesmo anel e corta o mesmo cabo.
