---
title: Por que os roteadores contam uns aos outros
version: 2
---

A aula 15 terminou com r3 mandando respostas na direção de um cabo que não existia mais, porque nada
conseguia avisá-lo. **Um protocolo de roteamento são roteadores contando uns aos outros o que
alcançam**, o tempo todo, para que uma mudança em qualquer lugar chegue a todas as tabelas. O
laboratório desta aula são quatro roteadores em anel, o formato que a aula 3 usou, com um PC atrás de r1
e outro atrás de r2:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O laboratório desta aula: quatro roteadores em anel. r1 e r2 se ligam por 10.20.0.0/30 (r1 10.20.0.1, r2 10.20.0.2); r2 e r3 por 10.20.0.4/30 (r2 10.20.0.5, r3 10.20.0.6); r3 e r4 por 10.20.0.8/30 (r3 10.20.0.9, r4 10.20.0.10); r4 e r1 por 10.20.0.12/30 (r4 10.20.0.13, r1 10.20.0.14). pc1, 10.20.1.10, está em 10.20.1.0/24 atrás de r1 em 10.20.1.1; pc2, 10.20.2.10, está em 10.20.2.0/24 atrás de r2 em 10.20.2.1.\"><defs><marker id=\"rg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"190\" y=\"60\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r1</text><text x=\"200\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 10.20.0.1</text><text x=\"200\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth4 10.20.0.14</text><text x=\"200\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 10.20.1.1</text><rect x=\"430\" y=\"60\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r2</text><text x=\"440\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 10.20.0.2</text><text x=\"440\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 10.20.0.5</text><text x=\"440\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 10.20.2.1</text><rect x=\"430\" y=\"210\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r3</text><text x=\"440\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 10.20.0.6</text><text x=\"440\" y=\"257\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth3 10.20.0.9</text><rect x=\"190\" y=\"210\" width=\"130\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r4</text><text x=\"200\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth3 10.20.0.10</text><text x=\"200\" y=\"257\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth4 10.20.0.13</text><rect x=\"20\" y=\"72\" width=\"110\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"30\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.10</text><rect x=\"590\" y=\"72\" width=\"110\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"600\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.2.10</text><path d=\"M130 95 L190 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M560 95 L590 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M320 95 L430 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M495 130 L495 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M320 245 L430 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M255 130 L255 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"375\" y=\"83\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.0.0/30</text><text x=\"505\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.0.4/30</text><text x=\"375\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.0.8/30</text><text x=\"245\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.0.12/30</text><text x=\"160\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><text x=\"645\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.2.0/24</text></svg>", "caption": "O laboratório desta aula: o anel da aula 3, sem protocolo de roteamento até que um seja digitado."}
```

É o anel da aula 3 sem protocolo de roteamento nenhum. Salve-o como `~/netlab/igp.sh` e monte com
`sudo bash ~/netlab/netlab.sh up igp`:

```bash
# ~/netlab/igp.sh: the ring of ring.sh with no routing protocol configured.
# FRR runs on every router with only its hostname, and the RIP, OSPF and
# EIGRP daemons are started, waiting for a configuration.
local n
for n in r1 r2 r3 r4; do node $n router; done
node pc1; node pc2
link r1 eth1 r2 eth1; addr r1 eth1 10.20.0.1/30;  addr r2 eth1 10.20.0.2/30
link r2 eth2 r3 eth2; addr r2 eth2 10.20.0.5/30;  addr r3 eth2 10.20.0.6/30
link r3 eth3 r4 eth3; addr r3 eth3 10.20.0.9/30;  addr r4 eth3 10.20.0.10/30
link r4 eth4 r1 eth4; addr r4 eth4 10.20.0.13/30; addr r1 eth4 10.20.0.14/30
link pc1 eth0 r1 eth0; addr pc1 eth0 10.20.1.10/24; addr r1 eth0 10.20.1.1/24; gw pc1 10.20.1.1
link pc2 eth0 r2 eth0; addr pc2 eth0 10.20.2.10/24; addr r2 eth0 10.20.2.1/24; gw pc2 10.20.2.1
for n in r1 r2 r3 r4; do echo "hostname $n" | FRR_EXTRA="ripd ospfd eigrpd" frr $n; done
```

A última linha sobe o FRR em cada roteador só com o nome dele, e com os daemons de RIP, OSPF e EIGRP
rodando, à espera da configuração que esta aula digita no `vtysh`.

Nada está configurado ainda além dos endereços. r1 conhece seus três cabos e mais nada, e pc1 não
alcança pc2:

```
root@r1:~# ip route
10.20.0.0/30 dev eth1 proto kernel scope link src 10.20.0.1 
10.20.0.12/30 dev eth4 proto kernel scope link src 10.20.0.14 
10.20.1.0/24 dev eth0 proto kernel scope link src 10.20.1.1 
ana@pc1:~$ ping -c 1 -W 1 10.20.2.10
PING 10.20.2.10 (10.20.2.10) 56(84) bytes of data.
From 10.20.1.1 icmp_seq=1 Destination Net Unreachable

--- 10.20.2.10 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 1ms

```

Daria para resolver isso com rotas estáticas. Conte o que custa: o anel tem seis redes, e cada roteador
precisa de uma rota para cada rede em que não está. r1 e r2 tocam três cada e precisam de três rotas cada;
r3 e r4 tocam duas cada e precisam de quatro cada. **Catorze rotas digitadas**, e cada uma aponta para um
lado do anel sem nenhuma ideia do que fazer quando um cabo falha. Acrescente um quinto roteador e você
visita todos de novo.

## Duas maneiras de contar

Os protocolos de roteamento dentro de uma organização se chamam **protocolos de gateway interior**, IGPs
(*interior gateway protocols*). Eles vêm em duas famílias, e a diferença é o que um roteador conta aos
vizinhos:

- *Vetor de distância.* Cada roteador conta aos vizinhos a própria tabela: *estas redes, a estas
  distâncias*. Um vizinho soma o custo do enlace entre os dois e fica com a melhor oferta. Ninguém vê a
  rede inteira; cada roteador confia no que o próximo diz. O **RIP** funciona assim.
- *Estado de enlace.* Cada roteador conta a *todos* os roteadores da área sobre os próprios enlaces:
  *sou r1, tenho um cabo até r2 e um até r4, e esta LAN*. Todo roteador junta o mesmo conjunto de
  descrições, desenha o mesmo mapa, e calcula os próprios caminhos mais curtos sobre ele. O **OSPF**
  funciona assim, e o IS-IS também, que grandes provedores usam e este curso não cobre.

O **EIGRP**, o terceiro protocolo aqui, é vetor de distância com contabilidade extra: ele lembra o que cada
vizinho ofereceu, e assim troca para uma reserva sem perguntar a ninguém.

## O que todos têm em comum

Cada protocolo primeiro encontra seus **vizinhos**, mandando pequenas mensagens de hello pelas interfaces
que mandaram usar, e só troca rotas com roteadores que respondem. Cada um põe suas melhores rotas na mesma
tabela do kernel que a aula 14 leu, marcadas com seu nome, `proto rip` ou `proto ospf`. Cada uma leva
também a **distância administrativa** que a aula 14 listou, para que um roteador rodando dois deles saiba em qual
rota acreditar: 120 para o RIP, 110 para o OSPF, e 90 para as rotas internas do EIGRP em equipamento Cisco.

A outra coisa que eles têm em comum é que são **interiores**. Eles supõem que todo roteador é operado
pelas mesmas pessoas e diz a verdade. Entre organizações, onde essa suposição falha, a internet usa o
BGP, que é a aula 17.

No laboratório, todo roteador roda o FRR, o mesmo software de roteamento que a aula 14 usou para mostrar
a distância administrativa, com todos os daemons de que esta aula precisa já iniciados e nada
configurado. Cada protocolo é digitado em r1 e mostrado ali; as mesmas linhas foram digitadas em r2, r3 e
r4 sem serem mostradas.
