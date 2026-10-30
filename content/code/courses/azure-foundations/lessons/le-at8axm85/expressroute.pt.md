---
title: ExpressRoute, o circuito privado, e como não ter um só
version: 1
---

**Um circuito ExpressRoute é uma conexão privada entre a rede de uma empresa e a da Microsoft,
construída por uma operadora, que nunca atravessa a internet pública.** Não é um cabo que se pluga: é um
acordo entre três partes, e um recurso no Azure que o registra. **Nada nesta seção foi executado**, e o
laboratório não tem como mostrar parte nenhuma dela; ela é ensinada a partir da documentação da
Microsoft.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l23-expressroute\" aria-label=\"As partes de um circuito ExpressRoute, da esquerda para a direita. O roteador do escritório se liga pela rede do provedor de conectividade a uma localidade de peering, como Sao Paulo, onde ficam dois roteadores de borda da Microsoft, primário e secundário. Dali a rede da Microsoft leva o private peering a um ExpressRoute gateway na GatewaySubnet do hub, ao lado do VPN gateway, e o Microsoft peering aos serviços públicos da Microsoft. Nada no caminho atravessa a internet.\"><defs><marker id=\"l23-expressroute-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l23-expressroute-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16.0\" y=\"115.0\" width=\"110.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"71.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">roteador</text><text x=\"71.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a empresa</text><rect x=\"150.0\" y=\"105.0\" width=\"130.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"215.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">provedor</text><text x=\"215.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a rede da operadora</text><rect x=\"304.0\" y=\"60.0\" width=\"150.0\" height=\"170.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"379.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">localidade de peering</text><text x=\"379.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Sao Paulo</text><rect x=\"320.0\" y=\"112.0\" width=\"118.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"379.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">roteador primário</text><rect x=\"320.0\" y=\"170.0\" width=\"118.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"379.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">roteador secundário</text><rect x=\"500.0\" y=\"40.0\" width=\"204.0\" height=\"134.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"602.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">GatewaySubnet</text><rect x=\"516.0\" y=\"72.0\" width=\"172.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ExpressRoute gateway</text><text x=\"602.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">private peering</text><rect x=\"516.0\" y=\"122.0\" width=\"172.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"602.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">VPN gateway, de reserva</text><rect x=\"500.0\" y=\"196.0\" width=\"204.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"602.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">serviços públicos da Microsoft</text><text x=\"602.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Microsoft peering</text><path d=\"M127.0 143.0 L149.0 143.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-expressroute-af-ah-paper-dim)\"></path><path d=\"M281.0 133.0 L319.0 133.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-expressroute-af-ah-paper-dim)\"></path><path d=\"M281.0 153.0 L300.0 153.0 L300.0 191.0 L319.0 191.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-expressroute-af-ah-paper-dim)\"></path><path d=\"M439.0 133.0 L472.0 133.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M439.0 191.0 L472.0 191.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M472.0 92.0 L472.0 223.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M472.0 92.0 L515.0 92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-expressroute-af-ah-phosphor)\"></path><path d=\"M472.0 223.0 L499.0 223.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-expressroute-af-ah-paper-dim)\"></path><text x=\"360.0\" y=\"274.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os dois peerings usam as duas conexões; nenhum caminho passa pela internet</text></svg>", "caption": "Um circuito são duas conexões a dois roteadores, num prédio só, e é por isso que um circuito não basta.", "same": ["ExpressRoute gateway", "Microsoft peering", "private peering"]}
```

## Três partes e um ponto de encontro

Um circuito liga a empresa à Microsoft numa **localidade de peering**: um datacenter neutro onde os
roteadores de borda da Microsoft ficam ao lado dos das operadoras. A documentação da Microsoft lista
quatro na região de São Paulo e do Rio: **Sao Paulo** (Equinix SP2), **Sao Paulo2** (TIVIT),
**Campinas** (Ascenty) e **Rio de Janeiro** (Equinix RJ2), as três primeiras associadas à `brazilsouth`
e a última à `brazilsoutheast`. A operadora, que a Microsoft chama de **provedor de conectividade**, leva
o tráfego da empresa do prédio dela até essa localidade.

A contratação corre nesta ordem. A empresa cria o recurso do circuito no Azure, citando o provedor, a
localidade de peering e uma **largura de banda** de uma lista fixa, de 50 Mbps a 10 Gbps. O Azure
responde com uma **service key**, um GUID que é a única coisa que as três partes trocam; a documentação
da Microsoft diz com todas as letras que ele não é segredo. A empresa entrega a chave ao provedor, o
provedor monta o lado dele, e o estado do circuito muda para *Provisioned*. Só então alguma coisa passa.
O passo do meio é um contrato e um técnico em campo, medido em semanas.

## Dois peerings num circuito

Um circuito carrega um ou dois **peerings**, cada um um par de sessões BGP:

- o **private peering** alcança os endereços privados das suas redes virtuais. É o que a loja quer: o
  sistema financeiro fala com `10.20.3.0/24` como se estivesse no fim do corredor;
- o **Microsoft peering** alcança os serviços públicos da Microsoft, como o Microsoft 365 ou o endereço
  público de uma storage account, pelo circuito em vez da internet. Como esses são endereços públicos, o
  lado da empresa também precisa apresentar endereços públicos, em geral traduzindo os seus.

O circuito chega à rede por um gateway, o mesmo tipo de recurso do da VPN mas do tipo `ExpressRoute`,
com SKUs próprios, e ele mora na **mesma `GatewaySubnet`**. Esse é o motivo de a loja ter feito a
sub-rede `/27`: um VPN gateway e um ExpressRoute gateway podem dividi-la, e o desenho usual mantém os
dois.

## Todo circuito já são dois, e isso não basta

**Cada circuito são duas conexões**, primária e secundária, a dois roteadores diferentes da Microsoft na
mesma localidade de peering, e a Microsoft mantém as duas ativas ao mesmo tempo. Então o próprio
circuito não tem um roteador único a perder. O que ele tem é tudo o que é da empresa e da operadora: se
as duas conexões terminam num roteador só no escritório, ou viajam num cabo só pela mesma rua, uma falha
derruba as duas. A documentação da Microsoft é específica: terminar primária e secundária no mesmo
aparelho compromete a redundância com que o circuito foi construído.

**E a localidade de peering em si é um prédio.** Um incêndio ali derruba as duas conexões de todo
circuito que se encontra nele. As respostas, da mais barata à mais resiliente:

1. **uma VPN site a site de reserva**, pela internet, pelo VPN gateway ao lado do de ExpressRoute.
   Quando as rotas do circuito somem, o BGP manda o tráfego pelo túnel;
2. **um segundo circuito numa segunda localidade de peering**, Sao Paulo e Campinas por exemplo, cada
   um com a sua operadora, para que nenhum prédio, nenhuma operadora e nenhuma rua sejam compartilhados;
3. os dois, que é o que a Microsoft recomenda para os sistemas que não podem parar.

## O que o circuito não faz

**O ExpressRoute é privado, e privado não é criptografado.** O circuito mantém o tráfego fora da
internet; ele não o criptografa. Uma empresa que precisa de criptografia no circuito roda um túnel IPsec
por dentro dele com um VPN gateway, ou, com o ExpressRoute Direct, em que ela é dona de portas nos
roteadores da Microsoft, usa MACsec no enlace. A decisão é a mesma que a lição 19 toma sobre private
endpoints: sair da internet é uma redução de quem pode ver o tráfego, não uma garantia de que ninguém
pode.

A outra coisa que ele não faz é deixar algo mais barato por si só. Um circuito é cobrado por mês pela
largura de banda, além do gateway por hora; se os dados que o atravessam também são cobrados depende do
plano escolhido, medido ou ilimitado. Isso é da lista de preços dizer e deste curso deixar lá, pelo
motivo que a lição 1 deu.
