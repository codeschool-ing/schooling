---
title: Quatro jeitos de falhar no primeiro dia
version: 1
---

**Quando um cluster local não sobe, o erro quase nunca é do Kubernetes.** É da máquina por baixo: um
nome já usado, um Docker que não responde, uma porta que outro programa segura, um `kubectl` apontado
para um cluster que não existe mais. Cada um dos quatro abaixo foi provocado de propósito no laptop,
e cada um se resolve com uma linha.

## O nome já existe

Rodando o mesmo comando duas vezes:

```
ana@laptop:~/shop$ kind create cluster --name study --config cluster.yaml
cgroup v1 is deprecated in Kubernetes and will not be supported in a future kind release, please upgrade to cgroup v2
ERROR: failed to create cluster: node(s) already exist for a cluster with the name "study"
```

**Um cluster do kind tem nome, e o nome precisa estar livre.** A primeira linha é um aviso que esta
máquina imprime por causa do cgroup v1, e você não vai vê-lo na sua. O erro é a segunda linha: `study`
já existe. Ou você usa esse cluster, ou escolhe outro nome com `--name`, ou o remove com
`kind delete cluster --name study` e começa de novo.

## O Docker não responde

Os nós são containers, então o kind precisa de um daemon do Docker antes de fazer qualquer coisa.
Aqui o cliente foi apontado para um socket em que nada escuta, que é exatamente o que ele vê quando o
Docker está parado:

```
ana@laptop:~/shop$ DOCKER_HOST=unix:///run/nothing.sock kind create cluster --name other 2>&1 | tail -n 1
failed to connect to the docker API at unix:///run/nothing.sock; check if the path is correct and if the daemon is running: dial unix /run/nothing.sock: connect: no such file or directory
```

A mensagem diz o socket e sugere a causa. No Linux, `sudo systemctl start docker`; com o Docker
Desktop, abra o programa e espere até ele dizer que está rodando. Se `docker ps` funciona e o kind
continua dizendo isso, a variável `DOCKER_HOST` ou um contexto do Docker está apontando para outro
lugar.

## Uma porta está com outro programa

Um cluster que publica a porta de um nó no laptop (para um navegador alcançar um Service, como a
lição 8 faz) precisa dessa porta livre. Este arquivo pede a 8080 do laptop, que um pequeno servidor
web já estava segurando:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
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
  extraPortMappings:
  - containerPort: 30080
    hostPort: 8080
```

```
ana@laptop:~/shop$ kind create cluster --name ports --config ports.yaml 2>&1 | grep -o "failed to bind host port.*"
failed to bind host port 0.0.0.0:8080/tcp: address already in use
```

**É o erro do Docker, repassado pelo kind**, e ele diz qual porta. Descubra quem a segura (`sudo lsof
-i :8080` ou `sudo ss -ltnp` no Linux) e pare esse programa, ou troque o `hostPort` por uma porta que
ninguém use. Um `kind create` que falhou não deixa nada para trás que precise ser limpo.

## O kubectl aponta para o nada

Apagar um cluster remove o contexto dele do `~/.kube/config`, e se ele era o atual, o `kubectl` fica
sem contexto nenhum:

```
ana@laptop:~/shop$ kind delete cluster --name study
Deleting cluster "study" ...
Deleted nodes: ["study-control-plane" "study-worker" "study-worker2"]
ana@laptop:~/shop$ kubectl get nodes
E1006 13:37:53.979359   17475 memcache.go:381] "Couldn't get current server API group list" err="Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
E1006 13:37:53.979744   17475 memcache.go:381] "Couldn't get current server API group list" err="Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
E1006 13:37:53.981892   17475 memcache.go:381] "Couldn't get current server API group list" err="Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
E1006 13:37:53.982304   17475 memcache.go:381] "Couldn't get current server API group list" err="Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
E1006 13:37:53.983883   17475 memcache.go:381] "Couldn't get current server API group list" err="Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
The connection to the server localhost:8080 was refused - did you specify the right host or port?
ana@laptop:~/shop$ kubectl config current-context
error: current-context is not set
```

**Este é o erro mais enganoso dos quatro.** Sem contexto, o `kubectl` cai num padrão antigo, um API
server sem criptografia em `localhost:8080`, que nada numa máquina moderna oferece. A correção é
apontá-lo para um cluster que existe: `kubectl config get-contexts` lista os disponíveis, e
`kubectl config use-context kind-shop` escolhe um.

| o que você vê | o que significa | a correção |
|---|---|---|
| `node(s) already exist for a cluster with the name` | o nome já existe | use o cluster, ou `kind delete cluster --name …` |
| `failed to connect to the docker API` | o Docker não está rodando, ou não está onde o cliente procura | inicie o Docker; confira o `DOCKER_HOST` |
| `failed to bind host port … address already in use` | uma porta de `extraPortMappings` está ocupada | libere a porta ou troque o `hostPort` |
| `The connection to the server localhost:8080 was refused` | o `kubectl` não tem contexto atual | `kubectl config use-context …` |

Mais uma falha não tem mensagem clara: **um cluster que sobe e depois perde nós, ou pods que são
mortos sem motivo visível, quase sempre quer dizer que o Docker tem pouca memória.** O Docker Desktop
roda os containers dentro de uma máquina virtual de tamanho fixo; dê a ela pelo menos 4 GiB nas
configurações antes de culpar o cluster. A lição 19 mostra como fica um container morto por falta de
memória.
