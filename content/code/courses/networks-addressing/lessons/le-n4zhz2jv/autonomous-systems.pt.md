---
title: Sistemas autônomos e seus números
version: 2
---

Os protocolos da aula 16 supõem que todo roteador é operado pelas mesmas pessoas. A internet é o caso
oposto: **dezenas de milhares de redes, cada uma operada por sua própria organização**, cada uma decidindo
por si o que transportar e para quem. Cada uma é um **sistema autônomo** (AS, *autonomous system*): um
conjunto de roteadores sob uma administração, com uma política de roteamento em relação ao resto do mundo.

Dentro de um AS você roda um IGP, OSPF ou IS-IS, e tem a convergência rápida e confiante da aula 16.
**Entre ASes você roda o BGP** (*Border Gateway Protocol*, versão 4, RFC 4271), que transporta
alcançabilidade e, acima de tudo, política: não só *eu alcanço isto*, mas *e é para estes que eu
transporto*.

## Números de AS

Cada AS é identificado por um **número de AS** (ASN). Eles tinham 16 bits, de 1 a 65535, ficaram escassos,
e foram estendidos para 32 bits; os dois tipos estão em uso hoje. Algumas faixas são reservadas:

| faixa | para que serve |
|---|---|
| 64496 a 64511 | documentação, para exemplos e laboratórios como este |
| 64512 a 65534 | uso privado, dentro de uma organização, nunca anunciado na internet |
| 4200000000 a 4294967294 | uso privado, o equivalente em 32 bits |

Um ASN público é atribuído por um registro regional de internet, o LACNIC para a América Latina, que no
Brasil atribui por meio do NIC.br. Uma organização precisa de um quando quer seu próprio bloco de endereços
alcançável por mais de um provedor, que é o caso da empresa deste laboratório.

## O laboratório

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"O laboratório desta aula, em três sistemas autônomos. A empresa, AS 64500, tem 203.0.113.0/24: www em 203.0.113.10 atrás do roteador edge, cujas outras duas interfaces são 192.0.2.1 e 192.0.2.5. O provedor A, AS 64501, opera ispa, ligado a edge por 192.0.2.0/30 (ispa é 192.0.2.2) e servindo a1, 198.51.100.10, em 198.51.100.0/25. O provedor B, AS 64502, opera ispb, ligado a edge por 192.0.2.4/30 (ispb é 192.0.2.6) e servindo b1, 198.51.100.130, em 198.51.100.128/25. ispa e ispb também se ligam um ao outro por 192.0.2.8/30, em 192.0.2.9 e 192.0.2.10.\"><defs><marker id=\"bt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M220 10 L500 10 L500 182 L220 182 L220 10\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"232\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">AS 64500</text><text x=\"310\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a empresa</text><path d=\"M10 230 L310 230 L310 410 L10 410 L10 230\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"22\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">AS 64501</text><text x=\"100\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">provedor A</text><path d=\"M410 230 L710 230 L710 410 L410 410 L410 230\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"422\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">AS 64502</text><text x=\"500\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">provedor B</text><rect x=\"300\" y=\"40\" width=\"120\" height=\"41\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><text x=\"310\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.10</text><rect x=\"290\" y=\"104\" width=\"140\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">edge</text><text x=\"300\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 192.0.2.1</text><text x=\"300\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 192.0.2.5</text><path d=\"M360 81 L360 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"40\" y=\"262\" width=\"160\" height=\"71\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ispa</text><text x=\"50\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 192.0.2.2</text><text x=\"50\" y=\"309\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 192.0.2.9</text><text x=\"50\" y=\"324\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 198.51.100.1</text><rect x=\"40\" y=\"358\" width=\"160\" height=\"41\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"372\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a1</text><text x=\"50\" y=\"390\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.10</text><path d=\"M120 333 L120 358\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"212\" y=\"380\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.0/25</text><rect x=\"520\" y=\"262\" width=\"160\" height=\"71\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ispb</text><text x=\"530\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth0 192.0.2.6</text><text x=\"530\" y=\"309\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth1 192.0.2.10</text><text x=\"530\" y=\"324\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eth2 198.51.100.129</text><rect x=\"520\" y=\"358\" width=\"160\" height=\"41\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"372\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">b1</text><text x=\"530\" y=\"390\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.130</text><path d=\"M600 333 L600 358\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"508\" y=\"380\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.128/25</text><path d=\"M310 167 L160 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"214\" y=\"205\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.0/30</text><path d=\"M410 167 L560 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"506\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.4/30</text><path d=\"M200 297 L520 297\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.8/30</text></svg>", "caption": "O laboratório desta aula. Cada linha tracejada é um sistema autônomo; cada cabo que cruza uma delas leva uma sessão eBGP."}
```

Salve-o como `~/netlab/bgp.sh` e monte com `sudo bash ~/netlab/netlab.sh up bgp`:

```bash
# ~/netlab/bgp.sh: a company with its own block, 203.0.113.0/24, and its own
# autonomous system, 64500, connected to two providers that also peer with
# each other. The providers are configured here; the company's router, edge,
# starts with nothing.
#
#            www 203.0.113.10
#                 |
#               edge (AS 64500)
#              /              \
#   192.0.2.0/30              192.0.2.4/30
#            /                  \
#   ispa (AS 64501) --------- ispb (AS 64502)
#        |         192.0.2.8/30      |
#   a1 198.51.100.10          b1 198.51.100.130
#   (198.51.100.0/25)         (198.51.100.128/25)
isp_bgp() {  # isp_bgp NODE ASN OWN-PREFIX ROUTER-ID CUSTOMER PEER PEER-ASN
  frr "$1" <<CONF
hostname $1
ip prefix-list CUSTOMER seq 5 permit 203.0.113.0/24
route-map FROM-CUSTOMER permit 10
 match ip address prefix-list CUSTOMER
route-map ANY permit 10
router bgp $2
 bgp router-id $4
 neighbor $5 remote-as 64500
 neighbor $6 remote-as $7
 address-family ipv4 unicast
  network $3
  neighbor $5 route-map FROM-CUSTOMER in
  neighbor $5 route-map ANY out
  neighbor $6 route-map ANY in
  neighbor $6 route-map ANY out
 exit-address-family
CONF
}
node www; node a1; node b1
node edge router; node ispa router; node ispb router
link www eth0 edge eth0;  addr www eth0 203.0.113.10/24; addr edge eth0 203.0.113.1/24; gw www 203.0.113.1
link edge eth1 ispa eth0; addr edge eth1 192.0.2.1/30; addr ispa eth0 192.0.2.2/30
link edge eth2 ispb eth0; addr edge eth2 192.0.2.5/30; addr ispb eth0 192.0.2.6/30
link ispa eth1 ispb eth1; addr ispa eth1 192.0.2.9/30; addr ispb eth1 192.0.2.10/30
link a1 eth0 ispa eth2;   addr a1 eth0 198.51.100.10/25;  addr ispa eth2 198.51.100.1/25;   gw a1 198.51.100.1
link b1 eth0 ispb eth2;   addr b1 eth0 198.51.100.130/25; addr ispb eth2 198.51.100.129/25; gw b1 198.51.100.129
isp_bgp ispa 64501 198.51.100.0/25   192.0.2.2 192.0.2.1 192.0.2.10 64502
isp_bgp ispb 64502 198.51.100.128/25 192.0.2.6 192.0.2.5 192.0.2.9  64501
echo "hostname edge" | FRR_EXTRA=bgpd frr edge
```

`isp_bgp` escreve a configuração do FRR de um provedor: o bloco dele, uma sessão com o cliente cujas
rotas de entrada passam pelo route map `FROM-CUSTOMER`, e uma sessão com o outro provedor. A seção sobre
vazamentos de rota volta a esse route map. O edge, o roteador da empresa, sobe com o BGP rodando e nada
configurado, porque esta aula digita a configuração dele.

A empresa, AS 64500, tem o bloco `203.0.113.0/24` com um servidor web nele. Seu roteador, `edge`, está
ligado a dois provedores, ispa no AS 64501 e ispb no AS 64502, que também se ligam um ao outro e servem
cada um uma rede de clientes própria, com um host, a1 e b1. Todo ASN e todo endereço vêm das faixas
reservadas para documentação.

**Os provedores já estão configurados, e edge não tem nada.** A tabela BGP de ispa mostra o que ele sabe:

```
root@ispa:~# vtysh -c "show ip bgp"
BGP table version is 2, local router ID is 192.0.2.2, vrf id 0
Default local pref 100, local AS 64501
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

   Network          Next Hop            Metric LocPrf Weight Path
*> 198.51.100.0/25  0.0.0.0                  0         32768 i
*> 198.51.100.128/25
                    192.0.2.10               0             0 64502 i

Displayed  2 routes and 2 total paths
```

Duas redes. `198.51.100.0/25` são os clientes do próprio ispa: próximo salto `0.0.0.0`, que quer dizer
*este roteador*, e peso (*weight*) 32768, o valor que o FRR dá a uma rota que o próprio roteador origina.
`198.51.100.128/25` é a de ispb, aprendida pelo cabo entre os dois, de `192.0.2.10`, com o **AS path**
`64502`: a rota veio do AS 64502. O `i` no fim é o código de origem, IGP, que quer dizer que a rota entrou
no BGP por um comando `network`. **Nada sobre 203.0.113.0/24**, porque ninguém o anunciou, e assim:

```
ana@a1:~$ ping -c 1 -W 1 203.0.113.10
PING 203.0.113.10 (203.0.113.10) 56(84) bytes of data.
From 198.51.100.1 icmp_seq=1 Destination Net Unreachable

--- 203.0.113.10 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms

```

ispa, `198.51.100.1`, não tem rota para a empresa. O resto desta aula monta o lado de edge, uma peça de
cada vez.
