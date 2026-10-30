---
title: Entrada global, vista do DNS público, e a decisão
version: 1
---

**O Traffic Manager e o Front Door funcionam sendo donos do nome que o usuário procura**, então o DNS
público, a que qualquer um pode perguntar, mostra onde eles ficam na frente de um serviço. Dois nomes
da própria Microsoft bastam, e o `dig` da lição 1 pergunta sem conta. O `+noall +answer` deixa só a
resposta. O `+nottlid` omite os segundos que cada registro ainda tem nos caches, que mudam a cada
consulta. E o `grep CNAME` fica com os nomes e descarta os endereços no fim da cadeia, que diferem de
um lugar e de um minuto para o outro:

```
ana@laptop:~/azure/balancing$ dig portal.azure.com +noall +answer +nottlid | grep CNAME
portal.azure.com.	IN	CNAME	portal-prod-02-linkage.trafficmanager.net.
portal-prod-02-linkage.trafficmanager.net. IN CNAME azureportal.z01.azurefd.net.
azureportal.z01.azurefd.net. IN	CNAME	azurefd-p-prod.trafficmanager.net.
azurefd-p-prod.trafficmanager.net. IN CNAME shed.s-part-19.p-0010.p-msedge.net.
shed.s-part-19.p-0010.p-msedge.net. IN CNAME p-0010.p-msedge.net.
```

Leia a cadeia de cima para baixo. O nome do portal do Azure é um apelido para um nome em
**`trafficmanager.net`**: um perfil do Traffic Manager decide primeiro. A resposta dele é um nome em
**`azurefd.net`**, um endpoint do **Front Door**. O nome do próprio Front Door passa de novo pelo
Traffic Manager, que escolhe entre as redes de localidades de borda do Front Door, e os últimos nomes,
em `msedge.net`, são essas bordas. Então o portal empilha os dois serviços globais: o direcionamento
por DNS escolhe a entrada, e um proxy de camada 7 na borda leva o pedido para dentro.

```
ana@laptop:~/azure/balancing$ dig mcr.microsoft.com +noall +answer +nottlid | grep CNAME
mcr.microsoft.com.	IN	CNAME	mcr.trafficmanager.net.
mcr.trafficmanager.net.	IN	CNAME	mcr-0001.mcr-msedge.net.
```

O registro de contêineres da Microsoft, onde a Microsoft publica as suas imagens de contêiner, é mais
simples: um perfil do Traffic Manager, `mcr`, apontando para um conjunto de servidores do próprio
registro. Nenhum proxy no meio: depois da resposta do DNS, o cliente fala direto com esses servidores.

**Um nome do Traffic Manager é único em todo o Azure**, como o de uma storage account, porque é um nome
numa zona que a Microsoft opera. Um que ninguém criou simplesmente não existe:

```
ana@laptop:~/azure/balancing$ dig shop-azure-foundations-l22.trafficmanager.net +noall +comments | grep -o "status: [A-Z]*"
status: NXDOMAIN
```

`NXDOMAIN` é o DNS dizendo que o nome não existe. Criar um perfil com esse nome o faria responder em um
minuto, pelos servidores de nomes do próprio Traffic Manager. **Criar um não foi executado**; um perfil
é um recurso do Resource Manager como outro qualquer.

## A decisão

A maior parte das escolhas sai de três perguntas feitas em ordem:

1. **É HTTP?** Se não for, os serviços de camada 7 estão fora: um banco de dados, um servidor de jogo
   ou um broker de mensagens atrás de um balanceador fica com o Load Balancer numa região, e com o
   Traffic Manager, ou a camada entre regiões do Load Balancer, se abranger regiões.
2. **É uma região ou várias?** Uma região e HTTP é o Application Gateway. Várias regiões e HTTP é o
   Front Door, que também dá o cache e o WAF na borda.
3. **Alguma coisa precisa do endereço real de quem chamou?** O Load Balancer o mantém como origem. Os
   proxies o trocam pelo próprio e levam o original num cabeçalho, que a aplicação precisa ler e em
   que não deve confiar quando ele chega de qualquer outro lugar.

Os serviços também se combinam, e o desenho da loja é a combinação usual:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l22-shop-path\" aria-label=\"O caminho do pedido de um cliente no desenho da loja, da esquerda para a direita. Um cliente procura shop.example e se conecta à localidade de borda do Front Door mais próxima. O Front Door leva o pedido a brazilsouth, a um Application Gateway na sub-rede snet-agw. O gateway manda /api/ para o pool da aplicação e as páginas para o pool web em snet-web. As máquinas web chamam a camada de aplicação por um Load Balancer interno em snet-app. Tudo, menos a borda, está dentro de vnet-shop-prod.\"><defs><marker id=\"l22-shop-path-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l22-shop-path-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l22-shop-path-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16.0\" y=\"110.0\" width=\"100.0\" height=\"50.0\" rx=\"25\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"66.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cliente</text><text x=\"66.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop.example</text><rect x=\"140.0\" y=\"100.0\" width=\"118.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"199.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Front Door</text><text x=\"199.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">borda mais próxima</text><path d=\"M117.0 135.0 L139.0 135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-shop-path-af-ah-paper-dim)\"></path><rect x=\"280.0\" y=\"30.0\" width=\"424.0\" height=\"252.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"296.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">vnet-shop-prod</text><text x=\"690.0\" y=\"46.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">brazilsouth</text><path d=\"M259.0 135.0 L295.0 135.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-shop-path-af-ah-phosphor)\"></path><rect x=\"296.0\" y=\"96.0\" width=\"120.0\" height=\"78.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"356.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">App Gateway</text><text x=\"356.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">snet-agw</text><text x=\"356.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">separa /api/</text><rect x=\"444.0\" y=\"64.0\" width=\"108.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"498.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pool web</text><text x=\"498.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">snet-web</text><rect x=\"444.0\" y=\"196.0\" width=\"108.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"498.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">LB interno</text><text x=\"498.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">snet-app</text><rect x=\"580.0\" y=\"196.0\" width=\"108.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"634.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pool da aplicação</text><text x=\"634.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">snet-app</text><path d=\"M417.0 120.0 L443.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-shop-path-af-ah-paper-dim)\"></path><path d=\"M417.0 150.0 L430.0 150.0 L430.0 266.0 L634.0 266.0 L634.0 253.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-shop-path-af-ah-amber)\"></path><path d=\"M498.0 121.0 L498.0 195.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-shop-path-af-ah-paper-dim)\"></path><path d=\"M553.0 224.0 L579.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-shop-path-af-ah-paper-dim)\"></path><text x=\"600.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">/api/ vai direto ao pool da aplicação</text></svg>", "caption": "O Front Door escolhe a região, o Application Gateway o pool, e o load balancer interno a máquina.", "same": ["App Gateway", "Front Door"]}
```

Os clientes chegam a `shop.example` pelo **Front Door**, que guarda imagens em cache na borda e manda
os pedidos ao **Application Gateway** em `brazilsouth`, que separa `/api/` das páginas e entrega cada
um ao seu pool. Entre as camadas, um **Load Balancer interno** fica na frente das máquinas da
aplicação. O Traffic Manager não está no caminho: com o Front Door já escolhendo a região, uma segunda
camada de DNS só acrescentaria um cache para esperar expirar.

**Cada camada custa dinheiro por hora e por gigabyte**, e uma combinação são várias faturas. Um serviço
com uma região e poucos usuários costuma ser mais bem servido por um Application Gateway e nada na
frente dele; o curso não cita preço de nenhum dos quatro, pelo motivo que a lição 1 deu, e a lista de
preços da Microsoft é onde compará-los.
