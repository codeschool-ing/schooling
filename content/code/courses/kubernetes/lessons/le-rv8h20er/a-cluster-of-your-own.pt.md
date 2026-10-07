---
title: Um cluster seu
version: 1
---

O resto do curso acontece num cluster, e é este: **três nós feitos de containers Docker, montados pelo
`kind` a partir de um arquivo de uma dúzia de linhas.** A aula 5 o abre e compara o `kind` com os
outros jeitos de ter um cluster num laptop; aqui ele só precisa existir. Mais dois arquivos vão para
`~/shop`.

`cluster.yaml`, o cluster:

```yaml
# The cluster the lessons run on: one control-plane node and two workers.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
# The next two patches are for the machine this course was recorded on, which
# has cgroup v1 and forbids lowering a process's OOM score. Delete them on yours.
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
  serverTLSBootstrap: true
nodes:
- role: control-plane
- role: worker
- role: worker
```

Os três `nodes` são o que importa: um control plane e dois workers, para que agendar, espalhar e perder
um nó tenham onde acontecer. `serverTLSBootstrap: true` faz o kubelet de cada nó pedir ao cluster um
certificado de verdade em vez de assinar o próprio, e a aula 21 precisa disso. **Os dois patches acima
dele não fazem parte da aula.** A máquina em que o curso foi gravado tem cgroup v1 e proíbe baixar o
OOM score de um processo; um Ubuntu atual, o Docker Desktop ou o WSL 2 não têm nenhuma das duas
restrições, então apague essas linhas na sua e deixe o `serverTLSBootstrap: true` onde está.

`up.sh`, que joga fora o cluster que existia e monta um novo:

```sh
#!/bin/sh
# A fresh cluster called shop, with the shop's images inside it.
#   ./up.sh               the three nodes of cluster.yaml
#   ./up.sh other.yaml    another kind configuration, when a lesson asks
set -e
cd "$(dirname "$0")"
config=${1:-cluster.yaml}
kind delete cluster --name shop
kind create cluster --name shop --config "$config" --quiet
# The nodes are containers with an image store of their own, and they cannot
# see what Docker built on this machine. Copy the shop in.
kind load docker-image shop:1.0 shop:1.1 shop:2.0 --name shop
# Each kubelet asks the cluster for a serving certificate (serverTLSBootstrap
# in cluster.yaml). Wait for one request per node, then approve them.
nodes=$(kubectl get nodes --no-headers | wc -l)
until [ "$(kubectl get csr --no-headers | grep -c kubelet-serving)" -ge "$nodes" ]; do
  sleep 2
done
kubectl get csr --no-headers | awk '/kubelet-serving/ && /Pending/ {print $1}' |
  xargs -r kubectl certificate approve
# A cluster made without kind's network plugin (lesson 24) has no Ready node
# until one is installed, so there is nothing to wait for yet.
grep -q 'disableDefaultCNI: true' "$config" && exit 0
kubectl wait --for=condition=Ready nodes --all --timeout=180s
```

```
ana@laptop:~/shop$ chmod +x up.sh
ana@laptop:~/shop$ ./up.sh
Deleting cluster "shop" ...
Image: "shop:1.0" with ID "sha256:8ec5c8c026d8c79748bf4fca94a440247f90f79de08dd2c895ed37c4dcd3bb57" not yet present on node "shop-worker", loading...
Image: "shop:1.0" with ID "sha256:8ec5c8c026d8c79748bf4fca94a440247f90f79de08dd2c895ed37c4dcd3bb57" not yet present on node "shop-control-plane", loading...
Image: "shop:1.0" with ID "sha256:8ec5c8c026d8c79748bf4fca94a440247f90f79de08dd2c895ed37c4dcd3bb57" not yet present on node "shop-worker2", loading...
Image: "shop:1.1" with ID "sha256:bc6abd85e770d347b7672be119ad44c8f1206b60818de53b7329d91137a0725a" not yet present on node "shop-worker", loading...
Image: "shop:1.1" with ID "sha256:bc6abd85e770d347b7672be119ad44c8f1206b60818de53b7329d91137a0725a" not yet present on node "shop-control-plane", loading...
Image: "shop:1.1" with ID "sha256:bc6abd85e770d347b7672be119ad44c8f1206b60818de53b7329d91137a0725a" not yet present on node "shop-worker2", loading...
Image: "shop:2.0" with ID "sha256:101822b3a919de746e60a47700783084331e9bf6932d9787cc53421d46054b3b" not yet present on node "shop-worker", loading...
Image: "shop:2.0" with ID "sha256:101822b3a919de746e60a47700783084331e9bf6932d9787cc53421d46054b3b" not yet present on node "shop-control-plane", loading...
Image: "shop:2.0" with ID "sha256:101822b3a919de746e60a47700783084331e9bf6932d9787cc53421d46054b3b" not yet present on node "shop-worker2", loading...
certificatesigningrequest.certificates.k8s.io/csr-2cc6w approved
certificatesigningrequest.certificates.k8s.io/csr-cwz5v approved
certificatesigningrequest.certificates.k8s.io/csr-fvgh2 approved
certificatesigningrequest.certificates.k8s.io/csr-vgj84 approved
node/shop-control-plane condition met
node/shop-worker condition met
node/shop-worker2 condition met
```

Lido de cima para baixo: o cluster antigo apagado (na primeira vez não havia nenhum, e apagar nada não
é erro), o novo criado (o `--quiet` guarda para o kind a lista de passos, e a aula 5 os cita), as
três imagens da loja copiadas para cada um dos três nós, um
pedido de certificado por nó aprovado, e todo nó `Ready`. **As imagens precisam ser copiadas porque um
nó é um container com o seu próprio repositório de imagens**: ele não enxerga o que o Docker montou na
máquina em volta dele, e procuraria `shop:1.0` no Docker Hub sem encontrar. A última seção desta aula
mostra exatamente isso dando errado.

```
ana@laptop:~/shop$ kubectl get nodes
NAME                 STATUS   ROLES           AGE   VERSION
shop-control-plane   Ready    control-plane   28s   v1.37.0
shop-worker          Ready    <none>          13s   v1.37.0
shop-worker2         Ready    <none>          13s   v1.37.0
```

**Toda aula da aula 2 em diante começa com `./up.sh`**, e as transcrições dela começam num cluster
montado assim, para que nenhuma aula dependa do que a anterior deixou para trás. Uma aula que precise
de outro cluster, ou de algo instalado nele, diz isso antes do primeiro comando. Quando parar por hoje,
`kind delete cluster --name shop` devolve a memória.
