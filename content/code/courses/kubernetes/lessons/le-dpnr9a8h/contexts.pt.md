---
title: O arquivo kubeconfig e os contextos dele
version: 1
---

**O kubectl não guarda estado próprio nenhum sobre clusters.** Tudo o que ele sabe está num arquivo,
`~/.kube/config`, e uma requisição vai para onde esse arquivo mandar. A Ana agora tem dois clusters
no laptop, o cluster `shop` que as lições usam e um `study` ao lado, e o kind escreveu os dois no
arquivo:

```
ana@laptop:~/shop$ kubectl config get-contexts
CURRENT   NAME         CLUSTER      AUTHINFO     NAMESPACE
*         kind-shop    kind-shop    kind-shop    
          kind-study   kind-study   kind-study   
```

Um **contexto** é um nome para três coisas ao mesmo tempo: um cluster (onde está o API server), um
usuário (as credenciais a apresentar) e, opcionalmente, um namespace. O asterisco marca o contexto
atual, aquele que todo comando usa a menos que se diga outra coisa. `--minify` mostra o arquivo
reduzido a esse contexto:

```
ana@laptop:~/shop$ kubectl config view --minify
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://127.0.0.1:44489
  name: kind-shop
contexts:
- context:
    cluster: kind-shop
    user: kind-shop
  name: kind-shop
current-context: kind-shop
kind: Config
users:
- name: kind-shop
  user:
    client-certificate-data: DATA+OMITTED
    client-key-data: DATA+OMITTED
```

Três listas, `clusters`, `contexts` e `users`, e o contexto liga um item da primeira a um da terceira.
O servidor é `https://127.0.0.1:44489`, a porta que o kind publicou para o API server deste cluster, e
os certificados aparecem omitidos. **O arquivo guarda credenciais que funcionam**: quem consegue lê-lo
é administrador dos dois clusters, então ele é tratado como uma chave privada, nunca vai para um
commit e nunca é colado num chamado.

## Trocando

```
ana@laptop:~/shop$ kubectl config use-context kind-study
Switched to context "kind-study".
ana@laptop:~/shop$ kubectl get nodes
NAME                  STATUS     ROLES           AGE   VERSION
study-control-plane   NotReady   control-plane   11s   v1.37.0
study-worker          NotReady   <none>          1s    v1.37.0
study-worker2         NotReady   <none>          1s    v1.37.0
ana@laptop:~/shop$ kubectl config use-context kind-shop
Switched to context "kind-shop".
ana@laptop:~/shop$ kubectl --context kind-study get nodes -o name
node/study-control-plane
node/study-worker
node/study-worker2
```

`use-context` muda o contexto atual no arquivo, então a troca vale até a próxima, em todo terminal. Os
nós de `study` ainda estão `NotReady` porque aquele cluster tinha subido segundos antes; o que importa
é que o `kubectl` chegou até eles. Para um comando só contra outro cluster, `--context` deixa o arquivo
em paz, e esse é o hábito mais seguro em scripts: **um `use-context` esquecido é como um comando
feito para um cluster de teste chega à produção.**

## Namespaces, e o padrão

Um contexto pode levar um namespace, e então todo comando sem `-n` acontece nele:

```
ana@laptop:~/shop$ kubectl create namespace dev
namespace/dev created
ana@laptop:~/shop$ kubectl config set-context --current --namespace=dev
Context "kind-shop" modified.
ana@laptop:~/shop$ kubectl get pods
No resources found in dev namespace.
```

`dev` existe e está vazio. A mesma requisição com `-n` chega a outro namespace, e
`--all-namespaces`, ou `-A`, chega a todos:

```
ana@laptop:~/shop$ kubectl get pods -n kube-system -l component=etcd
NAME                      READY   STATUS    RESTARTS   AGE
etcd-shop-control-plane   1/1     Running   0          46s
ana@laptop:~/shop$ kubectl get pods --all-namespaces --no-headers | wc -l
13
```

Treze pods no cluster inteiro, todos eles do próprio cluster. **Um namespace muda onde um nome é
procurado, e mais nada**: ele não isola a rede nem limita o que um pod pode usar, a menos que outra
coisa seja montada para isso, como as lições 20 e 24 fazem.
