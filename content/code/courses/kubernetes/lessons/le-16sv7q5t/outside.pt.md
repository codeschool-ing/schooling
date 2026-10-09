---
title: De fora do cluster: NodePort e LoadBalancer
version: 1
---

Um ClusterIP só existe dentro do cluster. **Os outros dois tipos não o substituem; acrescentam um
caminho de entrada por cima dele**, e cada um é o tipo anterior mais uma coisa.

## NodePort: a mesma porta em todos os nós

```yaml
apiVersion: v1
kind: Service
metadata:
  name: shop-nodeport
spec:
  type: NodePort
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: http
    nodePort: 30080
```

```
ana@laptop:~/shop$ kubectl apply -f shop-nodeport.yaml
service/shop-nodeport created
ana@laptop:~/shop$ kubectl get service shop-nodeport
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
shop-nodeport   NodePort   10.96.233.128   <none>        80:30080/TCP   0s
ana@laptop:~/shop$ kubectl get nodes -o custom-columns=NAME:.metadata.name,ADDRESS:.status.addresses[0].address
NAME                 ADDRESS
shop-control-plane   172.18.0.2
shop-worker          172.18.0.3
shop-worker2         172.18.0.4
ana@laptop:~/shop$ curl -s 172.18.0.3:30080; curl -s localhost:8080
shop 1.0 on shop-59d88b64fd-h8h2m
shop 1.0 on shop-59d88b64fd-cp8t7
```

`80:30080/TCP`: a porta 80 no endereço interno do Service, como antes, mais a 30080 em todos os nós. O
primeiro `curl` chamou o `shop-worker` diretamente pelo endereço; o segundo foi para a 8080 do laptop,
que este cluster liga à 30080 do nó do plano de controle. **Qualquer nó responde por todo Service
NodePort**, rode ou não um pod dele ali. NodePorts vêm de uma faixa fixa, de 30000 a 32767 por padrão,
e é por isso que nada público é servido diretamente num deles: algo na frente traduz uma porta normal
para ela.

## LoadBalancer: um endereço próprio

Esse algo é o que um Service LoadBalancer pede. O Kubernetes não fornece o balanceador: **ele pede um
à nuvem**, por um componente chamado cloud controller manager, e escreve no Service o endereço que
recebe. Neste laptop, o `cloud-provider-kind` do projeto kind faz o papel da nuvem, respondendo a cada
Service LoadBalancer com um pequeno proxy Envoy na rede do Docker. É um programa só, das releases do projeto,
rodado na sua máquina num segundo terminal, com `sudo` porque cria containers e rotas de rede; ele
continua rodando e registrando até o `Ctrl+C`:

```sh
ARCH=$(dpkg --print-architecture)
curl -fsSL https://github.com/kubernetes-sigs/cloud-provider-kind/releases/download/v0.12.0/cloud-provider-kind_0.12.0_linux_$ARCH.tar.gz | tar xz cloud-provider-kind
sudo ./cloud-provider-kind
```

A máquina em que o curso foi gravado não tem IPv6, então a cópia dela foi compilada do código-fonte da
mesma release com um endereço trocado de `::` para `0.0.0.0`; numa máquina com IPv6, como uma VM
Ubuntu, a da release funciona como está.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: shop-lb
spec:
  type: LoadBalancer
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: http
```

```
ana@laptop:~/shop$ kubectl apply -f shop-lb.yaml
service/shop-lb created
ana@laptop:~/shop$ kubectl get service shop-lb
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
shop-lb   LoadBalancer   10.96.228.208   172.18.0.5    80:31269/TCP   7s
ana@laptop:~/shop$ curl -s 172.18.0.5
shop 1.0 on shop-59d88b64fd-cp8t7
ana@laptop:~/shop$ docker ps --filter label=io.x-k8s.cloud-provider-kind.cluster=shop --format "{{.Names}}\t{{.Image}}"
kindccm-698a25f42e67	envoyproxy/envoy:v1.33.2
ana@laptop:~/shop$ kubectl delete service shop-lb
service "shop-lb" deleted from default namespace
```

`EXTERNAL-IP` é `172.18.0.5`, um endereço na rede do Docker que não pertence a nenhum nó, e a loja
responde nele na porta 80, sem NodePort na URL. Por baixo, o Service também ganhou um NodePort,
`31269`, que é para onde o balanceador manda o tráfego: um LoadBalancer é um NodePort com uma máquina
na frente. A linha do `docker ps` é essa máquina. Numa nuvem seria o balanceador do provedor, cobrado
por hora, e é por isso que um cluster com cinquenta Services costuma ter um balanceador na frente de um
controlador de Ingress (lição 16) e não cinquenta.

| tipo | alcançável de | construído sobre |
|---|---|---|
| ClusterIP | dentro do cluster | um endereço da faixa de serviços e uma lista de endpoints |
| NodePort | tudo o que alcança um nó | um ClusterIP, mais uma porta em cada nó |
| LoadBalancer | o endereço que um provedor atribui | um NodePort, mais um balanceador na frente dos nós |
