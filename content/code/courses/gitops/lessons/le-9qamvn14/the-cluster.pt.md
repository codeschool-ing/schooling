---
title: Um cluster, um registry e as ferramentas
version: 1
---

**Todas as aulas deste curso rodam contra a mesma montagem pequena**, e esta seção a constrói: um
cluster Kubernetes criado pelo `kind`, um registry de imagens ao lado dele e os dois programas que
os comandam. A aula 2 acrescenta um servidor Git, e cada aula seguinte instala a ferramenta de que
trata.

## Docker

O curso `docker` instala o Docker Engine na aula 6, a partir do repositório de pacotes do próprio
Docker. Se você fez esse curso nesta máquina, pule adiante. A versão curta, das instruções de
instalação do Docker para Ubuntu, é:

```sh
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

A última linha deixa você usar `docker` sem `sudo`, a partir do próximo login. **Esses comandos não
foram executados para este curso**, porque a máquina de gravação já tinha Docker. Esta é a versão
que ela tem:

```
ana@laptop:~/setup$ docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"
client 29.8.2, server 29.8.2
```

## kind e kubectl

As transcrições foram gravadas como `ana`, numa máquina chamada `laptop`. Crie uma pasta para os
arquivos desta montagem com `mkdir ~/setup && cd ~/setup`. O seu prompt vai mostrar o seu usuário e
a sua máquina, e essa deve ser a única diferença que você vê.

Os dois programas são arquivos únicos, baixados dos projetos deles e conferidos contra o checksum que
cada projeto publica ao lado do arquivo. `ARCH` é `amd64` na maioria dos computadores e `arm64` num
Mac com Apple silicon, e o `dpkg` sabe qual:

```
ana@laptop:~/setup$ ARCH=$(dpkg --print-architecture); echo $ARCH
amd64
ana@laptop:~/setup$ curl -fsSLo kind https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-$ARCH
ana@laptop:~/setup$ curl -fsSL https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-$ARCH.sha256sum | sed "s/kind-linux-$ARCH/kind/" | sha256sum --check
kind: OK
ana@laptop:~/setup$ curl -fsSLo kubectl https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kubectl
ana@laptop:~/setup$ echo "$(curl -fsSL https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kubectl.sha256)  kubectl" | sha256sum --check
kubectl: OK
ana@laptop:~/setup$ sudo install -m 0755 kind kubectl /usr/local/bin/ && rm kind kubectl
ana@laptop:~/setup$ kind version
kind v0.33.0 go1.26.7 linux/amd64
ana@laptop:~/setup$ kubectl version --client
Client Version: v1.37.1
Kustomize Version: v5.8.1
```

**Os dois `OK` são a razão das linhas do meio**: o arquivo que você baixou é o arquivo que o projeto
publicou. Uma verificação que falha imprime `FAILED` e sai com erro, e a resposta certa é apagar o
arquivo e baixar de novo, nunca instalar assim mesmo. A aula 8 volta a esse hábito e pergunta o que
um checksum prova e o que não prova.

## O registry

O GitOps publica **imagens que já existem**, pelo nome. Alguma coisa precisa guardá-las onde o
cluster consiga baixá-las, então a montagem ganha um registry próprio: a implementação de referência
do protocolo de distribuição OCI, rodando como container e escutando só na sua máquina.

```sh
docker run -d --restart=always --name registry -p 127.0.0.1:5001:5000 registry:3.1.2
```

```
ana@laptop:~/setup$ docker run -d --restart=always --name registry -p 127.0.0.1:5001:5000 registry:3.1.2
15cda3b455ca5ccbee1f6be74339f4d5698f3f50dcb23014b9d39bff7fab31c5
ana@laptop:~/setup$ curl -s localhost:5001/v2/_catalog
{"repositories":[]}
```

Um catálogo vazio é a resposta certa: o registry está no ar e ainda não guarda nada. A porta 5001 do
seu lado vira a 5000 dentro do container, e o `127.0.0.1` a mantém fora da sua rede. A aula 7 é
sobre registries; por enquanto ele é um lugar para pôr uma imagem.

## O cluster

Um cluster é descrito num arquivo, como tudo aqui. Salve este como `~/setup/cluster.yaml`:

```yaml
# The study cluster for gitops: one node, two ports reachable from your
# computer, and a registry it can pull from.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
# Read registry settings from /etc/containerd/certs.d, where the commands
# after this file tell the node where localhost:5001 really is.
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
# The next two patches are for the machine this was recorded on, which has
# cgroup v1 and forbids lowering a process's OOM score. Delete them on yours.
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
  - containerPort: 30080   # staging's bulletin
    hostPort: 8080
    listenAddress: 127.0.0.1
  - containerPort: 30081   # production's bulletin
    hostPort: 8081
    listenAddress: 127.0.0.1
```

**Um nó basta**, porque nada neste curso é sobre escalonamento: é sobre como uma mudança chega ao
cluster. Os dois `extraPortMappings` fazem as portas 8080 e 8081 da sua máquina levarem ao nó, então
uma aplicação publicada ali responde ao `curl` sem port-forward. O primeiro patch é o que importa
para o registry, e os próximos comandos o usam.

```
ana@laptop:~/setup$ time kind create cluster --name gitops --config cluster.yaml --quiet

real	0m16.115s
user	0m1.663s
sys	0m1.481s
ana@laptop:~/setup$ kind get clusters
gitops
ana@laptop:~/setup$ kubectl config current-context
kind-gitops
```

**Dezesseis segundos**, a maior parte para o nó subir os próprios containers. O kind escreveu um
contexto chamado `kind-gitops` no `~/.kube/config` e o tornou o atual, e é por isso que o `kubectl`
sabe para onde ir.

## Ensinando ao nó onde fica o registry

O nome `localhost:5001` tem uma pegadinha. Na sua máquina ele quer dizer o registry. **Dentro do nó
ele quer dizer o próprio nó**, onde nada escuta na 5001. Então o nó fica sabendo, na pasta que o
primeiro patch indicou, que `localhost:5001` é na verdade o container chamado `registry` na porta
5000, e o registry entra na rede em que o nó está:

```sh
for node in $(kind get nodes --name gitops); do
  docker exec "$node" mkdir -p /etc/containerd/certs.d/localhost:5001
  printf '[host."http://registry:5000"]\n' |
    docker exec -i "$node" cp /dev/stdin /etc/containerd/certs.d/localhost:5001/hosts.toml
done
docker network connect kind registry
```

É o arranjo que a própria documentação do kind recomenda para um registry local, e ele faz um único
nome de imagem funcionar nos dois lugares: você envia `localhost:5001/bulletin:1.0` do seu terminal, e
um manifesto que diz `localhost:5001/bulletin:1.0` é baixado pelo nó do mesmo registry.

```
ana@laptop:~/setup$ kubectl get nodes
NAME                   STATUS   ROLES           AGE   VERSION
gitops-control-plane   Ready    control-plane   23s   v1.37.0
```

`Ready`, no Kubernetes `v1.37.0`. A montagem está completa. `kind delete cluster --name gitops`
devolve tudo o que o cluster usa, e `docker rm -f registry` o registry; a próxima seção põe alguma
coisa neles.
