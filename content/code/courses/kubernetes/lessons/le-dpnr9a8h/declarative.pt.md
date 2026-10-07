---
title: Escreva, depois aplique
version: 1
---

A lição 2 criou um deployment com `kubectl create deployment`, e a lição 4 escalou um com
`kubectl scale`. São comandos **imperativos**: cada um é uma ordem, e depois de rodar, o único
registro do que foi pedido é o histórico do seu shell. O resto deste curso trabalha do outro jeito.
**Você escreve os objetos em arquivos, guarda os arquivos no git, e o `kubectl apply` faz o cluster
ficar igual a eles.** O arquivo é a descrição; o cluster é uma cópia mantida em dia.

## Um arquivo para começar

Ninguém escreve um manifesto a partir de uma página em branco. `--dry-run=client -o yaml` faz o
`kubectl create` imprimir o objeto que teria enviado, em vez de enviá-lo:

```
ana@laptop:~/shop$ kubectl create deployment web --image=shop:1.0 --replicas=2 --dry-run=client -o yaml > deployment.yaml
ana@laptop:~/shop$ cat deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: web
  name: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  strategy: {}
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - image: shop:1.0
        name: shop
        resources: {}
status: {}
```

`strategy: {}`, `resources: {}` e `status: {}` são campos vazios que o gerador deixa, e podem ser
apagados. Todo o resto é um Deployment completo.

## apply, e apply de novo

```
ana@laptop:~/shop$ kubectl apply -f deployment.yaml
deployment.apps/web created
ana@laptop:~/shop$ kubectl apply -f deployment.yaml
deployment.apps/web unchanged
```

**O `apply` pode ser repetido sem medo.** A primeira execução criou o objeto; a segunda comparou o
arquivo com o cluster, não encontrou nada para mudar e disse `unchanged`. É essa propriedade que
deixa um pipeline rodar `kubectl apply -f` a cada commit sem saber o que já está lá. Quando o arquivo
muda, o `kubectl diff` mostra o que o `apply` faria antes de qualquer coisa acontecer:

```
ana@laptop:~/shop$ sed -i "s/replicas: 2/replicas: 3/" deployment.yaml
ana@laptop:~/shop$ kubectl diff -f deployment.yaml
diff -u -N /tmp/LIVE-959397723/apps.v1.Deployment.default.web /tmp/MERGED-1156607339/apps.v1.Deployment.default.web
--- /tmp/LIVE-959397723/apps.v1.Deployment.default.web	2026-10-06 13:46:18.859512755 -0300
+++ /tmp/MERGED-1156607339/apps.v1.Deployment.default.web	2026-10-06 13:46:18.859512755 -0300
@@ -6,7 +6,7 @@
     kubectl.kubernetes.io/last-applied-configuration: |
       {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"labels":{"app":"web"},"name":"web","namespace":"default"},"spec":{"replicas":2,"selector":{"matchLabels":{"app":"web"}},"strategy":{},"template":{"metadata":{"labels":{"app":"web"}},"spec":{"containers":[{"image":"shop:1.0","name":"shop","resources":{}}]}}},"status":{}}
   creationTimestamp: "2026-10-06T16:46:16Z"
-  generation: 1
+  generation: 2
   labels:
     app: web
   name: web
@@ -15,7 +15,7 @@
   uid: 55c8bb00-d7ab-4b5c-b8c7-db9fdb8dfeda
 spec:
   progressDeadlineSeconds: 600
-  replicas: 2
+  replicas: 3
   revisionHistoryLimit: 10
   selector:
     matchLabels:
```

É um diff unificado entre o objeto vivo e o objeto como ficaria depois de aplicado. Duas linhas
mudam: `replicas` de 2 para 3, que a Ana pediu, e `generation` de 1 para 2, que o API server vai
incrementar porque o spec mudou. A anotação comprida acima delas,
`kubectl.kubernetes.io/last-applied-configuration`, é o arquivo como foi aplicado da última vez: o
kubectl a guarda no objeto para, na próxima vez, saber distinguir um campo que você apagou do arquivo
de um campo que outra pessoa definiu.

```
ana@laptop:~/shop$ kubectl apply -f deployment.yaml
deployment.apps/web configured
```

## Desvio, e como o arquivo vence

Alguém escala à mão, como conserto rápido no meio de um incidente:

```
ana@laptop:~/shop$ kubectl scale deployment web --replicas=5
deployment.apps/web scaled
ana@laptop:~/shop$ kubectl diff -f deployment.yaml
diff -u -N /tmp/LIVE-1635049792/apps.v1.Deployment.default.web /tmp/MERGED-2555153764/apps.v1.Deployment.default.web
--- /tmp/LIVE-1635049792/apps.v1.Deployment.default.web	2026-10-06 13:46:19.795512810 -0300
+++ /tmp/MERGED-2555153764/apps.v1.Deployment.default.web	2026-10-06 13:46:19.795512810 -0300
@@ -6,7 +6,7 @@
     kubectl.kubernetes.io/last-applied-configuration: |
       {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"labels":{"app":"web"},"name":"web","namespace":"default"},"spec":{"replicas":3,"selector":{"matchLabels":{"app":"web"}},"strategy":{},"template":{"metadata":{"labels":{"app":"web"}},"spec":{"containers":[{"image":"shop:1.0","name":"shop","resources":{}}]}}},"status":{}}
   creationTimestamp: "2026-10-06T16:46:16Z"
-  generation: 3
+  generation: 4
   labels:
     app: web
   name: web
@@ -15,7 +15,7 @@
   uid: 55c8bb00-d7ab-4b5c-b8c7-db9fdb8dfeda
 spec:
   progressDeadlineSeconds: 600
-  replicas: 5
+  replicas: 3
   revisionHistoryLimit: 10
   selector:
     matchLabels:
```

**Agora o diff corre ao contrário**: o objeto vivo diz 5, o arquivo diz 3, e aplicar levaria o cluster
de volta a 3. Isso é desvio (o cluster deixou de bater com a descrição) e o diff o encontrou sem
ninguém precisar se lembrar do incidente. A Ana aplica:

```
ana@laptop:~/shop$ kubectl apply -f deployment.yaml
deployment.apps/web configured
ana@laptop:~/shop$ kubectl get deployment web
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
web    3/3     3            3           6s
```

Três de novo. Se isso está certo depende de o conserto rápido ser desejado: se era, a mudança
pertence ao arquivo e ao git, para o próximo `apply` não desfazê-la. A lição 39 leva isso até o fim,
com um programa que aplica o repositório continuamente e informa o desvio no momento em que ele
acontece.

## Removendo o que um arquivo criou

```
ana@laptop:~/shop$ kubectl delete -f deployment.yaml
deployment.apps "web" deleted from default namespace
```

`delete -f` remove os objetos nomeados no arquivo, e é assim que uma aplicação sai de um cluster sem
ninguém listar as partes dela à mão.

| | imperativo | declarativo |
|---|---|---|
| exemplo | `kubectl scale deployment web --replicas=5` | editar `replicas`, depois `kubectl apply -f` |
| o registro do que foi pedido | o histórico do seu shell | o arquivo, no git |
| rodar duas vezes | pode falhar, ou fazer duas vezes | `unchanged` |
| ver a mudança antes | não | `kubectl diff` |
| bom para | explorar, e emergências que você depois escreve | tudo o que ainda deve ser verdade amanhã |

A versão do `apply` usada aqui é a original, do lado do cliente. `kubectl apply --server-side` leva a
comparação para dentro do API server, que registra qual ferramenta é dona de cada campo; o Helm da
lição 37 e os controladores de GitOps da lição 39 a usam, e para uma pessoa num terminal os comandos
são os mesmos.
