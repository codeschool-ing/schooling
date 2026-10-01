---
title: Política, e o AS path que decide
version: 1
---

Uma política BGP se escreve com duas ferramentas. Uma **prefix list** nomeia prefixos. Um **route map** é
uma lista ordenada de entradas, cada uma *permit* ou *deny*, cada uma casando com algo, uma prefix list
por exemplo, e opcionalmente alterando a rota; **uma rota que não casa com nenhuma entrada é negada**.
edge recebe três deles:

```
root@edge:~# vtysh -c "configure terminal" -c "ip prefix-list OURS seq 5 permit 203.0.113.0/24" -c "route-map TO-PROVIDER permit 10" -c "match ip address prefix-list OURS" -c "exit" -c "route-map FROM-PROVIDER deny 5" -c "match ip address prefix-list OURS" -c "exit" -c "route-map FROM-PROVIDER permit 10" -c "exit" -c "router bgp 64500" -c "address-family ipv4 unicast" -c "neighbor 192.0.2.2 route-map FROM-PROVIDER in" -c "neighbor 192.0.2.2 route-map TO-PROVIDER out" -c "neighbor 192.0.2.6 route-map FROM-PROVIDER in" -c "neighbor 192.0.2.6 route-map TO-PROVIDER out"
```

Leia como política, e não como sintaxe:

- `OURS` é o bloco da empresa, `203.0.113.0/24`, e mais nada.
- `TO-PROVIDER`, aplicado na *saída* para os dois provedores, permite o que casa com `OURS`. Todo o
  resto cai no fim e é negado: **edge anuncia o próprio bloco e mais nada**.
- `FROM-PROVIDER`, aplicado na *entrada*, primeiro nega `OURS`, para que nenhum provedor diga a edge
  como chegar à própria rede da empresa, e depois permite todo o resto.

O resumo troca `(Policy)` por números:

```
root@edge:~# vtysh -c "show bgp summary"

IPv4 Unicast Summary (VRF default):
BGP router identifier 192.0.2.1, local AS number 64500 vrf-id 0
BGP table version 3
RIB entries 5, using 960 bytes of memory
Peers 2, using 1448 KiB of memory

Neighbor        V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
192.0.2.2       4      64501        16        10        0    0    0 00:00:13            2        1 N/A
192.0.2.6       4      64502        16        10        0    0    0 00:00:13            2        1 N/A

Total number of neighbors 2
```

**2 recebidos e 1 enviado em cada sessão**: cada provedor mandou suas duas redes de clientes, e edge mandou
seu único bloco a cada um. ispa lista edge entre os vizinhos a quem repassa 203.0.113.0/24, como a captura
da próxima seção mostra, e o que chegar edge recusa duas vezes: `FROM-PROVIDER` o nega, e o caminho contém
64500, o AS do próprio edge. **Um roteador BGP descarta qualquer rota cujo AS
path já contenha o seu número**, e é assim que o BGP evita loops entre ASes.

## Lendo a tabela de edge

```
root@edge:~# vtysh -c "show ip bgp"
BGP table version is 3, local router ID is 192.0.2.1, vrf id 0
Default local pref 100, local AS 64500
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

   Network          Next Hop            Metric LocPrf Weight Path
*  198.51.100.0/25  192.0.2.6                              0 64502 64501 i
*>                  192.0.2.2                0             0 64501 i
*> 198.51.100.128/25
                    192.0.2.6                0             0 64502 i
*                   192.0.2.2                              0 64501 64502 i
*> 203.0.113.0/24   0.0.0.0                  0         32768 i

Displayed  3 routes and 5 total paths
```

Cinco caminhos para três redes. Para `198.51.100.0/25`, os clientes de ispa, edge guarda dois:

- por `192.0.2.6`, ispb, com o AS path **`64502 64501`**: ispb o ouviu de ispa e o repassou;
- por `192.0.2.2`, ispa, com o AS path **`64501`**, marcado com `>`, o melhor.

**O AS path é a lista de ASes que uma rota atravessou, do mais recente ao mais antigo, com a origem por
último.** Com todo o resto igual, o caminho mais curto vence, e aqui todo o resto é igual.
`198.51.100.128/25` é a imagem espelhada: melhor por ispb, `64502`. O bloco da própria empresa tem próximo
salto `0.0.0.0` e peso 32768, originado aqui.

A escolha do BGP passa por uma lista fixa de critérios de desempate, em ordem, e para no primeiro que
difere. Os primeiros, no FRR e na Cisco: o maior weight (local a um roteador), a maior local
preference (compartilhada dentro de um AS), uma rota que este roteador originou, **o AS path mais curto**,
o código de origem, o menor MED, e depois eBGP antes de iBGP. Tudo o que esta aula faz com tráfego real
acontece no passo do AS path, porque nada antes dele foi ajustado.

Os melhores caminhos vão para o kernel:

```
root@edge:~# ip route
192.0.2.0/30 dev eth1 proto kernel scope link src 192.0.2.1 
192.0.2.4/30 dev eth2 proto kernel scope link src 192.0.2.5 
198.51.100.0/25 nhid 15 via 192.0.2.2 dev eth1 proto bgp metric 20 
198.51.100.128/25 nhid 16 via 192.0.2.6 dev eth2 proto bgp metric 20 
203.0.113.0/24 dev eth0 proto kernel scope link src 203.0.113.1 
```

`proto bgp`, e o mesmo `metric 20` que a aula 16 encontrou nas rotas do RIP, o número do FRR e não do BGP.
Agora a1 e b1 alcançam o servidor web, **cada um pelo próprio provedor**:

```
ana@a1:~$ traceroute -n 203.0.113.10
traceroute to 203.0.113.10 (203.0.113.10), 30 hops max, 60 byte packets
 1  198.51.100.1  2.503 ms  0.519 ms  0.155 ms
 2  192.0.2.1  0.605 ms  0.168 ms  0.128 ms
 3  203.0.113.10  1.421 ms  0.388 ms  0.131 ms
ana@b1:~$ traceroute -n 203.0.113.10
traceroute to 203.0.113.10 (203.0.113.10), 30 hops max, 60 byte packets
 1  198.51.100.129  2.477 ms  0.631 ms  0.294 ms
 2  192.0.2.5  0.834 ms  0.713 ms  0.534 ms
 3  203.0.113.10  0.680 ms  0.551 ms  0.236 ms
```

O tráfego de a1 chega em `192.0.2.1`, a interface de edge voltada para ispa; o de b1 em `192.0.2.5`,
voltada para ispb. Três saltos cada, e os dois provedores carregam o tráfego da empresa, que é o motivo de
ter dois.
