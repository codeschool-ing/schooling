---
title: A sonda que mata
version: 2
---

A verificação de saúde mais cara é a que acerta sobre um problema e erra sobre de quem ele é. **Uma
sonda de liveness que verifica uma dependência reinicia toda cópia de um serviço quando a dependência
falha**, e nenhum dos reinícios pode ajudar.

Três cópias de um serviço cuja sonda de liveness insiste em alcançar o banco, salvas como
`~/shop/k8s/deep.yaml`:

```schooling-example
{
  "language": "yaml",
  "file": "k8s/deep.yaml",
  "parts": [
    {
      "code": "# A stand-in database, and a service whose LIVENESS probe checks that it can\n# reach it: the mistake this part of the lesson is about.\napiVersion: apps/v1\nkind: Deployment\nmetadata: {name: db}\nspec:\n  replicas: 1\n  selector: {matchLabels: {app: db}}\n  template:\n    metadata: {labels: {app: db}}\n    spec:\n      containers:\n        - name: db\n          image: shop:1.4.0\n          imagePullPolicy: Never\n          command: [python, -m, http.server, \"5432\"]\n---\napiVersion: v1\nkind: Service\nmetadata: {name: db}\nspec:\n  selector: {app: db}\n  ports: [{port: 5432}]\n---\n",
      "note": "Um substituto de banco de dados: um servidor escutando na 5432, atrás de um Service chamado `db`."
    },
    {
      "code": "apiVersion: apps/v1\nkind: Deployment\nmetadata: {name: deep}\nspec:\n  replicas: 3\n  selector: {matchLabels: {app: deep}}\n  template:\n    metadata: {labels: {app: deep}}\n    spec:\n      containers:\n        - name: deep\n          image: shop:1.4.0\n          imagePullPolicy: Never\n          command: [python, -m, http.server, \"8000\"]\n"
    },
    {
      "code": "          livenessProbe:\n            exec:\n              command: [python, -c, \"import socket; socket.create_connection(('db', 5432), 1)\"]\n            periodSeconds: 3\n            failureThreshold: 3\n",
      "note": "**O erro**: uma sonda de liveness que só passa se o `db` aceitar uma conexão. Ela é escrita com a melhor das intenções, *se eu não alcanço meu banco, algo está errado comigo*, e é falsa."
    }
  ]
}
```

```
ana@obs:~/shop$ kubectl apply -f k8s/deep.yaml
deployment.apps/db created
service/db created
deployment.apps/deep created
ana@obs:~/shop$ kubectl get pods -l app=deep
NAME                    READY   STATUS    RESTARTS   AGE
deep-556bf5bcdd-jw2kh   1/1     Running   0          1s
deep-556bf5bcdd-s5flf   1/1     Running   0          1s
deep-556bf5bcdd-vnsfv   1/1     Running   0          1s
```

As três prontas e nunca reiniciadas. Então o banco some, escalado para nada, e passam-se dois minutos
e meio:

```
ana@obs:~/shop$ kubectl scale deployment db --replicas=0
deployment.apps/db scaled
ana@obs:~/shop$ kubectl get pods -l app=deep
NAME                    READY   STATUS    RESTARTS     AGE
deep-556bf5bcdd-jw2kh   1/1     Running   3 (4s ago)   2m32s
deep-556bf5bcdd-s5flf   1/1     Running   3 (4s ago)   2m32s
deep-556bf5bcdd-vnsfv   1/1     Running   3 (4s ago)   2m32s
```

**Toda cópia reiniciou três vezes, no mesmo momento.** Cada reinício é um processo morto no meio do que
estava fazendo, requisições incluídas, e cada processo novo falhou na mesma sonda nove segundos
depois, porque o banco ainda não estava lá. Entre os reinícios o Kubernetes espera mais a cada vez,
dez segundos, depois vinte, depois quarenta, até cinco minutos, que é o que `CrashLoopBackOff`
significa quando aparece.

O banco volta:

```
ana@obs:~/shop$ kubectl scale deployment db --replicas=1
deployment.apps/db scaled
ana@obs:~/shop$ kubectl get pods -l app=deep
NAME                    READY   STATUS    RESTARTS      AGE
deep-556bf5bcdd-jw2kh   1/1     Running   3 (64s ago)   3m32s
deep-556bf5bcdd-s5flf   1/1     Running   3 (64s ago)   3m32s
deep-556bf5bcdd-vnsfv   1/1     Running   3 (64s ago)   3m32s
```

Os reinícios param, e a contagem fica em três, o registro de uma queda que este serviço não teve.
Com tráfego real o estrago é maior que a contagem: requisições se perderam a cada reinício, e caches
foram esvaziados. Quando o banco voltou toda cópia estava iniciando ou cumprindo uma espera, então a
recuperação levou mais do que a queda precisava.

A correção é uma frase: **a liveness verifica o processo, a readiness verifica as dependências.** Se
esta verificação fosse uma sonda de readiness, as três cópias teriam saído do Service enquanto o
banco estava fora. Teriam voltado sozinhas poucos segundos depois de ele voltar, sem nada reiniciado
e nada perdido.

Quando terminar com o cluster, apague o que esta aula pôs nele, e depois o cluster:

```sh
kubectl delete -f k8s/deep.yaml -f k8s/probe-demo.yaml
kind delete cluster --name lab
```
