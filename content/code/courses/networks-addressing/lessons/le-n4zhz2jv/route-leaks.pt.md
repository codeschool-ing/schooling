---
title: Vazamentos de rota, e os dois filtros que os detêm
version: 1
---

Um **vazamento de rota** (*route leak*) é um anúncio que vai para onde sua política diz que não deveria ir.
O formato mais comum é o que este laboratório consegue fazer: **um cliente anunciando a um provedor as
rotas que aprendeu do outro**, o que se oferece para transportar tráfego entre duas redes grandes pelo
enlace pequeno de uma empresa. A empresa nunca quis ser rede de trânsito; uma linha errada a torna uma.

Os anúncios de edge para ispb, como estão:

```
root@edge:~# vtysh -c "show ip bgp neighbors 192.0.2.6 advertised-routes"
BGP table version is 3, local router ID is 192.0.2.1, vrf id 0
Default local pref 100, local AS 64500
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

   Network          Next Hop            Metric LocPrf Weight Path
*> 203.0.113.0/24   0.0.0.0                  0         32768 i

Total number of prefixes 1
```

Um prefixo, o da própria empresa. Agora o erro, encenado de propósito: um route map de saída chamado
`EVERYTHING`, uma única entrada `permit` sem `match`, que permite toda rota, aplicado em direção a ispb no
lugar de `TO-PROVIDER`:

```
root@edge:~# vtysh -c "configure terminal" -c "route-map EVERYTHING permit 10" -c "exit" -c "router bgp 64500" -c "address-family ipv4 unicast" -c "neighbor 192.0.2.6 route-map EVERYTHING out"
root@edge:~# vtysh -c "show ip bgp neighbors 192.0.2.6 advertised-routes"
BGP table version is 3, local router ID is 192.0.2.1, vrf id 0
Default local pref 100, local AS 64500
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

   Network          Next Hop            Metric LocPrf Weight Path
*> 198.51.100.0/25  0.0.0.0                                0 64501 i
*> 198.51.100.128/25
                    0.0.0.0                                0 64502 i
*> 203.0.113.0/24   0.0.0.0                  0         32768 i

Total number of prefixes 3
```

**Três prefixos**, onde havia um: o bloco da empresa, e as redes de clientes dos dois provedores. edge
agora diz a ispb *mande para mim seu tráfego para os clientes de ispa que eu repasso*. A listagem mostra os
caminhos como edge os guarda; ispb receberia cada um com 64500 acrescentado na frente.

## O filtro do outro lado

ispb aceitou a oferta? Sua visão dos clientes de ispa:

```
root@ispb:~# vtysh -c "show ip bgp 198.51.100.0/25"
BGP routing table entry for 198.51.100.0/25, version 2
Paths: (1 available, best #1, table default)
  Advertised to non peer-group peers:
  192.0.2.5 192.0.2.9
  64501
    192.0.2.9 from 192.0.2.9 (192.0.2.2)
      Origin IGP, metric 0, valid, external, best (First path received)
      Last update: Tue Sep 29 08:49:48 2026
```

**Um caminho disponível, vindo de `192.0.2.9`, ispa, pelo cabo entre os provedores.** Nada de edge. A
configuração de ispb no `lab.sh` aplica a tudo o que vem do cliente um route map que permite
`203.0.113.0/24` e mais nada, o gêmeo, do lado do provedor, do `TO-PROVIDER` de edge. Então o vazamento foi
pego pelo segundo filtro.

Dois detalhes deixam o caso mais nítido. O próprio bloco de ispb, `198.51.100.128/25`, teria sido
descartado de qualquer jeito, porque o caminho que edge ofereceu contém 64502, e um roteador BGP recusa um
caminho que contém o próprio AS. E neste laboratório a rota vazada para os clientes de ispa, `64500 64501`,
teria perdido para a direta `64501` pelo tamanho. **Na internet real ela não precisaria perder**: um
provedor que dá às rotas dos clientes uma local preference maior, como a seção anterior descreveu, prefere
uma rota vazada vinda de um cliente à correta vinda de um par, sejam quais forem os tamanhos. É assim que
um vazamento por uma rede pequena atrai o tráfego de redes grandes por um enlace que não o suporta, e isso
já aconteceu, mais de uma vez, com serviços que milhões de pessoas usam ficando lentos ou inalcançáveis
por horas.

**Então há dois filtros, um de cada lado de todo enlace de cliente**, e nenhum basta sozinho:

- **o filtro de saída do cliente**: anuncie seus próprios prefixos, e os dos seus clientes se tiver, e nada
  aprendido de um provedor ou de um par;
- **o filtro de entrada do provedor**: aceite de um cliente só os prefixos que esse cliente tem direito de
  anunciar.

## Pondo de volta, com uma rede de segurança

```
root@edge:~# vtysh -c "configure terminal" -c "router bgp 64500" -c "address-family ipv4 unicast" -c "neighbor 192.0.2.6 route-map TO-PROVIDER out" -c "neighbor 192.0.2.2 maximum-prefix 1000" -c "neighbor 192.0.2.6 maximum-prefix 1000"
root@edge:~# vtysh -c "show ip bgp neighbors 192.0.2.6 advertised-routes"
BGP table version is 3, local router ID is 192.0.2.1, vrf id 0
Default local pref 100, local AS 64500
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

   Network          Next Hop            Metric LocPrf Weight Path
*> 203.0.113.0/24   0.0.0.0                  0         32768 i

Total number of prefixes 1
```

`TO-PROVIDER` voltou em direção a ispb, e um prefixo é anunciado de novo. A mesma mudança acrescentou
`maximum-prefix 1000` aos dois vizinhos: **se um provedor um dia mandar a edge mais de 1000 prefixos, edge
fecha a sessão** em vez de encher a tabela com o que chegou. É a guarda do lado que recebe contra a imagem
espelhada desta seção, um provedor vazando algo enorme na sua direção, e é barata: o número só precisa
ficar com folga acima do que você espera receber.

A configuração final, como o FRR a guarda:

```
root@edge:~# vtysh -c "show running-config" | sed -n "/^router bgp/,\$p"
router bgp 64500
 bgp router-id 192.0.2.1
 neighbor 192.0.2.2 remote-as 64501
 neighbor 192.0.2.6 remote-as 64502
 !
 address-family ipv4 unicast
  network 203.0.113.0/24
  neighbor 192.0.2.2 maximum-prefix 1000
  neighbor 192.0.2.2 route-map FROM-PROVIDER in
  neighbor 192.0.2.2 route-map TO-ISPA out
  neighbor 192.0.2.6 maximum-prefix 1000
  neighbor 192.0.2.6 route-map FROM-PROVIDER in
  neighbor 192.0.2.6 route-map TO-PROVIDER out
 exit-address-family
exit
!
ip prefix-list OURS seq 5 permit 203.0.113.0/24
!
route-map TO-PROVIDER permit 10
 match ip address prefix-list OURS
exit
!
route-map FROM-PROVIDER deny 5
 match ip address prefix-list OURS
exit
!
route-map FROM-PROVIDER permit 10
exit
!
route-map TO-ISPA permit 10
 match ip address prefix-list OURS
 set as-path prepend 64500 64500
exit
!
route-map EVERYTHING permit 10
exit
!
end
```

Leia de cima para baixo: o AS, os dois vizinhos, a única rede, os limites, e um route map de entrada e de
saída em cada sessão, `TO-ISPA` em direção a ispa com o prepend da seção anterior. Uma coisa não deveria
estar ali. **`route-map EVERYTHING` continua definido**, sem uso, esperando alguém aplicá-lo de novo por
engano; `no route-map EVERYTHING` o removeria. Ele não foi removido neste laboratório, e é o tipo de sobra
que uma revisão de configuração existe para encontrar.
