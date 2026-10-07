---
title: Egress, e o DNS que todo mundo esquece
version: 1
---

Regras de ingress protegem um pod de quem chama. **Regras de egress limitam o que um pod pode
chamar**, e é isso que contém um pod comprometido: um front-end que só alcança a loja não pode ser
usado para alcançar o banco, o API server ou a internet.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: front-egress
  namespace: shop
spec:
  podSelector:
    matchLabels:
      app: front
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: shop
    ports:
    - port: 8080
```

`front-egress` seleciona `front` e permite um destino: pods rotulados `app: shop`, porta 8080. Todo o
resto que sai de `front` agora é recusado, e isso inclui algo de que a loja precisa antes de qualquer
pacote chegar a ela:

```
ana@laptop:~/shop$ kubectl apply -f deny-egress.yaml
networkpolicy.networking.k8s.io/front-egress created
ana@laptop:~/shop$ kubectl -n shop exec front -- wget -qO- -T 3 shop
wget: bad address 'shop'
command terminated with exit code 1
ana@laptop:~/shop$ kubectl -n shop exec front -- wget -qO- -T 3 shop.shop.svc.cluster.local
wget: bad address 'shop.shop.svc.cluster.local'
command terminated with exit code 1
```

**`bad address 'shop'` é uma falha de DNS, não de conexão.** Antes de conectar, o `wget` pergunta ao
CoreDNS o que `shop` quer dizer, e o CoreDNS é um pod em `kube-system` na porta 53, que a política não
permitiu. O nome completo falha do mesmo jeito, porque o que está bloqueado é a pergunta, não o nome.
Essa é a surpresa mais comum com políticas de egress, e a correção é uma política que todo namespace
com regras de egress acaba tendo:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: front-dns
  namespace: shop
spec:
  podSelector:
    matchLabels:
      app: front
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
```

Os dois seletores estão dentro de uma única entrada `to`, então eles se combinam: pods rotulados
`k8s-app: kube-dns` **dentro** do namespace chamado `kube-system`. Escritos como duas entradas
separadas, cada uma com o seu hífen, eles significariam qualquer pod rotulado `kube-dns` em qualquer
lugar, **ou** todo pod de `kube-system`, o que é bem mais amplo. Esse único hífen é o jeito mais fácil
de errar uma NetworkPolicy.

```
ana@laptop:~/shop$ kubectl apply -f allow-dns.yaml
networkpolicy.networking.k8s.io/front-dns created
ana@laptop:~/shop$ kubectl -n shop exec front -- wget -qO- -T 3 shop
shop 1.0 on shop-774b84ff8c-zmqss
ana@laptop:~/shop$ kubectl -n shop exec front -- wget -qO- -T 3 http://kubernetes.default:443
wget: download timed out
command terminated with exit code 1
```

Os nomes voltam a resolver e a loja responde. O API server, que `front` não tem motivo para chamar, não
responde: `kubernetes.default` resolveu para o endereço dele, e a conexão então estourou o tempo.
**Duas políticas, e `front` alcança exatamente duas coisas.**

| política | seleciona | permite |
|---|---|---|
| `deny-all` | todo pod em `shop` | nada entrando |
| `allow-front` | `app: shop` | entrada de `app: front`, porta 8080 |
| `allow-monitoring` | `app: shop` | entrada de namespaces rotulados `purpose: monitoring`, porta 8080 |
| `front-egress` | `app: front` | saída para `app: shop`, porta 8080 |
| `front-dns` | `app: front` | saída para `kube-dns` em `kube-system`, porta 53 |
