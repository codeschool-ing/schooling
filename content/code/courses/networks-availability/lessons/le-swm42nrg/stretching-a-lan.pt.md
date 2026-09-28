---
title: Quando esticar uma LAN vale a pena, e quando dói
version: 1
---

O broadcast ARP atravessando o provedor é o recurso e o perigo num pacote só. **Uma VPN de camada 2 não
une duas redes; ela as transforma numa só, com tudo o que um único segmento divide.**

Esticar tem seu lugar em algumas situações. Uma máquina virtual movida a quente de um data center para
outro mantém o endereço IP e as conexões abertas só se a mesma sub-rede existir dos dois lados. Algumas
aplicações antigas acham os pares por broadcast, ou exigem que os membros de um cluster fiquem numa
sub-rede. E a interconexão de data centers, em que as duas pontas pertencem a um operador em enlaces que
ele controla, é aquilo para que o VXLAN foi feito.

Em qualquer outro caso, o que os escritórios dividem é o que sofrem juntos:

| dividido | o que significa através de uma WAN |
|---|---|
| broadcasts | todo pedido ARP e todo DHCP discover de um site atravessa o túnel para todos os outros |
| um loop | um cabo ligado de volta no próprio switch num site inunda os outros sites também |
| spanning tree | uma árvore só atravessando a WAN, a aula 20 de `networks-addressing`: uma mudança de topologia num site chega aos outros |
| uma sub-rede | se o enlace da WAN cai, a sub-rede se parte em duas metades que acreditam estar inteiras |
| um gateway | uma máquina movida para a filial continua mandando para o gateway na matriz, e de volta, pela WAN |

A última linha tem nome, **tromboning**: o tráfego entre duas máquinas no mesmo prédio sai pela WAN até
um roteador no outro e volta, porque é lá que mora o gateway da sub-rede. **A divisão da linha acima é
pior, porque nada a denuncia**: cada metade continua respondendo pelos endereços que ainda tem.

**Roteie quando puder, estique só quando algo precisar da mesma sub-rede em dois lugares.** Todo túnel
das aulas 1 e 2 uniu duas sub-redes por dois roteadores. Uma tempestade de broadcast ou um loop num
escritório ficava naquele escritório, e um enlace caído cortava uma rota em vez de partir uma rede em
duas metades.

## Os outros jeitos de levar camada 2

Nenhum destes rodou no laboratório. Os três primeiros levam quadros Ethernet, como o VXLAN; o último é
como o VXLAN roda em escala.

| | como leva os quadros | onde aparece |
|---|---|---|
| OpenVPN com `dev tap` | quadros Ethernet pela mesma VPN TLS desta aula | instalações pequenas, uma ponte remota para uma LAN |
| L2TPv3 | quadros em IP ou UDP, um pseudowire entre dois roteadores | o serviço Ethernet ponto a ponto de um provedor |
| VPLS | quadros pela rede MPLS de um provedor, muitos sites num segmento | os "serviços de LAN" de operadora entre filiais |
| EVPN | o BGP diz a cada ponta qual MAC mora onde, em vez de inundar para aprender | data centers rodando VXLAN em escala |

O EVPN responde à lista de inundação da seção anterior. Em vez de copiar todo broadcast e todo quadro
desconhecido para cada site e aprender os endereços pelas respostas, cada ponta anuncia os próprios
endereços MAC no BGP, o protocolo da aula 17 de `networks-addressing`. As outras sabem onde um endereço
mora antes de precisar perguntar. 
