---
title: VPN Gateway, o caminho criptografado pela internet
version: 1
---

**Há dois caminhos do prédio de uma empresa até uma rede no Azure, e eles diferem naquilo por onde
passam.** Uma **VPN** é um túnel criptografado pela internet pública: barata, pronta numa tarde, e tão
rápida e estável quanto a internet estiver naquele dia. O **ExpressRoute** é um circuito privado que
uma operadora de telecomunicações provisiona entre a empresa e a Microsoft: semanas para contratar,
cobrado por mês, e ele nunca encosta na internet. A maioria das empresas começa pelo primeiro, e as que
crescem acrescentam o segundo, mantendo o primeiro como reserva. Esta lição os vê nessa ordem, e **quase
tudo nela é lido, não executado**: um gateway e um circuito são coisas que só o Azure cria, e só o Bicep
da próxima seção foi conferido no laboratório.

O caso da loja é pequeno e comum. O escritório em São Paulo tem a sua própria rede, `192.168.0.0/16`,
um firewall com endereço público, `203.0.113.10`, e um sistema financeiro que precisa alcançar o banco
de dados na `vnet-shop-prod`. O caminho entra pela rede hub da lição 20, a `vnet-shop-hub`, na
assinatura `shop-shared`, para que todo spoke ligado ao hub por peering possa usar um caminho só em vez
de cada um construir o seu.

## O gateway mora numa sub-rede chamada GatewaySubnet

**Um VPN gateway é um par de máquinas virtuais que a Microsoft roda para você, dentro de uma sub-rede da
sua rede.** Você nunca vê as máquinas e não consegue entrar nelas; você cria o recurso gateway, e o Azure
põe as instâncias na sub-rede. Três regras sobre essa sub-rede são da Microsoft, não convenções:

- **o nome precisa ser exatamente `GatewaySubnet`.** O nome é como o Azure a encontra; uma sub-rede
  chamada `snet-gateway` é só uma sub-rede, e a criação do gateway falha;
- **ela não guarda mais nada.** Nenhuma máquina, nenhum outro serviço;
- **ela é `/27` ou maior** para todo SKU menos o menor. A loja dá a ela `10.0.255.0/27`, no topo da
  faixa do hub, o que deixa espaço para um ExpressRoute gateway dividi-la depois. Uma sub-rede maior não
  custa nada, e aumentar uma pequena debaixo de um gateway rodando é um projeto.

Criar um gateway leva **45 minutos ou mais**, pela própria documentação da Microsoft. Um desenho que
supõe que o caminho pode ser refeito na hora do almoço está errado antes de começar.

## SKUs, e por que os nomes terminam em AZ

O tamanho do gateway é o SKU, e o SKU decide a vazão, o número de túneis e os recursos. Dois fatos
importam mais que a tabela de números, que é da Microsoft para mudar:

- **o Basic é para experimentar**, e a documentação da Microsoft diz isso: sem BGP, sem active-active,
  suporte limitado, nunca produção;
- **os SKUs que terminam em `AZ`** (`VpnGw1AZ` a `VpnGw5AZ`) espalham as instâncias do gateway pelas
  zonas de disponibilidade da região. A Microsoft está levando todo gateway para eles, e os que não têm
  `AZ` estão sendo consolidados neles. A loja usa o `VpnGw2AZ`.

Um gateway também precisa de um endereço público do SKU Standard, e de um segundo quando as duas
instâncias estão ativas, que é a próxima parte.

## Active-standby e active-active

Todo gateway tem duas instâncias. **Por padrão uma carrega o túnel e a outra espera**: quando a ativa
falha, ou a Microsoft faz manutenção nela, a reserva assume, e o túnel cai por um momento enquanto isso
acontece. A documentação da Microsoft descreve a interrupção como breve, de segundos numa manutenção
planejada a mais tempo numa falha não planejada.

O **active-active** faz as duas instâncias montarem túneis ao mesmo tempo, cada uma do seu endereço
público. Com um firewall no escritório isso dá dois túneis; com dois firewalls, cada um ligado às duas
instâncias, dá quatro, e perder qualquer aparelho deixa o tráfego correndo pelo resto:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l23-active-active\" aria-label=\"Redundância dupla numa VPN site a site. À esquerda, a rede do escritório 192.168.0.0/16 com dois firewalls. À direita, na GatewaySubnet 10.0.255.0/27 da rede hub, o VPN gateway vpng-shop com duas instâncias ativas, cada uma com o seu endereço público. Cada firewall monta um túnel até cada instância, quatro túneis ao todo, atravessando a internet no meio. Perder qualquer firewall ou qualquer instância deixa dois ou mais túneis de pé.\"><text x=\"115.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">escritório</text><text x=\"115.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.0.0/16</text><text x=\"600.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">GatewaySubnet</text><text x=\"600.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.0.255.0/27</text><rect x=\"50.0\" y=\"100.0\" width=\"130.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">firewall 1</text><rect x=\"50.0\" y=\"190.0\" width=\"130.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">firewall 2</text><rect x=\"530.0\" y=\"100.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instância 1</text><text x=\"600.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pip-vpng-shop-1</text><rect x=\"530.0\" y=\"190.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instância 2</text><text x=\"600.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pip-vpng-shop-2</text><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">pela internet</text><path d=\"M181.0 115.0 L529.0 115.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M181.0 118.0 L529.0 212.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M181.0 212.0 L529.0 118.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M181.0 215.0 L529.0 215.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"360.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">quatro túneis: qualquer aparelho pode falhar</text></svg>", "caption": "Dois firewalls e duas instâncias ativas fazem quatro túneis, e o BGP acompanha quais estão de pé.", "same": ["firewall 1", "firewall 2"]}
```

O preço do active-active é um segundo endereço público e, na prática, o **BGP**: com vários túneis de pé
ao mesmo tempo, os dois lados precisam de um protocolo de roteamento para combinar quais redes estão
atrás de qual túnel e para parar de usar um que morreu. O BGP é o assunto da última parte da próxima
seção.

## O outro tipo de VPN

Tudo acima é **site a site**: uma rede com outra, por aparelhos nas duas pontas, invisível para quem a
usa. Um gateway também pode aceitar conexões **ponto a site**, em que um notebook sozinho roda um cliente
de VPN e entra na rede de onde estiver. É a ferramenta certa para um punhado de administradores e a
errada para um escritório inteiro, e o login dela pode usar o Entra ID, o que a liga ao acesso
condicional da lição 11.
