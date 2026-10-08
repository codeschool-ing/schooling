---
title: Linkerd, comparado pelo projeto
version: 2
---

O **Linkerd** é o outro mesh do título desta aula, e o mais antigo: ele deu nome à categoria em 2016. A
segunda versão trocou o proxy em JVM da primeira por um pequeno, escrito em Rust só para esse trabalho, o
`linkerd2-proxy`, em vez do Envoy. Essa é a aposta central dele: um proxy que faz menos, gasta menos e
quase não precisa de configuração.

**A máquina em que esta aula foi gravada não conseguiu baixar as imagens do Linkerd**, publicadas no
registro dele e no do GitHub, ambos recusados pela rede dela. Então o Linkerd não está rodando aqui. O que
a ferramenta de linha de comando dele consegue fazer sem um cluster é renderizar o que instalaria:

```
ana@obs:~/shop$ linkerd version --client
Client version: edge-26.9.3
```

```
ana@obs:~/shop$ linkerd install --crds --set installGatewayAPI=true 2>/dev/null | grep '^kind:' | sort | uniq -c
     14 kind: CustomResourceDefinition
```

```
ana@obs:~/shop$ linkerd install --ignore-cluster | grep -E '^kind:|image:' | sort | uniq -c
      1             image: cr.l5d.io/linkerd/controller:edge-26.9.3
      5         image: cr.l5d.io/linkerd/controller:edge-26.9.3
      6         image: cr.l5d.io/linkerd/proxy:edge-26.9.3
      2       image:
      5 kind: ClusterRole
      5 kind: ClusterRoleBinding
      2 kind: ConfigMap
      1 kind: CronJob
      3 kind: Deployment
      1 kind: MutatingWebhookConfiguration
      1 kind: Namespace
      3 kind: Role
      2 kind: RoleBinding
      5 kind: Secret
      8 kind: Service
      4 kind: ServiceAccount
      2 kind: ValidatingWebhookConfiguration
```

As definições de recursos customizados vêm primeiro, catorze, incluindo as da própria Gateway API. Depois o plano de controle: três Deployments, um webhook que acrescenta o proxy aos pods novos (o `MutatingWebhookConfiguration`) e duas imagens, `controller` e `proxy`, o `linkerd2-proxy` que ficaria ao lado de cada pod no mesh, os do plano de controle incluídos. As duas linhas `image:` vazias são imagens escritas como nome e versão em linhas separadas. O formato é o do Istio: um plano de controle, um injetor e um proxy por pod.

As diferenças que importam na escolha, ditas a partir do projeto de cada um e não de uma execução:

| | Istio | Linkerd |
|---|---|---|
| proxy | Envoy, de uso geral e muito configurável | `linkerd2-proxy`, escrito só para o mesh |
| TLS mútuo | ligado no modo permissivo; estrito por política | ligado por padrão entre pods no mesh |
| telemetria | estatísticas do Envoy, com rótulos por origem e destino | métricas por rota pela extensão `viz` |
| controle de tráfego | rico: regras de roteamento, espelhamento, injeção de falhas | menor, sobre recursos padrão da Gateway API |
| modo sem sidecar | modo ambient | nenhum; o proxy fica por pod |

**Nenhuma das escolhas muda o argumento de observabilidade desta aula.** As duas dão contagens de
requisições, latências e taxas de sucesso por par de serviços sem código, as duas protegem o tráfego com
identidade de carga, e as duas param no mesmo lugar: veem requisições, não para que elas serviam.

Quando terminar com o cluster, apague os dois namespaces e depois o cluster:

```sh
kubectl delete namespace shop-mesh outside
kind delete cluster --name lab
```
