---
title: A Gateway API separa a entrada das rotas
version: 1
---

**O Ingress punha tudo num objeto só**: a entrada, os hosts, os caminhos e os serviços por trás deles,
tudo editado por quem tivesse permissão de editar Ingress. Num cluster dividido por várias equipes,
isso é poder demais para cada equipe ou uma fila na porta da equipe de plataforma. A Gateway API o
divide em objetos que correspondem às pessoas:

| objeto | escrito por | diz |
|---|---|---|
| GatewayClass | quem instala o controlador | qual controlador implementa esse tipo de entrada |
| Gateway | quem opera o cluster | uma entrada: quais portas, quais protocolos, quais namespaces podem pendurar rotas |
| HTTPRoute | a equipe dona da aplicação | para estes hosts e caminhos, mande o tráfego para estes Services |

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: traefik
spec:
  controllerName: traefik.io/gateway-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: public
spec:
  gatewayClassName: traefik
  listeners:
  - name: web
    protocol: HTTP
    port: 8000
    allowedRoutes:
      namespaces:
        from: Same
```

O Gateway `public` escuta HTTP na porta do controlador e aceita rotas só do próprio namespace, que é
uma decisão que os operadores do cluster tomam uma vez. A rota é o arquivo da equipe da aplicação:

```schooling-example
{"language": "yaml", "file": "route.yaml", "parts": [{"code": "apiVersion: gateway.networking.k8s.io/v1\nkind: HTTPRoute\nmetadata:\n  name: shop\nspec:\n  parentRefs:\n  - name: public\n", "note": "**Um HTTPRoute, preso a um Gateway pelo nome.** `parentRefs` é como a equipe da aplicação diz a que entrada as suas rotas pertencem, sem editar essa entrada."}, {"code": "  hostnames:\n  - shop.example.test\n", "note": "**Para qual host esta rota responde.** Uma requisição para qualquer outro host não chega a estas regras."}, {"code": "  rules:\n  - matches:\n    - path:\n        type: PathPrefix\n        value: /admin\n      headers:\n      - name: X-Staff\n        value: \"yes\"\n    backendRefs:\n    - name: admin\n      port: 80\n", "note": "**A primeira regra precisa das duas condições**: um caminho em `/admin` e o cabeçalho `X-Staff: yes`. O Ingress não tem campo para cabeçalho; a Gateway API tem."}, {"code": "  - backendRefs:\n    - name: shop\n      port: 80\n", "note": "**Todo o resto neste host vai para a loja.** Uma regra sem `matches` é o caminho padrão."}]}
```

```
ana@laptop:~/shop$ kubectl apply -f gateway.yaml -f route.yaml
gatewayclass.gateway.networking.k8s.io/traefik created
gateway.gateway.networking.k8s.io/public created
httproute.gateway.networking.k8s.io/shop created
ana@laptop:~/shop$ kubectl get gatewayclass,gateway
NAME                                             CONTROLLER                      ACCEPTED   AGE
gatewayclass.gateway.networking.k8s.io/traefik   traefik.io/gateway-controller   True       5s

NAME                                       CLASS     ADDRESS   PROGRAMMED   AGE
gateway.gateway.networking.k8s.io/public   traefik             True         5s
ana@laptop:~/shop$ kubectl get httproute shop -o jsonpath="{.status.parents[0].conditions[*].type}"; echo
Accepted ResolvedRefs
```

Todo objeto dá retorno. A GatewayClass está `ACCEPTED` pelo Traefik, o Gateway está `PROGRAMMED`, e
as condições da rota dizem `Accepted` (o Gateway a aceitou) e `ResolvedRefs` (os dois Services
existem). **Esse status é a diferença para o Ingress perdido da seção anterior**: uma rota que ninguém
executa não mostraria condição nenhuma, ou diria por quê.

```
ana@laptop:~/shop$ curl -s -H "Host: shop.example.test" localhost:8080/admin
shop 1.0 on shop-774b84ff8c-gw795
ana@laptop:~/shop$ curl -s -H "Host: shop.example.test" -H "X-Staff: yes" localhost:8080/admin
admin 1.0 on admin-76fdf69bb5-679z5
```

Sem o cabeçalho, `/admin` chega à loja pela regra padrão; com `X-Staff: yes`, chega a `admin`. Rotear
por cabeçalho, dividir o tráfego por peso (a lição 36 faz isso para um canary) e rotear gRPC e TLS
fazem parte do padrão, enquanto o Ingress precisava de uma anotação diferente para cada controlador.

```
ana@laptop:~/shop$ kubectl api-resources --api-group=gateway.networking.k8s.io
NAME                 SHORTNAMES   APIVERSION                          NAMESPACED   KIND
backendtlspolicies   btlspolicy   gateway.networking.k8s.io/v1        true         BackendTLSPolicy
gatewayclasses       gc           gateway.networking.k8s.io/v1        false        GatewayClass
gateways             gtw          gateway.networking.k8s.io/v1        true         Gateway
grpcroutes                        gateway.networking.k8s.io/v1        true         GRPCRoute
httproutes                        gateway.networking.k8s.io/v1        true         HTTPRoute
referencegrants      refgrant     gateway.networking.k8s.io/v1beta1   true         ReferenceGrant
```

A API é um conjunto de CRDs, instalado ao lado do controlador, e é por isso que este cluster precisou
recebê-los: a lição 43 mostra o que isso significa. Os tipos principais dela são `v1`, tão estáveis
quanto o resto do Kubernetes.
