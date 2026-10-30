---
title: Quatro serviços em dois eixos
version: 1
---

**O Azure tem quatro serviços que ficam na frente das suas máquinas e repartem o tráfego entre elas,
e o erro comum é enxergar quatro marcas da mesma coisa e escolher a mais barata.** São quatro
respostas a duas perguntas separadas, e cada pergunta tem duas respostas:

- **Quanto do tráfego ele lê?** Um serviço de camada 4 lê endereços e portas e deixa passar todo o
  resto sem tocar. Um serviço de camada 7 lê cada pedido HTTP, o nome do host, o caminho e os
  cabeçalhos, e decide pedido a pedido.
- **Onde ele fica?** Um serviço regional mora numa região, na frente de máquinas daquela região. Um
  global fica na frente de várias regiões ao mesmo tempo e decide a qual região um usuário chega.

Duas perguntas com duas respostas cada dão quatro caixas, e cada caixa tem exatamente um serviço:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l22-quadrant\" aria-label=\"Uma grade de dois por dois. Colunas: camada 4, que lê endereços e portas, e camada 7, que lê pedidos HTTP. Linhas: regional e global. Regional e camada 4 é o Azure Load Balancer. Regional e camada 7 é o Application Gateway. Global e camada 4 é o Traffic Manager, que responde no DNS e não carrega tráfego. Global e camada 7 é o Front Door, um proxy nas localidades de borda da Microsoft.\"><text x=\"320.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">camada 4: endereços e portas</text><text x=\"565.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">camada 7: pedidos HTTP</text><text x=\"105.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">regional</text><text x=\"105.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">global</text><rect x=\"200.0\" y=\"50.0\" width=\"240.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Load Balancer</text><text x=\"320.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">espalha fluxos TCP e UDP</text><text x=\"320.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o endereço de quem chama chega</text><rect x=\"445.0\" y=\"50.0\" width=\"240.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Application Gateway</text><text x=\"565.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um proxy reverso na sua rede</text><text x=\"565.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">roteia por host e caminho</text><rect x=\"200.0\" y=\"180.0\" width=\"240.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Traffic Manager</text><text x=\"320.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">responde no DNS</text><text x=\"320.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nenhum pacote passa por ele</text><rect x=\"445.0\" y=\"180.0\" width=\"240.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Front Door</text><text x=\"565.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um proxy na borda</text><text x=\"565.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cache e WAF antes de qualquer região</text></svg>", "caption": "Duas perguntas com duas respostas cada, e um serviço em cada caixa.", "same": ["Application Gateway", "Front Door", "Load Balancer", "Traffic Manager", "global", "regional"]}
```

## Load Balancer, regional e de camada 4

O Azure Load Balancer espalha conexões TCP e UDP pelas máquinas de um **backend pool**. Ele lê as
cinco coisas que identificam um fluxo, os dois endereços, as duas portas e o protocolo, e calcula um
hash delas para escolher uma máquina, de modo que todo pacote de uma conexão chega à mesma máquina.
Ele nunca abre a conexão e nunca vê uma URL; para as máquinas atrás dele, o endereço de quem chamou
chega como origem. Uma **health probe** pergunta a cada máquina, em intervalos, se ela está apta, e
uma máquina que para de responder para de receber fluxos novos.

Ele vem em duas formas que dividem o nome: um load balancer **público** tem um endereço público como
front end, e um **interno** tem um endereço privado de uma sub-rede, na frente de máquinas que outras
máquinas chamam. A loja usa os dois: um público para os clientes, e um interno na frente da camada de
aplicação, que só a camada web chama. **O SKU Basic foi aposentado em 30 de setembro de 2025**, então
todo load balancer que você cria hoje é Standard, e a próxima seção monta um.

## Application Gateway, regional e de camada 7

O Application Gateway é um **proxy reverso**: ele encerra a conexão HTTPS do cliente, lê o pedido e
abre uma conexão própria com um backend que ele escolhe. Como lê o pedido, ele faz o que o Load
Balancer não faz: manda `/api/` para um pool e todo o resto para outro, hospeda vários sites num
endereço, reescreve cabeçalhos e mantém um usuário na mesma máquina com um cookie. Com o SKU WAF ele
também inspeciona o pedido atrás de ataques comuns, o que é um web application firewall e fica no
curso `azure-operations`.

Três fatos decidem como ele se encaixa numa rede:

- **Ele precisa de uma sub-rede só dele**, que não pode ter mais nada. A loja dá a ele a
  `snet-agw`, `10.20.5.0/24`, na `vnet-shop-prod`;
- **os backends veem o endereço do gateway, não o do cliente**, já que foi o gateway que abriu a
  conexão. O endereço do cliente viaja no cabeçalho `X-Forwarded-For`;
- **só existem agora os SKUs v2**, Standard_v2 e WAF_v2, que escalam sozinhos e podem abranger zonas.
  Os SKUs v1 foram aposentados em 28 de abril de 2026.

## Traffic Manager, global e respondendo no DNS

O Traffic Manager é o diferente da turma: **nenhum pacote seu passa por ele.** Ele é um serviço de
DNS. Um nome como `shop.example` é um CNAME para um nome do Traffic Manager em `trafficmanager.net`.
Quando o resolvedor de um usuário pergunta por ele, o Traffic Manager responde com o endereço de um
dos seus endpoints, escolhido pelo **método de roteamento** do perfil: por prioridade, por peso, pela
menor latência a partir do usuário, pelo país do usuário ou pela faixa de endereço do usuário. Dali em
diante o usuário fala direto com o endpoint.

Esse desenho tem um preço: uma decisão tomada no DNS dura enquanto a resposta estiver em cache. Quando
um endpoint cai, o Traffic Manager para de citá-lo, e os usuários que guardam a resposta antiga
continuam tentando o endereço que caiu até a cópia deles expirar. Um TTL curto encurta essa espera e
multiplica as consultas, que o Traffic Manager cobra por milhão.

## Front Door, global e de camada 7

O Front Door é a versão global do proxy reverso. A conexão de um usuário termina na mais próxima das
**localidades de borda** da Microsoft, que são mais de cem, e o Front Door leva o pedido pela rede
própria da Microsoft até a região que deve responder. No caminho ele pode guardar em cache o que for
cacheável, como faz uma rede de distribuição de conteúdo, e aplicar regras de WAF na borda, antes que
um ataque chegue a qualquer região.

Ele é vendido em duas camadas, Standard e Premium, com o Premium acrescentando os conjuntos de regras
gerenciadas do WAF e conexões privadas com as origens por Private Link, que é o assunto da lição 19.
Uma terceira, a **classic**, é o produto anterior, e a Microsoft a está aposentando: não construa nada
novo sobre ela.

A última seção desta lição pergunta ao DNS público sobre dois nomes da própria Microsoft, e encontra
tanto o Traffic Manager quanto o Front Door nas respostas.
