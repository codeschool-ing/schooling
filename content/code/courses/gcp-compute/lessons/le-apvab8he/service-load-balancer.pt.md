---
title: Um Service do tipo LoadBalancer
version: 1
---

Dentro do cluster, um Service dá a um conjunto de pods um endereço estável. Para alcançá-los de
fora, o Kubernetes sempre teve uma resposta que todo provedor implementa: **`type: LoadBalancer`.
No GKE essa linha faz o Google montar um balanceador de carga de verdade fora do cluster**, com
endereço IP próprio, regra de encaminhamento própria e linha própria na conta. Nada dentro do
cluster é esse balanceador; o GKE o cria no seu projeto e o mantém em dia com o Service.

## O manifesto

Este é o front-end `web` exposto do jeito mais simples. Vem da documentação do Google e não foi
executado: não há cluster neste laboratório onde aplicá-lo.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: shop
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 8080
```

No GKE isso produz um **Network Load Balancer de passagem**: ele trabalha na camada 4, repassa
conexões TCP aos nós ou pods sem lê-las, e é regional, na região do cluster. O endereço externo
aparece no status do Service um ou dois minutos depois de aplicado. Num cluster local como o kind,
que o curso `kubernetes` usa nas trilhas que o incluem, o mesmo manifesto deixa o endereço como
`<pending>` para sempre, porque não há ninguém ali para montar o balanceador; no GKE, há o Google.

## O que camada 4 quer dizer aqui

Um balanceador de passagem **vê conexões, não requisições.** Ele não consegue mandar `/orders`
para um serviço e `/` para outro, não termina TLS com um certificado gerenciado pelo Google e não
aplica política de segurança a um caminho HTTP. Cada Service desse tipo ganha balanceador e
endereço próprios, então uma loja com cinco serviços públicos assim tem cinco endereços e cinco
regras de encaminhamento, cada uma cobrada.

Isso o torna a ferramenta certa para tráfego que não é HTTP, um proxy de banco, um servidor de
jogo, um broker MQTT, e para serviços internos, que levam uma anotação:

```yaml
metadata:
  annotations:
    networking.gke.io/load-balancer-type: "Internal"
```

Com ela, o balanceador ganha um endereço dentro da VPC em vez de na internet, e é assim que um
serviço do cluster é oferecido a máquinas virtuais e a serviços do Cloud Run que alcançam a VPC do
jeito que a lição 12 descreveu.

## Mantendo o endereço

O endereço de um Service `LoadBalancer` pertence a esse Service. **Apague e recrie o Service, e o
endereço quase sempre é outro**, o que quebra todo registro DNS que apontava para ele. Um Service
de produção ou reserva um endereço regional estático e o nomeia no manifesto, ou, para HTTP, nem
usa esse tipo e deixa o Ingress da próxima seção ou o Gateway da seção 05 segurar um endereço
global para muitos serviços.
