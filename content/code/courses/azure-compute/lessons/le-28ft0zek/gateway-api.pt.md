---
title: A Gateway API, três recursos para três donos
version: 1
---

É tentador ler a Gateway API como uma Ingress maior, o mesmo arquivo com os campos que faltavam. Os
campos estão lá, pesos e casamento de cabeçalhos entre eles, mas essa é a mudança menor. **A Gateway
API divide a porta de entrada em recursos separados, um para cada pessoa que é dona de uma parte
dela.** Uma *GatewayClass* diz qual controller implementa os gateways, e pertence a quem instala
esse controller. Um *Gateway* é um ponto de entrada, os listeners, as portas e que namespaces podem
usá-lo, e pertence ao time que roda o cluster. Uma *HTTPRoute* diz que requisições vão para quais
Services, e pertence ao time que entrega a aplicação. Cada um aponta para o de cima, e cada dono
pode receber permissão só sobre o seu recurso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 372\" role=\"img\" aria-label=\"Quatro recursos e seus donos. Uma GatewayClass, azure-alb-external, no cluster todo, de quem instala o controller, diz qual controller implementa os gateways. Um Gateway, shop-gateway no namespace infra, do time do cluster, tem um listener na porta 80 e diz que namespaces podem se ligar a ele. Uma HTTPRoute, shop no namespace shop, do time da shop, manda os testadores para a 1.1 e o resto 90 para 10. Cada um aponta para o de cima. Ao lado, uma ReferenceGrant no namespace finance, do time de finanças, deixa as rotas em shop citarem o Service dele.\"><text x=\"16\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">de quem é</text><text x=\"300\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o recurso</text><text x=\"452\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que ele diz</text><text x=\"16\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">quem instala o controller</text><rect x=\"200\" y=\"36\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"300\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">GatewayClass</text><text x=\"300\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">azure-alb-external</text><text x=\"300\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no cluster todo</text><text x=\"452\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">qual controller implementa os gateways</text><text x=\"16\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o time do cluster</text><rect x=\"200\" y=\"122\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"300\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">Gateway</text><text x=\"300\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-gateway</text><text x=\"300\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">namespace infra</text><text x=\"452\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">porta 80, e que namespaces podem se ligar</text><text x=\"16\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o time da shop</text><rect x=\"200\" y=\"208\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"300\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">HTTPRoute</text><text x=\"300\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop</text><text x=\"300\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">namespace shop</text><text x=\"452\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">testadores na 1.1, o resto 90 para 10</text><line x1=\"300\" y1=\"206\" x2=\"300\" y2=\"184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><polygon points=\"300,184 302.7,190.4 297.3,190.4\" fill=\"var(--paper-dim)\"></polygon><line x1=\"300\" y1=\"120\" x2=\"300\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><polygon points=\"300,98 302.7,104.4 297.3,104.4\" fill=\"var(--paper-dim)\"></polygon><text x=\"310\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aponta para o de cima</text><text x=\"16\" y=\"330\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o time de finanças</text><rect x=\"200\" y=\"300\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"300\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">ReferenceGrant</text><text x=\"300\" y=\"332\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-routes</text><text x=\"300\" y=\"348\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">namespace finance</text><text x=\"452\" y=\"330\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rotas em shop podem citar o Service dele</text><line x1=\"300\" y1=\"298\" x2=\"300\" y2=\"270\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><polygon points=\"300,270 302.7,276.4 297.3,276.4\" fill=\"var(--amber)\"></polygon></svg>", "caption": "Um arquivo por dono. As setas são referências escritas no arquivo de baixo: uma rota cita o seu gateway, um gateway cita a sua classe. A permissão aponta para o outro lado, porque só o dono do que é referido pode autorizar.", "same": ["namespace infra", "namespace shop", "namespace finance"]}
```

## As definições não fazem parte do Kubernetes

Um cluster não conhece a Gateway API até as custom resource definitions dela serem instaladas. O
projeto Kubernetes as publica como um arquivo por release, em dois canais: *standard*, os recursos
estáveis, e *experimental*. O AKS instala o canal standard para você com `--enable-gateway-api`, e
a documentação dele, lida em 30 de outubro de 2026, diz que bundle ele põe em que versão do
Kubernetes: `v1.6.1` para a 1.37. O cluster do lab roda a 1.37, então recebe o mesmo bundle, da
página de releases:

```
ana@laptop:~/azure$ curl -sSLO https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml
ana@laptop:~/azure$ grep -c "^kind: CustomResourceDefinition" standard-install.yaml
10
ana@laptop:~/azure$ kubectl apply --server-side -f standard-install.yaml
customresourcedefinition.apiextensions.k8s.io/backendtlspolicies.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/gatewayclasses.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/gateways.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/grpcroutes.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/httproutes.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/listenersets.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/referencegrants.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/tcproutes.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/tlsroutes.gateway.networking.k8s.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/udproutes.gateway.networking.k8s.io serverside-applied
validatingadmissionpolicy.admissionregistration.k8s.io/safe-upgrades.gateway.networking.k8s.io serverside-applied
validatingadmissionpolicybinding.admissionregistration.k8s.io/safe-upgrades.gateway.networking.k8s.io serverside-applied
ana@laptop:~/azure$ kubectl get crd gateways.gateway.networking.k8s.io -o jsonpath='{.metadata.annotations}{"\n"}'
{"api-approved.kubernetes.io":"https://github.com/kubernetes-sigs/gateway-api/pull/4530","gateway.networking.k8s.io/bundle-version":"v1.6.1","gateway.networking.k8s.io/channel":"standard"}
```

O arquivo traz dez definições e uma ValidatingAdmissionPolicy que recusa definições experimentais
por cima das standard. O `--server-side` deixa com o API server o registro de quem definiu cada campo, em vez de copiar
cada uma dessas definições grandes numa anotação própria, como faria um `apply` comum. O último comando imprimiu as
anotações que a documentação da Microsoft manda conferir numa instalação gerenciada: a versão do
bundle e o canal. No AKS, mais uma, `app.kubernetes.io/managed-by: aks`, diz quem as mantém em dia,
e o bundle avança sozinho quando o cluster passa para a minor version seguinte.

## A metade da infraestrutura

A classe e o gateway são o arquivo do time do cluster. A classe cita o controller da seção 04,
`alb.networking.azure.io/alb-controller`, com o nome de classe que a Microsoft dá a ele; no AKS o
add-on cria esse objeto e você não o escreveria. O gateway escuta HTTP na porta 80 e só aceita
rotas de namespaces com o rótulo `gateway-access: "true"`, que o `shop.yaml` deu ao da shop. Salve
como `gateway.yaml`:

```yaml
# gateway.yaml: the cluster team's half, a class and one gateway.
apiVersion: v1
kind: Namespace
metadata:
  name: infra
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: azure-alb-external
spec:
  controllerName: alb.networking.azure.io/alb-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shop-gateway
  namespace: infra
spec:
  gatewayClassName: azure-alb-external
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            gateway-access: "true"
```

```
ana@laptop:~/azure$ kubectl apply -f gateway.yaml
namespace/infra created
gatewayclass.gateway.networking.k8s.io/azure-alb-external created
gateway.gateway.networking.k8s.io/shop-gateway created
ana@laptop:~/azure$ kubectl get gatewayclass,gateway -A
NAME                                                        CONTROLLER                               ACCEPTED   AGE
gatewayclass.gateway.networking.k8s.io/azure-alb-external   alb.networking.azure.io/alb-controller   Unknown    0s

NAMESPACE   NAME                                             CLASS                ADDRESS   PROGRAMMED   AGE
infra       gateway.gateway.networking.k8s.io/shop-gateway   azure-alb-external             Unknown      0s
ana@laptop:~/azure$ kubectl get gateway shop-gateway -n infra -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}'
Accepted=Unknown Pending: Waiting for controller
Programmed=Unknown Pending: Waiting for controller
```

**Os dois objetos foram aceitos, e nenhum está funcionando.** `Unknown` com a razão `Pending` e a
mensagem `Waiting for controller` não foi escrito por um controller: é o padrão que a própria
definição põe em `status`, para que um gateway que ninguém reivindicou diga isso em vez de não
dizer nada. No AKS com o ALB Controller rodando, a condição da classe passaria a `True` e o gateway
ficaria `Programmed`, com um endereço. Aqui nada reivindica `alb.networking.azure.io/alb-controller`,
e nada vai reivindicar.

## A metade da aplicação

A rota é o arquivo do time da shop, no namespace da shop. Ela se liga ao gateway em `infra`,
responde por `shop.example.com` e tem duas regras. Testadores que mandam `x-shop-canary: yes`
sempre recebem a 1.1; todo o resto é dividido entre as duas versões, 90 para 10. Salve como
`route.yaml`:

```yaml
# route.yaml: the shop team's half, a canary for 1.1.
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: shop
  namespace: shop
spec:
  parentRefs:
  - name: shop-gateway
    namespace: infra
  hostnames:
  - shop.example.com
  rules:
  - name: testers
    matches:
    - headers:
      - name: x-shop-canary
        value: "yes"
    backendRefs:
    - name: shop-v1-1
      port: 80
  - name: everyone
    backendRefs:
    - name: shop-v1-0
      port: 80
      weight: 90
    - name: shop-v1-1
      port: 80
      weight: 10
```

```
ana@laptop:~/azure$ kubectl apply -f route.yaml
httproute.gateway.networking.k8s.io/shop created
ana@laptop:~/azure$ kubectl get httproute -n shop
NAME   HOSTNAMES              AGE
shop   ["shop.example.com"]   0s
ana@laptop:~/azure$ kubectl get httproute shop -n shop -o yaml | sed -n '/^spec:/,$p'
spec:
  hostnames:
  - shop.example.com
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: shop-gateway
    namespace: infra
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: shop-v1-1
      port: 80
      weight: 1
    matches:
    - headers:
      - name: x-shop-canary
        type: Exact
        value: "yes"
      path:
        type: PathPrefix
        value: /
    name: testers
  - backendRefs:
    - group: ""
      kind: Service
      name: shop-v1-0
      port: 80
      weight: 90
    - group: ""
      kind: Service
      name: shop-v1-1
      port: 80
      weight: 10
    matches:
    - path:
        type: PathPrefix
        value: /
    name: everyone
```

A saída termina em `spec`: **a rota não tem `status` nenhum**. Um Gateway traz um
padrão; o status de uma rota é uma lista com uma entrada por gateway que a processou, escrita pelo
controller desse gateway, e nenhum controller escreveu uma.

O API server preencheu o que o arquivo deixou de fora, e vale ler os padrões. O casamento de
cabeçalho é `Exact`. Uma regra sem `matches` casa tudo abaixo de `/`, então as duas regras agora
têm um `PathPrefix` de `/`. E `shop-v1-1` na primeira regra tem peso 1, o que, com um backend só,
quer dizer tudo.

Então como uma requisição com o cabeçalho sabe a que regra pertence, se as duas casam? A
especificação dá a ordem: um caminho `Exact` primeiro, depois o prefixo mais longo, depois um
método, depois **o maior número de cabeçalhos casados**. Os dois caminhos são `/`, nenhuma cita
método, e `testers` tem um cabeçalho contra nenhum, então a requisição de um testador vai para a
1.1 toda vez. A ordem das regras no arquivo só desempata o que sobrar depois de tudo isso.

Um **peso é uma proporção, não uma porcentagem**. Cada backend recebe o seu peso dividido pela
soma dos pesos da sua lista, então `90` e `10` querem dizer o mesmo que `9` e `1`, e a soma não
precisa dar 100. Os Container Apps da lição 8 exigiam 100; esta API não. O texto da própria
definição diz isso, e o `kubectl explain` o imprime:

```
ana@laptop:~/azure$ kubectl explain httproute.spec.rules.backendRefs.weight | sed -n '/^DESCRIPTION/,/^$/p'
DESCRIPTION:
    Weight specifies the proportion of requests forwarded to the referenced
    backend. This is computed as weight/(sum of all weights in this
    BackendRefs list). For non-zero values, there may be some epsilon from
    the exact proportion defined here depending on the precision an
    implementation supports. Weight is not a percentage and the sum of
    weights does not need to equal 100.
    
    If only one backend is specified and it has a weight greater than 0, 100%
    of the traffic is forwarded to that backend. If weight is set to 0, no
    traffic should be forwarded for this entry. If unspecified, weight
    defaults to 1.
    
    Support for this field varies based on the context where used.
    
```

## Atravessando um namespace

A rota chegou a um gateway em outro namespace porque o `allowedRoutes` do gateway deixou:
ligar uma rota a um gateway é a única referência que o lado do gateway controla. Toda outra
referência entre namespaces precisa de uma **ReferenceGrant** no namespace referido, escrita pelos
donos dele. Se a rota da shop mandasse `/export` para o Service da exportação financeira no
namespace `finance`, o time de finanças teria de permitir. Salve como `grant.yaml`:

```yaml
# grant.yaml: the finance team lets routes in shop refer to its export Service.
apiVersion: v1
kind: Namespace
metadata:
  name: finance
---
apiVersion: gateway.networking.k8s.io/v1
kind: ReferenceGrant
metadata:
  name: shop-routes
  namespace: finance
spec:
  from:
  - group: gateway.networking.k8s.io
    kind: HTTPRoute
    namespace: shop
  to:
  - group: ""
    kind: Service
    name: export
```

```
ana@laptop:~/azure$ kubectl apply -f grant.yaml
namespace/finance created
referencegrant.gateway.networking.k8s.io/shop-routes created
ana@laptop:~/azure$ kubectl get referencegrant -n finance
NAME          AGE
shop-routes   1s
```

A permissão é conferida pelo controller, toda vez que ele monta a configuração, e remover a
permissão tem de revogar o que ela permitia. O API server só a guarda.

## O que o API server recusa, e o que ele não consegue

As definições trazem a sua própria validação, então alguns erros nunca chegam ao etcd. Uma rota com
três deles, salva como `bad-route.yaml`:

```yaml
# bad-route.yaml: three mistakes the definition catches.
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: shop-bad
  namespace: shop
spec:
  parentRefs:
  - name: shop-gateway
    namespace: infra
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: orders
    backendRefs:
    - name: shop-v1-0
      weight: 90
    - name: shop-v1-1
      port: 80
      weight: 1000001
```

O `--dry-run=server` a manda ao API server para todas as verificações, e não guarda nada:

```
ana@laptop:~/azure$ kubectl apply --dry-run=server -f bad-route.yaml
The HTTPRoute "shop-bad" is invalid: 
* spec.rules[0].backendRefs[1].weight: Invalid value: 1000001: spec.rules[0].backendRefs[1].weight in body should be less than or equal to 1000000
* spec.rules[0].backendRefs[0]: Invalid value: Must have port for Service reference
* spec.rules[0].matches[0].path: Invalid value: value must be an absolute path and start with '/' when type one of ['Exact', 'PathPrefix']
```

Um caminho que não começa com `/`, um peso acima do máximo de 1.000.000, e um Service citado sem
porta, os três numa só resposta. Agora um erro de outro tipo, o nome de um Service com um dígito
errado:

```
ana@laptop:~/azure$ sed 's/name: shop-v1-0/name: shop-v1-2/' route.yaml > typo.yaml
ana@laptop:~/azure$ kubectl apply --dry-run=server -f typo.yaml
httproute.gateway.networking.k8s.io/shop configured (server dry run)
```

**Aceito.** Não existe Service chamado `shop-v1-2`, e o API server não procura; conferir isso é
trabalho do controller. Um controller o reportaria na rota, e a especificação diz o que ele tem de
fazer enquanto isso: as requisições que iriam para um backend inválido são respondidas com `500`,
na proporção do peso dele. Esse erro de digitação, no backend de peso 90, responderia nove
requisições em dez com erro.

O lab não instala controller. As implementações que rodariam aqui são proxies de outros
fornecedores, e nenhuma é a que o AKS roda; instalar uma mostraria um gateway funcionando, mas não
o do Azure. O que o lab mostrou é a parte que é igual em toda implementação: os recursos, os
padrões deles e a validação deles. A seção 04 dá um controller à classe.

O cluster não é mais necessário depois desta seção. Apague-o:

```
ana@laptop:~/azure$ kind delete cluster --name shop
Deleting cluster "shop" ...
Deleted nodes: ["shop-control-plane" "shop-worker"]
```
