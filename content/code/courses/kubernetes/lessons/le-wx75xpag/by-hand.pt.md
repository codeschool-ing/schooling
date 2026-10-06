---
title: O ciclo, feito à mão
version: 1
---

**O GitOps se apoia numa regra: o estado desejado do cluster é o que um repositório git diz**, e toda
mudança no cluster é primeiro uma mudança nesse repositório. O repositório aqui se chama `platform`, e
guarda a loja como um diretório do Kustomize, da lição 38:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      containers:
      - name: shop
        image: shop:1.0
```

```
ana@laptop:~/shop/platform$ git log --oneline
efea582 shop 1.0, two copies
```

O ciclo tem dois passos, e o primeiro é comparar:

```
ana@laptop:~/shop/platform$ kubectl diff -k shop | grep -E "^[-+] " | head -n 5
+  creationTimestamp: "2026-10-06T21:07:25Z"
+  generation: 1
+  name: shop
+  namespace: default
+  uid: 990e0278-fe65-43f7-86c2-77048fd4c762
```

`kubectl diff` pergunta ao API server o que aplicar mudaria. Aqui o Deployment ainda não existe, então
tudo é novo. Depois o segundo passo, aplicar, e a comparação de novo:

```
ana@laptop:~/shop/platform$ kubectl apply -k shop
deployment.apps/shop created
ana@laptop:~/shop/platform$ kubectl diff -k shop; echo "diff exit status: $?"
diff exit status: 0
```

**Um status de saída 0 do `kubectl diff` quer dizer que o cluster bate com o repositório**; 1 quer dizer
que não bate. Esse único número é o que uma ferramenta de GitOps calcula, para toda aplicação, a cada
poucos minutos.

## Uma mudança passa pelo git

A versão 1.1 é lançada mudando o arquivo e fazendo commit, não mexendo no cluster:

```
ana@laptop:~/shop/platform$ sed -i 's/image: shop:1.0/image: shop:1.1/' shop/deployment.yaml
ana@laptop:~/shop/platform$ git commit -qam "shop 1.1" && git log --oneline
be6246c shop 1.1
efea582 shop 1.0, two copies
ana@laptop:~/shop/platform$ kubectl diff -k shop | grep -E "^[-+] "
-  generation: 1
+  generation: 2
-      - image: shop:1.0
+      - image: shop:1.1
ana@laptop:~/shop/platform$ kubectl apply -k shop
deployment.apps/shop configured
```

O commit diz quem mudou o quê e quando, e por quê, se a mensagem for boa. Numa equipe ele chega por um
pull request, então a mudança foi revisada antes de existir em qualquer lugar, e o histórico do cluster
é o histórico do repositório. **Ninguém precisou de acesso ao cluster para fazer a mudança**, só ao
repositório, e esse é o argumento de segurança do GitOps tanto quanto o de conveniência.
