---
title: Aplicando overlays, e por que o ConfigMap tem um hash
version: 1
---

`kubectl apply -k` monta um overlay e aplica o resultado num passo só:

```
ana@laptop:~/shop$ kubectl create namespace staging && kubectl create namespace production
namespace/staging created
namespace/production created
ana@laptop:~/shop$ kubectl apply -k deploy/overlays/staging
configmap/shop-settings-staging-ckt68hf7g8 created
service/shop-staging created
deployment.apps/shop-staging created
ana@laptop:~/shop$ kubectl apply -k deploy/overlays/production
configmap/shop-settings-f655md8fbd created
service/shop created
deployment.apps/shop created
ana@laptop:~/shop$ kubectl get deployments -A -l env -L env
NAMESPACE    NAME           READY   UP-TO-DATE   AVAILABLE   AGE   ENV
production   shop           3/3     3            3           1s    production
staging      shop-staging   1/1     1            1           1s    staging
```

**Uma base, dois ambientes, lado a lado**, cada um no seu namespace e rotulado com o seu nome. Nada na
base menciona nenhum dos dois.

## Uma mudança na base

A saudação muda na base, então todo ambiente deveria recebê-la:

```
ana@laptop:~/shop$ sed -i 's/GREETING=hello/GREETING=welcome/' deploy/base/kustomization.yaml
ana@laptop:~/shop$ kubectl diff -k deploy/overlays/production | grep -E "^[-+] " | head -n 12
-  generation: 1
+  generation: 2
-            name: shop-settings-f655md8fbd
+            name: shop-settings-k59c4b8286
+  GREETING: welcome
+  creationTimestamp: "2026-10-06T21:06:33Z"
+  labels:
+    env: production
+  name: shop-settings-k59c4b8286
+  namespace: production
+  uid: 94b071bc-15e7-4427-8696-b5745ebc833a
```

`kubectl diff` compara o que o overlay produziria com o que o cluster tem. O ConfigMap é um objeto
novo, `shop-settings-k59c4b8286`, porque o conteúdo mudou e o hash também; e o Deployment mudou
também, porque a referência dele ao ConfigMap mudou. **Essa segunda mudança é o motivo do hash**: um
Deployment cujo template de pod muda publica pods novos, então a configuração nova chega a todo pod. Um
ConfigMap editado no lugar com o mesmo nome não mudaria nada no ambiente dos pods em execução, como a
lição 13 constatou.

```
ana@laptop:~/shop$ kubectl apply -k deploy/overlays/production
configmap/shop-settings-k59c4b8286 created
service/shop unchanged
deployment.apps/shop configured
ana@laptop:~/shop$ kubectl -n production get configmaps
NAME                       DATA   AGE
kube-root-ca.crt           1      4s
shop-settings-f655md8fbd   1      4s
shop-settings-k59c4b8286   1      2s
```

`deployment.apps/shop configured`, e o rollout veio em seguida. O ConfigMap antigo continua lá, sem
uso. O `kubectl apply` nunca apaga o que um overlay deixa de produzir; a limpeza é feita com
`kubectl apply --prune` e um seletor de rótulo, ou por uma ferramenta de GitOps, assunto da lição 39.

| | Helm | Kustomize |
|---|---|---|
| as diferenças vivem em | valores, passados a templates | overlays e patches sobre manifestos simples |
| arquivos que o kubectl aplica sozinho | não, são templates | sim |
| registro de releases e rollback | sim, `helm history` e `rollback` | não; o histórico é o do git |
| instalar software de terceiros | o jeito comum | possível, menos comum |

Os dois não são rivais. Um arranjo comum é Helm para software que outras pessoas publicam, Kustomize
para as suas aplicações, e o `kubectl kustomize` capaz de renderizar um chart do Helm dentro de um
overlay quando os dois se encontram.
