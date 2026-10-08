---
title: O arquivo que sabe onde cada cluster está
version: 1
---

O kubectl não sabe de clusters. Ele lê um **kubeconfig**, o `~/.kube/config` a menos que digam o
contrário, que guarda três listas e um ponteiro: clusters (um endereço e uma CA), usuários (uma
credencial), contextos (um cluster, um usuário e um namespace opcional, sob um nome só), e o
`current-context`, o usado quando você não diz nada. A lição 7 usou um contexto. Aqui há dois clusters,
criados um depois do outro: `shop` pelo `./up.sh`, e `eu` pelo mesmo script com o outro nome escrito
nele, para ter os mesmos três nós e as imagens da loja:

```sh
./up.sh
sed 's/--name shop/--name eu/' up.sh > up-eu.sh && sh up-eu.sh
```

O kind acrescentou cada um ao mesmo arquivo:

```
ana@laptop:~/shop$ kubectl config get-contexts
CURRENT   NAME        CLUSTER     AUTHINFO    NAMESPACE
*         kind-eu     kind-eu     kind-eu     
          kind-shop   kind-shop   kind-shop   
ana@laptop:~/shop$ kubectl config current-context
kind-eu
ana@laptop:~/shop$ kubectl --context kind-shop get nodes
NAME                 STATUS   ROLES           AGE   VERSION
shop-control-plane   Ready    control-plane   70s   v1.37.0
shop-worker          Ready    <none>          56s   v1.37.0
shop-worker2         Ready    <none>          56s   v1.37.0
ana@laptop:~/shop$ kubectl --context kind-eu get nodes
NAME               STATUS   ROLES           AGE   VERSION
eu-control-plane   Ready    control-plane   31s   v1.37.0
eu-worker          Ready    <none>          16s   v1.37.0
eu-worker2         Ready    <none>          16s   v1.37.0
```

**O contexto atual é o último que foi mexido**, que é o `kind-eu` só porque ele foi criado em segundo. O
`--context` manda um comando para outro lugar sem mover o ponteiro. Os dois clusters têm a mesma forma e
nada mais em comum, e o arquivo mostra a única coisa que os separa para o kubectl, um endereço:

```
ana@laptop:~/shop$ kubectl config view -o jsonpath='{range .clusters[*]}{.name}{"  "}{.cluster.server}{"\n"}{end}'
kind-eu  https://127.0.0.1:46033
kind-shop  https://127.0.0.1:34351
```

## O comando que foi para o cluster errado

O ponteiro é compartilhado por todo terminal que lê o arquivo, e muda em silêncio. É assim que o
incidente clássico acontece: uma pessoa troca para olhar a produção numa janela, depois roda um delete em
outra, achando que ela ainda aponta para o staging. Primeiro, o mesmo Deployment nos dois clusters, cada
comando mandado com `--context`:

```
ana@laptop:~/shop$ for c in kind-shop kind-eu; do kubectl --context $c create deployment shop --image=shop:1.0 --replicas=2; done
deployment.apps/shop created
deployment.apps/shop created
ana@laptop:~/shop$ for c in kind-shop kind-eu; do echo "== $c"; kubectl --context $c get pods -l app=shop -o wide | cut -c1-90; done
== kind-shop
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE           NOM
shop-774b84ff8c-f82k7   1/1     Running   0          3s    10.244.1.3   shop-worker    <no
shop-774b84ff8c-l68m9   1/1     Running   0          3s    10.244.2.3   shop-worker2   <no
== kind-eu
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE         NOMIN
shop-774b84ff8c-29x6l   1/1     Running   0          3s    10.244.1.3   eu-worker    <none
shop-774b84ff8c-dhw8l   1/1     Running   0          3s    10.244.2.3   eu-worker2   <none
```

Depois o ponteiro é movido, e um delete é mandado sem nomear cluster:

```
ana@laptop:~/shop$ kubectl config use-context kind-shop
Switched to context "kind-shop".
ana@laptop:~/shop$ kubectl delete deployment shop
deployment.apps "shop" deleted from default namespace
ana@laptop:~/shop$ for c in kind-shop kind-eu; do echo "$c: $(kubectl --context $c get deployments --no-headers 2>/dev/null | wc -l) deployment(s)"; done
kind-shop: 0 deployment(s)
kind-eu: 1 deployment(s)
```

O `delete` não nomeou cluster nenhum, então foi para o atual. **Ele estava certo aqui só porque a linha
anterior tinha acabado de definir o contexto.** Três hábitos evitam que isso dê errado:

- **Scripts e pipelines sempre passam `--context`**, ou usam um kubeconfig próprio com exatamente um
  contexto dentro. Um pipeline que depende do ponteiro depende do que rodou antes dele.
- **O prompt mostra o contexto atual**, então a resposta está na tela antes de o comando ser digitado.
- **Credenciais de produção ficam num arquivo separado**, definido por `KUBECONFIG` para a sessão que
  precisa delas, então um comando perdido em outro lugar não as alcança.
