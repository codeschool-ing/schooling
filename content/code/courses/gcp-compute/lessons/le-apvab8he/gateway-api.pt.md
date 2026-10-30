---
title: A Gateway API
version: 1
---

O Ingress era um objeto fazendo três trabalhos: escolher o tipo de balanceador, guardar o endereço
e o certificado, e listar as rotas. **A Gateway API divide esses trabalhos em três tipos de objeto,
para que quem cuida de cada trabalho possa mudá-lo sem mexer nos outros.** Ela é a sucessora do
Ingress no projeto Kubernetes, e o GKE a implementa com os mesmos balanceadores.

## Três objetos, três donos

| objeto | quem cuida | o que diz |
|---|---|---|
| `GatewayClass` | o Google, no GKE | qual tipo de balanceador: global externo, regional externo, interno |
| `Gateway` | quem roda a plataforma | um balanceador: endereço, listeners, certificados |
| `HTTPRoute` | cada equipe | quais hosts e caminhos vão para quais Services dela |

O GKE fornece as classes; as que uma loja encontra primeiro são `gke-l7-global-external-managed`, o
mesmo Application Load Balancer externo que o Ingress da seção 03 montou, e `gke-l7-rilb`, um
interno regional. Uma equipe nunca edita o Gateway para acrescentar uma rota: escreve um
`HTTPRoute` no próprio namespace que se liga ao Gateway, e o Gateway decide quais namespaces podem
se ligar.

## Ligando

No GKE os objetos da Gateway API precisam ser instalados no cluster, e o recurso de cluster tem
uma configuração para isso. Salve isto como `cluster.tf` na pasta `lb` da seção 03:

```hcl
# lb/cluster.tf
resource "google_container_cluster" "shop" {
  name                = "shop"
  location            = "southamerica-east1"
  enable_autopilot    = true
  deletion_protection = false

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }
}
```

O plan agora tem o endereço e o cluster:

```
ana@laptop:~/gcp/lb$ terraform plan -no-color | grep -E '^  #|enable_autopilot|channel|^Plan'
  # google_compute_global_address.shop_web will be created
  # google_container_cluster.shop will be created
      + enable_autopilot                         = true
          + channel = "CHANNEL_STANDARD"
      + release_channel (known after apply)
Plan: 2 to add, 0 to change, 0 to destroy.
```

O provider conhece três valores, um deles para desligar, e diz isso quando recebe um quarto:

```
ana@laptop:~/gcp/lb$ sed -i 's/CHANNEL_STANDARD/STANDARD/' cluster.tf
ana@laptop:~/gcp/lb$ terraform validate -no-color

Error: expected gateway_api_config.0.channel to be one of ["CHANNEL_DISABLED" "CHANNEL_EXPERIMENTAL" "CHANNEL_STANDARD"], got STANDARD

  with google_container_cluster.shop,
  on cluster.tf line 9, in resource "google_container_cluster" "shop":
   9:     channel = "STANDARD"
```

`CHANNEL_STANDARD` instala a parte estável da API; `CHANNEL_EXPERIMENTAL` acrescenta o que ainda
está mudando no projeto original, o que é para experimentar, não para produção.

## O Gateway e a rota da loja

Vêm da documentação do Google; não foram executados. O Gateway da plataforma, no endereço
reservado na seção 03:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shop
  namespace: infra
spec:
  gatewayClassName: gke-l7-global-external-managed
  addresses:
    - type: NamedAddress
      value: shop-web
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
```

E a rota da equipe da loja, mandando nove requisições em dez para o `orders` atual e uma para a
versão nova:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: orders
  namespace: shop
spec:
  parentRefs:
    - name: shop
      namespace: infra
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api/orders
      backendRefs:
        - name: orders
          port: 80
          weight: 90
        - name: orders-next
          port: 80
          weight: 10
```

**Pesos são o recurso que o Ingress nunca teve**: um canário entre dois Services, escrito pela
equipe dona deles, sem mudança no Gateway. É a mesma ideia que a lição 9 aplica a revisões do
Cloud Run, aqui entre dois Deployments.

## Ingress ou Gateway

Os dois montam os mesmos balanceadores, e um Ingress que funciona pode continuar funcionando. Para
qualquer coisa nova, a documentação do Google e o projeto Kubernetes apontam para a Gateway API:
ela divide a responsabilidade, tem pesos e correspondência por cabeçalho embutidos, e a
`GatewayClass` torna o tipo de balanceador uma escolha explícita em vez de uma anotação. O cluster
da loja é novo, então começa com um Gateway.
