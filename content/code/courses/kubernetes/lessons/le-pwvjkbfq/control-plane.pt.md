---
title: O plano de controle, aberto
version: 1
---

**"O master" ainda é um nome comum para o plano de controle, e ele sugere um programa que comanda o
cluster.** São quatro, mais um banco de dados, e são processos comuns que você pode listar. No cluster
do laptop eles rodam no nó chamado `shop-control-plane`:

```
ana@laptop:~/shop$ kubectl get pods -n kube-system -o wide --field-selector spec.nodeName=shop-control-plane
NAME                                         READY   STATUS    RESTARTS   AGE   IP           NODE                 NOMINATED NODE   READINESS GATES
coredns-559f6c778d-mtg29                     1/1     Running   0          14s   10.244.0.3   shop-control-plane   <none>           <none>
coredns-559f6c778d-snbdh                     1/1     Running   0          14s   10.244.0.2   shop-control-plane   <none>           <none>
etcd-shop-control-plane                      1/1     Running   0          23s   172.18.0.3   shop-control-plane   <none>           <none>
kindnet-5ddmg                                1/1     Running   0          14s   172.18.0.3   shop-control-plane   <none>           <none>
kube-apiserver-shop-control-plane            1/1     Running   0          23s   172.18.0.3   shop-control-plane   <none>           <none>
kube-controller-manager-shop-control-plane   1/1     Running   0          23s   172.18.0.3   shop-control-plane   <none>           <none>
kube-proxy-vzh6c                             1/1     Running   0          14s   172.18.0.3   shop-control-plane   <none>           <none>
kube-scheduler-shop-control-plane            1/1     Running   0          23s   172.18.0.3   shop-control-plane   <none>           <none>
```

Quatro dessas linhas são o plano de controle: `etcd`, `kube-apiserver`, `kube-controller-manager` e
`kube-scheduler`, cada um com o nome do nó acrescentado. O resto também roda neste nó e pertence a
outras lições: o `coredns` responde nomes dentro do cluster (lição 15), e o `kindnet` e o
`kube-proxy` rodam em todos os nós, como a próxima seção mostra.

| componente | o que faz |
|---|---|
| `kube-apiserver` | a única porta. Toda requisição, do `kubectl` ou de outro componente, chega aqui, é conferida e é guardada |
| `etcd` | um banco chave-valor que guarda todos os objetos. Só o API server fala com ele |
| `kube-scheduler` | encontra pods que ainda não têm nó e escolhe um para cada |
| `kube-controller-manager` | roda os controladores embutidos: deployments, ReplicaSets, nós, jobs e dezenas de outros |

## Como um plano de controle sobe antes de existir um

O API server é quem roda pods, então quem roda o API server? **O kubelet daquele nó, a partir de
arquivos**, sem pedir nada a ninguém:

```
ana@laptop:~/shop$ docker exec shop-control-plane ls /etc/kubernetes/manifests
etcd.yaml
kube-apiserver.yaml
kube-controller-manager.yaml
kube-scheduler.yaml
```

Um arquivo em `/etc/kubernetes/manifests` é um *pod estático*: o kubelet observa o diretório e roda o
que estiver descrito ali, e o API server mostra uma cópia somente leitura para o `kubectl` poder
listá-lo. O kubeadm, que o kind usa para montar cada nó, escreve esses quatro arquivos; a lição 47
roda o kubeadm à mão. O arquivo também é a configuração do API server, e três das flags dele dizem
muito:

```
ana@laptop:~/shop$ docker exec shop-control-plane grep -E "^ +- --(etcd-servers|secure-port|service-cluster-ip-range)" /etc/kubernetes/manifests/kube-apiserver.yaml
    - --etcd-servers=https://127.0.0.1:2379
    - --secure-port=6443
    - --service-cluster-ip-range=10.96.0.0/16
```

Ele chega ao etcd em `127.0.0.1:2379`, na mesma máquina, e por TLS. Escuta na porta `6443`, que é
onde o `kubectl` disca. E dá aos Services endereços de `10.96.0.0/16`, uma faixa que só existe
dentro do cluster.

## O que o etcd guarda

Tudo. Os objetos da lição 2 são chaves sob `/registry`, por tipo, namespace e nome. Isto lê só as
chaves, com o cliente do próprio etcd, de dentro do pod do etcd e com os certificados dele:

```
ana@laptop:~/shop$ kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/deployments/default --prefix --keys-only
/registry/deployments/default/web

ana@laptop:~/shop$ kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/pods/default --prefix --keys-only
/registry/pods/default/web-768c88b7c7-mlp9j

/registry/pods/default/web-768c88b7c7-v5pxq
```

Ali estão o Deployment que a Ana criou e os dois pods que vieram dele. **Perder o etcd é perder a
memória do cluster**: os containers em execução continuariam, e nada saberia para que eles servem.
É por isso que um plano de controle de produção roda três ou cinco membros do etcd, que concordam em
cada escrita por maioria, e é por isso que a lição 47 faz um backup dele antes de qualquer outra coisa. E é
por isso que só um programa pode falar com ele: toda conferência que o API server faz numa
requisição seria inútil se outra porta levasse direto aos dados.
