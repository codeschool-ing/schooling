---
title: O log do próprio API server
version: 1
---

**Toda mudança num cluster é um pedido ao API server dele**, venha de quem vier: o Flux aplicando um
commit, uma pessoa rodando `kubectl`, um operador escrevendo um Secret. O API server pode gravar
cada pedido num log de auditoria enquanto o atende, com o usuário, o verbo, o objeto e o horário. É
o único registro que vê as mudanças que ninguém commitou.

Ele fica desligado a menos que o API server suba com uma política dizendo o que registrar, e num
cluster gerenciado isso é uma configuração do provedor: EKS, GKE e AKS mandam o log para o próprio
serviço de logs quando se pede. No kind são duas flags passadas pelo arquivo do cluster, e **as
flags do API server são fixadas quando o cluster é criado**. O cluster deste curso foi criado na
aula 1 sem elas, então o log de auditoria aparece num segundo cluster, pequeno, criado só para isso
ao lado do primeiro e apagado depois.

A política diz o que registrar e com quanto detalhe. Salve isto como `~/setup/audit-policy.yaml`:

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
- RequestReceived
rules:
- level: None
  resources:
  - group: coordination.k8s.io
    resources: ["leases"]
- level: Metadata
  resources:
  - group: ""
    resources: ["secrets"]
- level: RequestResponse
  verbs: ["create", "update", "patch", "delete"]
- level: None
```

As regras são lidas em ordem e vale a primeira que casar. Leases são renovados por todo controlador
a cada poucos segundos e não dizem nada, então são descartados. **Secrets são registrados em
`Metadata`**: quem fez o quê com qual Secret, e nunca o conteúdo, porque um log de auditoria que
guardasse todo segredo seria o arquivo mais valioso da empresa. Toda outra mudança é registrada com
o pedido e a resposta; e as leituras de qualquer coisa que não seja Secret, a última regra, não são
registradas, uma escolha que mantém o log pequeno e que uma política mais rígida faria diferente.

O arquivo do cluster é o da aula 1 sem as portas, mais as duas flags e os arquivos de que elas
precisam. Salve-o como `~/setup/audit-cluster.yaml`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
# The next two patches are for the machine this was recorded on, which has
# cgroup v1 and forbids lowering a process's OOM score. Delete them on yours.
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
- |
  kind: ClusterConfiguration
  apiServer:
    extraArgs:
    - name: audit-policy-file
      value: /etc/kubernetes/audit/policy.yaml
    - name: audit-log-path
      value: /var/log/kubernetes/audit.log
    extraVolumes:
    - name: audit-policy
      hostPath: /etc/kubernetes/audit
      mountPath: /etc/kubernetes/audit
      readOnly: true
      pathType: DirectoryOrCreate
    - name: audit-log
      hostPath: /var/log/kubernetes
      mountPath: /var/log/kubernetes
      pathType: DirectoryOrCreate
nodes:
- role: control-plane
  extraMounts:
  - hostPath: /home/ana/setup/audit-policy.yaml
    containerPath: /etc/kubernetes/audit/policy.yaml
    readOnly: true
```

`extraMounts` põe a política dentro do nó, e `extraVolumes` a põe, junto com o diretório do log,
dentro do contêiner do próprio API server. Troque `/home/ana` pelo seu diretório home: o kind
precisa do caminho completo.

```
ana@laptop:~/setup$ kind create cluster --name audit --config audit-cluster.yaml --kubeconfig ~/.kube/audit --wait 2m --quiet
ana@laptop:~/setup$ KUBECONFIG=~/.kube/audit kubectl get nodes
NAME                  STATUS   ROLES           AGE   VERSION
audit-control-plane   Ready    control-plane   25s   v1.37.0
```

Uma pessoa faz duas mudanças, um ConfigMap e um Secret, e o log tem as duas:

```
ana@laptop:~/setup$ export KUBECONFIG=~/.kube/audit
ana@laptop:~/setup$ kubectl create configmap note --from-literal=text=hello
configmap/note created
ana@laptop:~/setup$ kubectl create secret generic note --from-literal=password=not-in-the-log
secret/note created
ana@laptop:~/setup$ docker exec audit-control-plane cat /var/log/kubernetes/audit.log | jq -c 'select(.objectRef.name == "note" and .verb == "create") | {time: .requestReceivedTimestamp, user: .user.username, verb, resource: .objectRef.resource, name: .objectRef.name, level}'
{"time":"2026-10-16T04:54:37.474002Z","user":"kubernetes-admin","verb":"create","resource":"configmaps","name":"note","level":"RequestResponse"}
{"time":"2026-10-16T04:54:37.593582Z","user":"kubernetes-admin","verb":"create","resource":"secrets","name":"note","level":"Metadata"}
ana@laptop:~/setup$ docker exec audit-control-plane grep -c not-in-the-log /var/log/kubernetes/audit.log
0
ana@laptop:~/setup$ export KUBECONFIG=~/.kube/config
```

Duas entradas, uma por pedido, cada uma com o usuário, o verbo, o objeto e o horário até o
microssegundo. O ConfigMap fica registrado em `RequestResponse`, o Secret em `Metadata`, e o `grep`
não acha o valor do Secret em lugar nenhum do log: `0`.

**Este é o registro que pega uma mudança que ninguém commitou.** O Flux a desfaria na passada
seguinte, e o cluster pareceria intocado; o log de auditoria guarda o usuário, o horário e o objeto.
Enviado a um serviço de logs, com alertas para mudanças feitas por pessoas nos namespaces que o Flux
controla, ele transforma "alguém usou `kubectl` em produção" de boato em evento.

```
ana@laptop:~/setup$ kind delete cluster --name audit --kubeconfig ~/.kube/audit
Deleting cluster "audit" ...
Deleted nodes: ["audit-control-plane"]
```
