---
title: Quando a montagem falha
version: 1
---

**Uma montagem que falha quase nunca falha por causa do Kubernetes.** Ela falha uma camada abaixo: uma
imagem que os nós não enxergam, um Docker que recusa você, um download que veio errado. Cada falha
abaixo aconteceu enquanto este curso era gravado, e cada uma tem uma correção de uma ou duas linhas. A
aula 5 acrescenta mais quatro, todas do próprio `kind`, provocadas de propósito.

## Uma imagem que os nós não têm

A mais comum neste curso, porque a loja é montada na sua máquina e não baixada de lugar nenhum. Aqui
uma tag nova, `shop:dev`, é criada depois do cluster, e o cluster recebe o pedido de rodá-la:

```
ana@laptop:~/shop$ docker tag shop:1.0 shop:dev
ana@laptop:~/shop$ kubectl create deployment dev --image=shop:dev
deployment.apps/dev created
ana@laptop:~/shop$ kubectl get pods -l app=dev
NAME                   READY   STATUS             RESTARTS   AGE
dev-56757b7b5d-t85x7   0/1     ImagePullBackOff   0          25s
ana@laptop:~/shop$ kubectl describe pods -l app=dev | grep -m 1 "Failed to pull"
  Warning  Failed     10s (x2 over 25s)  kubelet            spec.containers{shop}: Failed to pull image "shop:dev": failed to pull and unpack image "docker.io/library/shop:dev": failed to resolve reference "docker.io/library/shop:dev": failed to do request: Head "https://registry-1.docker.io/v2/library/shop/manifests/dev": tls: failed to verify certificate: x509: certificate signed by unknown authority
ana@laptop:~/shop$ kind load docker-image shop:dev --name shop
Image: "shop:dev" with ID "sha256:8ec5c8c026d8c79748bf4fca94a440247f90f79de08dd2c895ed37c4dcd3bb57" not yet present on node "shop-worker", loading...
Image: "shop:dev" with ID "sha256:8ec5c8c026d8c79748bf4fca94a440247f90f79de08dd2c895ed37c4dcd3bb57" not yet present on node "shop-control-plane", loading...
Image: "shop:dev" with ID "sha256:8ec5c8c026d8c79748bf4fca94a440247f90f79de08dd2c895ed37c4dcd3bb57" not yet present on node "shop-worker2", loading...
ana@laptop:~/shop$ kubectl delete pods -l app=dev
pod "dev-56757b7b5d-t85x7" deleted from default namespace
ana@laptop:~/shop$ kubectl get pods -l app=dev
NAME                   READY   STATUS    RESTARTS   AGE
dev-56757b7b5d-vhjmr   1/1     Running   0          1s
```

`ImagePullBackOff` é o kubelet dizendo que tentou baixar e agora espera cada vez mais entre as
tentativas. A linha do `describe` diz por quê: a imagem não está no nó, então o nó pediu
`docker.io/library/shop:dev` ao Docker Hub. **O fim dessa linha depende da máquina.** Os nós da máquina
de gravação não alcançam o Docker Hub, então lá ela termina num erro de certificado; na sua os nós o
alcançam e ouvem que essa imagem não existe. Os dois querem dizer a mesma coisa:
ninguém copiou a imagem para o cluster. O `kind load docker-image` faz isso, e apagar o pod faz o
Deployment criar um novo na hora em vez de esperar o back-off acabar.

O mesmo acontece depois que você remonta uma imagem com `./build.sh`: o cluster fica com a cópia que
recebeu. Rode `./up.sh` de novo, ou `kind load docker-image` para a tag que mudou.

## O Docker recusa você

O `docker` conversa com um daemon que roda como root, por um socket que só o root e o grupo `docker`
podem usar. O Bruno, um usuário da mesma máquina que não está no grupo:

```
ana@laptop:~/shop$ sudo -u bruno docker ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
ana@laptop:~/shop$ sudo -u bruno kind get clusters
ERROR: failed to list clusters: command "docker ps -a --filter label=io.x-k8s.kind.cluster --format '{{.Label "io.x-k8s.kind.cluster"}}'" failed with error: exit status 1

Command Output: permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

O `kind` roda o `docker` por baixo, então falha com a mesma frase no fim da sua. A correção é o
`usermod -aG docker $USER` da seção sobre o Docker, **e depois sair e entrar de novo**, porque um shell
fica com os grupos com que começou; o `id` lista os seus, e `docker` tem de estar entre eles.

## Um download recusado ou errado

Enquanto este curso era gravado, o Docker Hub uma vez respondeu a um pull com `429 Too Many Requests`:
ele limita quantas imagens um endereço pode baixar sem conta. Esperar resolve, e também resolve um
`docker login` com uma conta gratuita do Docker, que aumenta o limite. Um checksum que imprime `FAILED`
em vez de `OK` quer dizer que o arquivo não é o que o projeto publicou; apague-o e baixe de novo em vez
de instalá-lo.

## Quando nada mais funciona

`kind delete cluster --name shop` e `./up.sh` dão um cluster novo em menos de um minuto, e essa é a
primeira coisa a tentar diante de qualquer coisa estranha numa aula: toda aula começa dele de qualquer
jeito. Se o próprio Docker está num estado que ninguém consegue explicar, apague a VM com
`multipass delete --purge k8s` e rode de novo os comandos desta aula. Parece desistir, e é o que quem
opera clusters faz com uma máquina cujo estado ninguém mais consegue explicar. É também por isso que
este curso monta tudo a partir de arquivos que você enxerga.
