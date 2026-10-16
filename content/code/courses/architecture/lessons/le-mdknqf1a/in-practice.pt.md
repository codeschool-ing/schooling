---
title: Onde você vai encontrá-los
version: 1
---

Poucas equipes rodam o Consul e um gateway à mão como o laboratório fez, porque as plataformas em que elas
implantam já contêm os dois:

| plataforma | o registro | descoberta | o gateway |
| --- | --- | --- | --- |
| Kubernetes | o etcd, guardando todo pod e a prontidão dele | um Service: um nome e um endereço estáveis na frente dos pods prontos, pelo DNS do cluster | um controlador de Ingress ou da Gateway API: NGINX, Traefik, Envoy Gateway |
| uma service mesh no Kubernetes | o mesmo | o sidecar escolhe uma instância, do lado do cliente | um gateway de entrada construído sobre o proxy da mesh |
| AWS sem Kubernetes | o Cloud Map, ou os grupos de destino do balanceador | DNS, ou o balanceador | o API Gateway ou um Application Load Balancer |
| máquinas virtuais | o Consul, como no laboratório | o DNS ou a API HTTP do Consul | qualquer um dos gateways acima, lendo o Consul |

As ideias são as que o laboratório construiu, com outros nomes. Uma **readiness probe** do Kubernetes é o
`/health` do laboratório; um pod que falha nela é tirado dos endpoints do Service exatamente como o
`stock-2` foi tirado das rotas do gateway. Um **Service** é descoberta do lado do servidor com o
balanceamento feito pelo próprio nó. E o etcd é o armazenamento Raft em que o arranjo inteiro confia, e é
por isso que clusters Kubernetes rodam três ou cinco nós de plano de controle.

Para a Quitanda, ainda um monólito com um serviço de estoque ao lado, a parte útil hoje é o gateway: uma
porta, com TLS, limites de taxa e ids de requisição num lugar só. O registro chega com a plataforma quando
as instâncias começarem a se mudar sozinhas.

Quando terminar, pare o laboratório:

```sh
docker compose down
```
