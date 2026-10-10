---
title: Quando a montagem falha
version: 1
---

Montar o ambiente é onde mais gente desiste de um curso como este, quase sempre por causa de uma
linha de saída que parecia uma catástrofe e era uma coisa pequena. Estas são as falhas que aparecem
seguindo esta aula, cada uma com o que imprime e o que resolve. **Todas foram produzidas de
propósito**, na máquina de onde vêm as transcrições.

## `permission denied` do Docker

Logo depois de instalar o Docker:

```
ana@laptop:~/setup$ docker ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

O daemon do Docker escuta num socket que só o `root` e o grupo `docker` podem usar. A instalação pôs
você no grupo, e **a participação em grupos é lida quando você entra na sessão**, então o terminal de
onde você instalou ainda não a tem. Saia e entre de novo; na VM, `exit` e `multipass shell gitops` de
novo. Aí o `id` lista `docker` entre os seus grupos. Rodar tudo com `sudo` funciona e deixa arquivos
do root na sua pasta pessoal, o que falha mais tarde de jeitos mais confusos.

## Um cluster que já existe

Rodando a criação uma segunda vez, ou depois de uma tentativa que funcionou pela metade:

```
ana@laptop:~/setup$ kind create cluster --name gitops --config cluster.yaml 2>&1 | grep ERROR
ERROR: failed to create cluster: node(s) already exist for a cluster with the name "gitops"
```

O kind recusa em vez de sobrescrever. Se o cluster existente funciona, fique com ele. Se não
funciona, `kind delete cluster --name gitops` o remove por completo e a criação pode rodar de novo.

## Uma porta ocupada

O arquivo do cluster pede as portas 8080 e 8081 da sua máquina. Se outra coisa já escuta numa delas,
aqui um pequeno servidor web que alguém deixou rodando na 8080, o nó não consegue subir:

```
ana@laptop:~/setup$ kind create cluster --name gitops --config cluster.yaml 2>&1 | grep 'already in use'
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint gitops-control-plane (25207e6238bdb17d0edf869e3eefc74d3391545e607f54156d9834c29b5e4a2f): failed to bind host port 127.0.0.1:8080/tcp: address already in use
```

O kind imprime uma página de saída quando a criação falha, e o `grep` fica com a única linha que
importa: `address already in use` diz qual porta. Descubra quem a ocupa com `ss -ltnp | grep 8080` e pare o
processo; ou mude o `hostPort` no `cluster.yaml` para uma porta livre e use esse número onde o curso
disser 8080. O kind limpa tudo depois de uma criação que falhou, então não há nada a apagar antes de
tentar de novo.

## Um pod que não consegue baixar a imagem

A falha mais comum de toda a montagem é um nó que não sabe onde fica `localhost:5001`, porque o laço
que escreve o `hosts.toml` foi pulado ou rodou antes de o cluster existir. O deployment é criado e
os pods nunca sobem:

```
ana@laptop:~/setup$ kubectl create deployment probe --image=localhost:5001/bulletin:1.0
deployment.apps/probe created
ana@laptop:~/setup$ kubectl get pods
NAME                     READY   STATUS             RESTARTS   AGE
probe-7c47477fcc-zgsbb   0/1     ImagePullBackOff   0          25s
ana@laptop:~/setup$ kubectl describe pods -l app=probe | tail -n 6
  Normal   Scheduled  25s                default-scheduler  Successfully assigned default/probe-7c47477fcc-zgsbb to gitops-control-plane
  Normal   BackOff    25s                kubelet            spec.containers{bulletin}: Back-off pulling image "localhost:5001/bulletin:1.0"
  Warning  Failed     25s                kubelet            spec.containers{bulletin}: Error: ImagePullBackOff
  Normal   Pulling    10s (x2 over 25s)  kubelet            spec.containers{bulletin}: Pulling image "localhost:5001/bulletin:1.0"
  Warning  Failed     10s (x2 over 25s)  kubelet            spec.containers{bulletin}: Failed to pull image "localhost:5001/bulletin:1.0": failed to pull and unpack image "localhost:5001/bulletin:1.0": failed to resolve reference "localhost:5001/bulletin:1.0": failed to do request: Head "https://localhost:5001/v2/bulletin/manifests/1.0": dial tcp 127.0.0.1:5001: connect: connection refused
  Warning  Failed     10s (x2 over 25s)  kubelet            spec.containers{bulletin}: Error: ErrImagePull
```

`ImagePullBackOff` é o resumo e o evento embaixo dele é o motivo: o nó tentou `localhost:5001` **nele
mesmo**, não achou nada escutando e desistiu. Rode de novo o laço de "Ensinando ao nó onde fica o
registry"; os pods tentam de novo sozinhos e sobem em menos de um minuto.

O mesmo status com outro motivo pede outra correção:

```
ana@laptop:~/setup$ kubectl create deployment probe --image=localhost:5001/bulletin:1.1
deployment.apps/probe created
ana@laptop:~/setup$ kubectl get pods
NAME                     READY   STATUS             RESTARTS   AGE
probe-57f8b4b4fd-w2j8f   0/1     ImagePullBackOff   0          20s
ana@laptop:~/setup$ kubectl describe pods -l app=probe | tail -n 6
  Normal   Scheduled  20s               default-scheduler  Successfully assigned default/probe-57f8b4b4fd-w2j8f to gitops-control-plane
  Normal   BackOff    19s               kubelet            spec.containers{bulletin}: Back-off pulling image "localhost:5001/bulletin:1.1"
  Warning  Failed     19s               kubelet            spec.containers{bulletin}: Error: ImagePullBackOff
  Normal   Pulling    7s (x2 over 19s)  kubelet            spec.containers{bulletin}: Pulling image "localhost:5001/bulletin:1.1"
  Warning  Failed     7s (x2 over 19s)  kubelet            spec.containers{bulletin}: Failed to pull image "localhost:5001/bulletin:1.1": rpc error: code = NotFound desc = failed to pull and unpack image "localhost:5001/bulletin:1.1": failed to resolve reference "localhost:5001/bulletin:1.1": localhost:5001/bulletin:1.1: not found
  Warning  Failed     7s (x2 over 19s)  kubelet            spec.containers{bulletin}: Error: ErrImagePull
```

`not found` quer dizer que o nó chegou ao registry, e o registry não tem essa tag. Aqui o manifesto
pede `1.1`, que nunca foi enviada. Compare o nome e a tag do manifesto com o que o registry guarda: o
`curl -s localhost:5001/v2/bulletin/tags/list` lista as tags.

## Nada responde na 8080

Se `curl localhost:8080` diz `Connection refused` com os pods em `Running`, o cluster foi criado de
um arquivo sem os `extraPortMappings`, e a porta 8080 da sua máquina não leva a lugar nenhum. O
mapeamento só pode ser definido na criação do cluster, então a correção é
`kind delete cluster --name gitops` e criar de novo com o arquivo desta aula, seguido do laço do
`hosts.toml`.
