---
title: O AGIC, um controller no cluster para um gateway fora dele
version: 1
---

O nome sugere um ingress controller como o NGINX: um proxy rodando no cluster, com as requisições
passando por ele. **O AGIC não carrega requisição nenhuma.** O Application Gateway Ingress
Controller é um pod que observa o cluster e reescreve a configuração de um Azure Application
Gateway, o load balancer regional de camada 7 da lição 22 de `azure-foundations`, pelo Azure
Resource Manager. O gateway fica numa sub-rede só dele, na rede virtual do cluster, e manda cada
requisição direto ao endereço IP de um pod. Toda propriedade do AGIC, boa ou ruim, vem desse
arranjo: o tráfego nunca passa pelos nodes do cluster na entrada, e o estado do cluster só chega ao
gateway tão rápido quanto uma escrita no ARM.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 334\" role=\"img\" aria-label=\"O arranjo do AGIC. Um cliente chega a um Application Gateway numa sub-rede só dele. O gateway manda cada requisição direto ao endereço de um pod, 10.244.1.2 e 10.244.1.4 para a shop 1.0 e 10.244.1.3 para a shop 1.1, sem NodePort e sem kube-proxy. Dentro do cluster, o AGIC, um pod, observa o API server em busca de mudanças em Ingress, Service e pods, escreve a configuração do gateway no Azure Resource Manager, e o Resource Manager a aplica no gateway.\"><rect x=\"12\" y=\"22\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"72\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um cliente</text><rect x=\"196\" y=\"12\" width=\"232\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"312\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">Application Gateway</text><text x=\"312\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">numa sub-rede só dela</text><rect x=\"500\" y=\"12\" width=\"208\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"604\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Azure Resource Manager</text><line x1=\"132\" y1=\"42\" x2=\"194\" y2=\"42\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><polygon points=\"194,42 187.6,44.7 187.6,39.3\" fill=\"var(--paper-dim)\"></polygon><line x1=\"498\" y1=\"42\" x2=\"430\" y2=\"42\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><polygon points=\"430,42 436.4,39.3 436.4,44.7\" fill=\"var(--amber)\"></polygon><text x=\"464\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">aplica</text><rect x=\"12\" y=\"112\" width=\"696\" height=\"210\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o cluster AKS, na mesma rede virtual</text><rect x=\"40\" y=\"214\" width=\"118\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"99\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.244.1.2</text><text x=\"99\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shop 1.0</text><line x1=\"312\" y1=\"74\" x2=\"99\" y2=\"212\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><polygon points=\"99,212 102.9,206.2 105.9,210.8\" fill=\"var(--phosphor)\"></polygon><rect x=\"172\" y=\"214\" width=\"118\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"231\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.244.1.4</text><text x=\"231\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shop 1.0</text><line x1=\"312\" y1=\"74\" x2=\"231\" y2=\"212\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><polygon points=\"231,212 231.9,205.1 236.6,207.8\" fill=\"var(--phosphor)\"></polygon><rect x=\"304\" y=\"214\" width=\"118\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"363\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.244.1.3</text><text x=\"363\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shop 1.1</text><line x1=\"312\" y1=\"74\" x2=\"363\" y2=\"212\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><polygon points=\"363,212 358.2,206.9 363.3,205.0\" fill=\"var(--phosphor)\"></polygon><text x=\"221\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">requisições, direto aos endereços dos pods</text><text x=\"221\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem NodePort, sem kube-proxy</text><rect x=\"500\" y=\"150\" width=\"190\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">AGIC, um pod</text><rect x=\"500\" y=\"250\" width=\"190\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API server</text><text x=\"595\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Ingress, Service, pods</text><line x1=\"595\" y1=\"248\" x2=\"595\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><polygon points=\"595,198 597.7,204.4 592.3,204.4\" fill=\"var(--paper-dim)\"></polygon><text x=\"605\" y=\"223\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">observa</text><line x1=\"640\" y1=\"148\" x2=\"640\" y2=\"74\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><polygon points=\"640,74 642.7,80.4 637.3,80.4\" fill=\"var(--amber)\"></polygon><text x=\"632\" y=\"96\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">escreve a configuração</text></svg>", "caption": "Dois caminhos. As requisições descem, do gateway aos pods, sem passar pelo AGIC. Uma mudança no cluster dá a volta longa, pelo AGIC e pelo Resource Manager, e o gateway só fica sabendo de um pod depois que esse caminho foi percorrido.", "same": ["Application Gateway", "Azure Resource Manager", "API server", "Ingress, Service, pods", "shop 1.0", "shop 1.1"]}
```

## Endereços de pod como backend pool

A documentação da Microsoft, lida em 30 de outubro de 2026, descreve o ciclo assim: o AGIC monitora
um subconjunto dos recursos do Kubernetes, traduz o estado do cluster em configuração do
Application Gateway e a aplica no ARM. Uma Ingress vira um listener e uma regra; o Service que ela
cita vira um backend pool; e os membros desse pool não são o endereço do Service, e sim os dos pods
dele. O gateway **fala com os pods direto pelos endereços privados, sem NodePort e sem kube-proxy**
no meio, o que tira um salto e o segundo load balancer que um desenho com NodePort exigiria.

No lab, esses endereços são o que as EndpointSlices dos Services guardam. São eles que o AGIC
escreveria nos dois backend pools:

```
ana@laptop:~/azure$ kubectl get endpointslices -n shop
NAME              ADDRESSTYPE   PORTS   ENDPOINTS               AGE
shop-v1-0-5hmkh   IPv4          8080    10.244.1.2,10.244.1.4   3s
shop-v1-1-jzdhd   IPv4          8080    10.244.1.3              3s
```

Dois pods atrás de `shop-v1-0`, um atrás de `shop-v1-1`. No kind, `10.244.1.x` é um endereço que só
o cluster alcança. No AKS o gateway tem de alcançá-lo a partir da própria sub-rede, e por isso o
plugin de rede importa: a Microsoft recomenda Azure CNI ou Azure CNI Overlay para o AGIC, e com
Overlay pede o AGIC 1.9.1 ou mais novo e uma sub-rede do gateway que não passe de `/24`, delegada a
`Microsoft.Network/applicationGateways`.

## O gateway é do AGIC, inteiro

**Por padrão o AGIC se considera dono do Application Gateway inteiro a que está ligado**, e
sobrescreve qualquer configuração que nenhuma Ingress descreva. O exemplo da documentação é um
listener para `prod.contoso.com` criado à mão no gateway: o AGIC o apaga em segundos. Um time que já
tem um Application Gateway servindo outros sites tem duas escolhas, um gateway separado para o
cluster ou o modo compartilhado do AGIC, que só a instalação por Helm oferece.

Só os SKUs `Standard_v2` e `WAF_v2` funcionam com o AGIC. O segundo é o motivo pelo qual muitos
times escolhem o AGIC: o web application firewall do gateway fica então na frente da shop sem salto
extra, e o autoscaling dele não usa nada da capacidade do cluster.

## Add-on ou Helm

O AGIC é instalado de um de dois jeitos, e a Microsoft dá suporte aos dois:

| | add-on do AKS | Helm |
|---|---|---|
| instalado por | `az aks enable-addons --addons ingress-appgw` | um chart que você instala e atualiza |
| atualizações | automáticas | à mão |
| por cluster | um AGIC, apontando para um gateway | vários, ou vários AGICs num gateway |
| modo compartilhado, e `ProhibitedTargets` | não | sim |
| `reconcilePeriodSeconds`, `armAuth.type` | não configuráveis | configuráveis |

A própria ajuda da linha de comando cita o add-on e as opções dele. É texto real da versão da CLI
deste curso, e não precisa de conta:

```
ana@laptop:~/azure$ az aks enable-addons --help | grep -- '- ingress-appgw'
        - ingress-appgw            : enable Application Gateway Ingress Controller addon.
ana@laptop:~/azure$ az aks enable-addons --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --appgw-(id|subnet-cidr) '
 --appgw-id : Resource Id of an existing Application Gateway to use with AGIC. Use with ingress-azure addon. 
 --appgw-subnet-cidr : Subnet CIDR to use for a new subnet created to deploy the Application Gateway. Use with ingress-azure addon. 
```

`--appgw-subnet-cidr` faz o add-on criar um gateway no node resource group, numa sub-rede nova desse
tamanho; `--appgw-id` o aponta para um que já existe. Com uma assinatura, ativá-lo no cluster da
lição 11 seria o comando abaixo, **não executado neste curso: precisa de uma assinatura**:

```sh
az aks enable-addons --resource-group shop --name shop-aks --addons ingress-appgw --appgw-subnet-cidr 10.20.8.0/24
```

## O atraso, e o acoplamento

Toda mudança no cluster que importa para o gateway, um pod que sobe, um pod que para, um rolling
update, um scale-in, tem de fazer o mesmo caminho: o AGIC a vê, calcula uma configuração nova,
manda para o ARM, e o gateway a aplica. O próprio tutorial da Microsoft avisa que o gateway pode
levar um minuto para receber uma atualização. **Até receber, o gateway continua mandando
requisições a um pod que já foi embora**, e o cliente vê um `502`. É para isso que serve a anotação
`connection-draining` na Ingress da shop: a documentação a recomenda para reduzir erros 502
intermitentes durante a remoção de pods, rolling deployments e scale-in, e
`connection-draining-timeout` define por quanto tempo, 30 segundos por padrão.

Os probes também ficam acoplados. O AGIC monta o health probe do gateway a partir do
`readinessProbe` do pod quando há um com `httpGet`, e senão faz o probe no próprio caminho da
Ingress, `/` no caso da shop, e espera um status de 200 a 399. A shop responde `/` com 404, `no such
page`, então **sem o probe do `shop.yaml` ou a anotação `health-probe-path`, o gateway marcaria
todo pod da shop como não saudável** e não serviria nada. Duas configurações do readiness probe,
`initialDelaySeconds` e `successThreshold`, nem são levadas para o gateway.

E a configuração do gateway é uma função do cluster. Passar da instalação por Helm para o add-on
significa remover um AGIC antes de ativar o outro. A documentação diz que as mudanças no cluster
entre um e outro não são refletidas no gateway, que fica com a última configuração recebida, e
aconselha fazer isso fora do horário comercial. Vários AGICs num mesmo gateway precisam da
instalação por Helm, e um upgrade do cluster que troca o plugin de rede é, nas palavras da
documentação, coisa para agendar numa janela de manutenção, as janelas da lição 11.

## Onde o AGIC fica

O AGIC só lê a API Ingress, com os limites da seção 01. Toda página da documentação dele agora abre
com a mesma dica: considere o Application Gateway for Containers, assunto da seção 04. O AGIC tem
suporte e continua sendo o jeito de pôr um Application Gateway existente, com a sua política de
firewall, na frente de um cluster. Para um cluster novo, é a opção da qual a própria Microsoft
aponta para longe.
