---
title: Uma política só é tão real quanto o plugin que a aplica
version: 1
---

Dois namespaces desta vez. `shop` roda a loja, o seu Service e um pod busybox chamado `front`, que faz
o papel do front-end web da loja. `other` roda um pod busybox chamado `stranger`, que pertence a outra
equipe. Nada impede `stranger` de chamar a loja, porque nada impede pod nenhum de chamar qualquer
outro.

A primeira política fecha o namespace `shop` para tudo:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: shop
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

**`podSelector: {}` seleciona todos os pods do namespace**, e `policyTypes: [Ingress]` sem regras
`ingress` quer dizer que nenhum deles aceita conexão de ninguém. Essa é a primeira política comum para
um namespace: negar tudo, e depois permitir o que for preciso, um caminho de cada vez.

## Aplicada, e ignorada

O cluster de laboratório de sempre roda o plugin de rede do próprio kind, o kindnet:

```
ana@laptop:~/shop$ kubectl get pods -n kube-system -l app=kindnet -o name
pod/kindnet-4jljk
pod/kindnet-m8cch
pod/kindnet-q6l2x
ana@laptop:~/shop$ kubectl apply -f deny-all.yaml
networkpolicy.networking.k8s.io/deny-all created
ana@laptop:~/shop$ kubectl -n other exec stranger -- wget -qO- -T 3 shop.shop
shop 1.0 on shop-774b84ff8c-pd5v4
```

**A política foi aceita, e `stranger` mesmo assim recebeu a resposta.** O API server guardou o objeto e
conferiu a sintaxe. Ele não a aplica, e não tem como saber se alguma coisa vai aplicar. Esse trabalho
é do plugin de rede. O kindnet carrega um motor de políticas, e o log dele diz o que aconteceu nesta
máquina:

```
ana@laptop:~/shop$ kubectl -n kube-system logs $(kubectl -n kube-system get pods -l app=kindnet -o name | head -n 1) | grep -A 1 'syncing nftables'
I1006 18:17:37.603768       1 controller.go:817] "syncing nftables rules" logger="nftables-sync" error=<
	conn.Receive: netlink receive: no such file or directory
```

O motor programa o kernel pelo nftables, e o kernel deste laptop recusou o pedido. Nada mais reclamou.
Num cluster cujo plugin não tem suporte nenhum a políticas, não existe nem esta linha: **uma
NetworkPolicy que nada aplica parece exatamente com uma que funciona, até alguém testar.**

## A mesma política com Calico

O segundo cluster foi criado sem o kindnet e roda o Calico no lugar, instalado a partir do manifesto do
próprio Calico (`lab.sh calico`). Um `calico-node` por nó:

```
ana@laptop:~/shop$ kubectl get pods -n kube-system -l k8s-app=calico-node -o wide
NAME                READY   STATUS    RESTARTS   AGE   IP           NODE                 NOMINATED NODE   READINESS GATES
calico-node-cdb4z   1/1     Running   0          25s   172.18.0.4   shop-worker          <none>           <none>
calico-node-d67ph   1/1     Running   0          25s   172.18.0.2   shop-worker2         <none>           <none>
calico-node-lrn2c   1/1     Running   0          25s   172.18.0.3   shop-control-plane   <none>           <none>
```

O mesmo `stranger`, a mesma loja, antes e depois do mesmo arquivo:

```
ana@laptop:~/shop$ kubectl -n other exec stranger -- wget -qO- -T 3 shop.shop
shop 1.0 on shop-774b84ff8c-zmqss
ana@laptop:~/shop$ kubectl apply -f deny-all.yaml
networkpolicy.networking.k8s.io/deny-all created
ana@laptop:~/shop$ kubectl -n other exec stranger -- wget -qO- -T 3 shop.shop
wget: download timed out
command terminated with exit code 1
ana@laptop:~/shop$ kubectl -n shop exec front -- wget -qO- -T 3 shop
wget: download timed out
command terminated with exit code 1
```

Antes da política, a resposta voltou. Depois dela, `stranger` estourou o tempo, e `front` também, o
próprio front-end da loja no mesmo namespace. **Negar tudo quer dizer tudo**, inclusive os vizinhos. A
próxima seção abre o caminho de que `front` precisa.

Escolher um plugin de rede é em parte escolher isto: o Calico e o Cilium aplicam NetworkPolicy, o
Flannel sozinho não aplica, e o plugin padrão de um cluster gerenciado pode precisar ter o suporte a
políticas ligado. A lição 18 comparou plugins; esta é a coluna dessa comparação que mais importa.
