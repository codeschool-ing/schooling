---
title: Um peering não repassa nada
version: 1
---

**Se a produção tem peering com o hub, e a staging tem peering com o hub, a produção ainda não alcança
a staging.** É a frase que as pessoas erram, porque toda outra rede que elas conhecem passa o tráfego
adiante: um roteador que conhece dois vizinhos os liga. Um peering não é um roteador. É uma afirmação
sobre duas redes, e não diz nada sobre uma terceira.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l20-transitive\" aria-label=\"Três redes. O hub vnet-shop-hub, 10.0.0.0/16, fica em cima. vnet-shop-prod, 10.20.0.0/16, e vnet-shop-staging, 10.30.0.0/16, ficam abaixo dele, cada uma ligada ao hub por um peering desenhado como linha cheia com duas pontas de seta. Entre produção e staging uma linha tracejada diz que não há rota: cada spoke aprende o intervalo do hub e não o da outra spoke.\"><defs><marker id=\"l20-transitive-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"270.0\" y=\"16.0\" width=\"180.0\" height=\"72.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-hub</text><text x=\"360.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.0.0.0/16</text><text x=\"360.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop-shared</text><rect x=\"40.0\" y=\"190.0\" width=\"180.0\" height=\"72.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-prod</text><text x=\"130.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.0.0/16</text><text x=\"130.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop-prod</text><rect x=\"500.0\" y=\"190.0\" width=\"180.0\" height=\"72.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-staging</text><text x=\"590.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.30.0.0/16</text><text x=\"590.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop-staging</text><path d=\"M200.0 189.0 L290.0 89.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l20-transitive-af-ah-phosphor)\" marker-start=\"url(#l20-transitive-af-ah-phosphor)\"></path><path d=\"M520.0 189.0 L430.0 89.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l20-transitive-af-ah-phosphor)\" marker-start=\"url(#l20-transitive-af-ah-phosphor)\"></path><text x=\"205.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">peering</text><text x=\"515.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">peering</text><path d=\"M222.0 226.0 L498.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 5\"></path><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">sem rota</text><text x=\"360.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um peering não repassa nada</text></svg>", "caption": "Cada spoke aprende o intervalo do hub. Nenhuma aprende o da outra.", "same": ["peering", "shop-prod", "shop-shared", "shop-staging"]}
```

O Azure dá a cada rede as rotas para os intervalos das redes **com as quais ela tem peering direto**, e
para aí. A `vnet-shop-prod` aprende `10.0.0.0/16` pelo peering com o hub, e nada sobre `10.30.0.0/16`,
porque não tem peering com a staging. Um pacote para `10.30.1.5` saindo da produção não acha rota para
esse intervalo e segue o destino de tudo o que não tem rota. O hub conhece os dois intervalos, mas **o
hub não é um equipamento**: nada nele encaminha um pacote de um peering para outro a não ser que alguém
ponha um equipamento ali.

## Três jeitos de atravessar

Há três jeitos de deixar duas spokes conversarem, e eles diferem no que custam e em quem consegue ver
o tráfego.

- **Fazer peering direto entre elas.** Um terceiro peering, produção com staging, e as duas conversam
  sem o hub. Funciona para duas. Para um parque inteiro vira uma **malha**: toda rede com peering com
  toda outra, `n × (n − 1) / 2` peerings para `n` redes, cada um dois recursos, cada um uma decisão que
  alguém precisa lembrar quando uma rede é acrescentada. Dez redes são quarenta e cinco peerings.
- **Rotear por um equipamento no hub.** Ponha um firewall no hub, o Azure Firewall ou um appliance
  virtual, e dê a cada spoke uma tabela de rotas que manda os intervalos das outras spokes para o
  endereço privado do firewall. O firewall recebe o pacote, decide se ele pode passar, e o manda adiante
  pelo outro peering; o lado do destino precisa então aceitá-lo, que é para isso que existe o
  `allowForwardedTraffic`. A lição 18 monta essa tabela de rotas e esse firewall. O custo é um firewall
  que roda por hora, e duas travessias de peering para cada pacote; o ganho é um lugar que vê e julga
  tudo o que se move entre spokes.
- **Deixar o Azure operar o hub.** O **Azure Virtual WAN** é um hub que a Microsoft opera, com
  roteadores próprios, onde as redes ligadas se alcançam sem tabelas de rotas suas. O **Azure
  Virtual Network Manager** cria e mantém peerings entre muitas redes a partir de uma descrição, em
  malha ou hub-and-spoke, para que uma spoke nova entre no grupo certo sem ninguém escrever os peerings
  dela à mão. Os dois são serviços próprios, e este curso os cita para você reconhecê-los; não os
  ensina.

**Se a produção deve alcançar a staging é a primeira pergunta**, e para a loja a resposta é não. Os
dois ambientes são assinaturas separadas em ramos separados da árvore da lição 2 justamente para que um
erro num não alcance o outro. **A não transitividade é o padrão que a loja quer**, e o único tráfego
entre spokes que ela vai permitir passa pelo firewall do hub, onde fica registrado.

## O que o laboratório consegue e não consegue mostrar

Um peering carrega pacotes, e o laboratório não tem nenhum para carregar: não há rede do Azure neste
computador para mandar um pacote através. O que o laboratório consegue mostrar é a aritmética da seção
anterior e o formato dos peerings da próxima, os dois lados, em Bicep e em Terraform. **O comportamento
que esta seção descreve, a rota que falta entre duas spokes, é o comportamento documentado da
Microsoft e não foi executado aqui.** Numa assinatura de verdade o lugar para vê-lo são as **rotas
efetivas** de uma máquina, que listam cada rota que uma interface de rede usa e de onde ela veio; um
intervalo aprendido por peering aparece com o tipo de próximo salto `VNetPeering`, e o intervalo de uma
spoke a dois passos de distância nem aparece.
