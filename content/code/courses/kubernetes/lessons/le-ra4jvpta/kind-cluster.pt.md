---
title: Um cluster de três nós com o kind
version: 1
---

Três programas são tudo de que um cluster kind precisa: o Docker, que roda os nós, o `kind`, que monta
o cluster, e o `kubectl`, que conversa com ele. A aula 1 os instalou, e estas são as versões com que as
transcrições da aula 2 em diante foram gravadas:

```
ana@laptop:~/shop$ docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"
client 29.8.2, server 29.8.2
ana@laptop:~/shop$ kind version
kind v0.33.0 go1.24.7 linux/amd64
ana@laptop:~/shop$ kubectl version --client
Client Version: v1.37.1
Kustomize Version: v5.8.1
```

O `go1.24.7` na linha do kind é o Go com que aquela cópia foi compilada; o binário de release da aula
1 cita um mais novo e é o mesmo kind. **Mantenha o `kubectl` a no
máximo uma versão menor de distância do cluster**: 1.37 contra um cluster 1.37 aqui, o que o projeto
garante que funciona, enquanto uma diferença de duas versões não tem suporte.

## O cluster, por escrito

Um cluster é descrito num arquivo, como tudo neste curso:

```yaml
# A study cluster: one control-plane node and two workers.
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
nodes:
- role: control-plane
- role: worker
- role: worker
```

Os três `nodes` são o que importa: um plano de controle e dois workers, para que escalonar, espalhar
e perder um nó tenham onde acontecer. Os dois patches acima deles não fazem parte da lição. A máquina
em que o curso foi gravado tem cgroup v1 e proíbe baixar o OOM score de um processo; a sua, em
qualquer Linux atual, no Docker Desktop ou no WSL 2, não tem nenhuma das duas restrições, e o arquivo
funciona sem essas oito linhas.

```
ana@laptop:~/shop$ time kind create cluster --name study --config cluster.yaml --quiet

real	0m23.864s
user	0m2.066s
sys	0m1.678s
ana@laptop:~/shop$ kind get clusters
study
ana@laptop:~/shop$ kubectl config current-context
kind-study
```

**Vinte e quatro segundos** para três nós, medidos pelo shell. O `--quiet` só esconde a lista de
progresso do kind: sem ele o kind imprime uma linha por etapa, de *Ensuring node image* e *Preparing
nodes* até *Installing CNI*, *Installing StorageClass* e *Joining worker nodes*. O kind também
escreveu um contexto chamado `kind-study` em `~/.kube/config` e o tornou o atual, e é por isso que o
`kubectl` sabe para onde ir sem ninguém dizer; a lição 7 trata desse arquivo.

```
ana@laptop:~/shop$ kubectl get nodes -o wide
NAME                  STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION           CONTAINER-RUNTIME
study-control-plane   Ready    control-plane   28s   v1.37.0   172.18.0.2    <none>        Debian GNU/Linux 13 (trixie)   6.18.44-fc-v70 (amd64)   containerd://2.3.4
study-worker          Ready    <none>          13s   v1.37.0   172.18.0.4    <none>        Debian GNU/Linux 13 (trixie)   6.18.44-fc-v70 (amd64)   containerd://2.3.4
study-worker2         Ready    <none>          13s   v1.37.0   172.18.0.3    <none>        Debian GNU/Linux 13 (trixie)   6.18.44-fc-v70 (amd64)   containerd://2.3.4
```

Os três estão `Ready`, no Kubernetes `v1.37.0`, com o containerd como runtime. A coluna
`KERNEL-VERSION` é o kernel do próprio laptop: **um container compartilha o kernel da máquina em que
roda**, então esses nós são três conjuntos de processos num Linux só, e esse é o motivo inteiro de
eles subirem em segundos.

## Do que o cluster é feito, e quanto custa

Do lado do Docker, um nó é um container como qualquer outro:

```
ana@laptop:~/shop$ docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
NAMES                 IMAGE                  STATUS
study-control-plane   kindest/node:v1.37.0   Up 34 seconds
study-worker          kindest/node:v1.37.0   Up 34 seconds
study-worker2         kindest/node:v1.37.0   Up 34 seconds
```

E custa o que os processos dele usam, medido depois de o cluster ter assentado por vinte segundos:

```
ana@laptop:~/shop$ docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
NAME                  CPU %     MEM USAGE / LIMIT
study-control-plane   12.87%    537.5MiB / 15.72GiB
study-worker          1.77%     121MiB / 15.72GiB
study-worker2         1.87%     120.5MiB / 15.72GiB
```

**Cerca de 780 MiB para o cluster inteiro**: 537,5 para o nó do plano de controle, que roda o etcd e
o API server, e uns 120 para cada worker. A coluna de CPU é a foto de um instante; um cluster ocioso
gasta a maior parte da CPU com o plano de controle conferindo a si mesmo. Num laptop de 8 GiB isso
deixa espaço para tudo o que o curso roda, e o `kind delete cluster` devolve tudo.
