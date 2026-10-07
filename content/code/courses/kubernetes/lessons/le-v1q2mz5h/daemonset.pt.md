---
title: Um pod em cada nó
version: 1
---

**Alguns programas pertencem à máquina e não à aplicação**: um coletor de logs que lê a saída de todo
container daquele nó, um agente de métricas, o próprio plugin de rede. Rodá-los como Deployment seria
chutar um número de réplicas e torcer para o escalonador espalhá-las por igual. Um DaemonSet faz outra
pergunta (quais nós devem ter um?) e a resposta dele é todo nó que possa rodá-lo.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-agent
spec:
  selector:
    matchLabels:
      app: node-agent
  template:
    metadata:
      labels:
        app: node-agent
    spec:
      containers:
      - name: agent
        image: busybox:1.37
        command: ["sh", "-c", "echo watching $NODE; exec sleep 3600"]
        env:
        - name: NODE
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
```

Não há `replicas`. A entrada `env` usa a downward API para entregar ao container o nome do nó em que
ele caiu, que é em geral a primeira coisa de que um agente precisa.

```
ana@laptop:~/shop$ kubectl apply -f node-agent.yaml
daemonset.apps/node-agent created
ana@laptop:~/shop$ kubectl get daemonset node-agent
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-agent   2         2         2       2            2           <none>          1s
ana@laptop:~/shop$ kubectl get pods -l app=node-agent -o wide
NAME               READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
node-agent-l4jtj   1/1     Running   0          1s    10.244.2.2   shop-worker2   <none>           <none>
node-agent-vbkc4   1/1     Running   0          1s    10.244.1.2   shop-worker    <none>           <none>
```

**Dois pods, um em cada worker, e nenhum no plano de controle.** Essa escolha não é do DaemonSet:

```
ana@laptop:~/shop$ kubectl describe node shop-control-plane | grep Taints
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
```

O nó do plano de controle tem uma **taint**, `NoSchedule`, que mantém pods comuns fora dele, e os pods
de um DaemonSet são comuns a menos que digam tolerá-la. O kindnet e o kube-proxy dizem, e por isso a
lição 4 encontrou um de cada nos três nós. A lição 30 trata de taints e das tolerations que as
atravessam.

Quando um nó entra no cluster, o controlador do DaemonSet dá a ele um pod na hora; quando um nó sai, o
pod vai junto. Atualizar um DaemonSet troca os pods um nó de cada vez, por padrão, então um agente
nunca falta em todos os nós ao mesmo tempo.
