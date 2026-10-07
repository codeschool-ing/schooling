---
title: Podman
version: 2
---

**O Podman roda as mesmas imagens com os mesmos comandos, e duas diferenças de arquitetura: não há
daemon, e ele roda sem root por padrão.** Cada comando `podman` faz o próprio trabalho e sai, e os
containers que ele inicia pertencem ao usuário que os iniciou.

O Podman está no arquivo do próprio Ubuntu, e no Ubuntu 24.04 isso é a versão 4.9.3, a de baixo. Ele
se instala ao lado do Docker sem mexer nele:

```sh
sudo apt-get install podman
```

## Uma configuração de registry própria

O Podman lê o `registries.conf`, e não o `daemon.json` do Docker. A Ana dá ao dela o mesmo espelho que
a aula 6 deu ao Docker:

```toml
[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry.mirror]]
location = "mirror.gcr.io"
```

## Root dentro, Ana fora

```
ana@vm:~$ podman --version
podman version 4.9.3
ana@vm:~$ podman run --rm --network none docker.io/library/alpine:3.22 id 2>&1 | grep -v "shared mount"
Trying to pull docker.io/library/alpine:3.22...
Getting image source signatures
Copying blob sha256:53f8f5e03afd86ade91b7aa57a749f5a3d1419c113be5d8c10e7ee61bb5ab887
Copying config sha256:c83674e1999044d33d751661371b873539f47e5b5c5ca3320c7e0377acca6238
Writing manifest to image destination
uid=0(root) gid=0(root) groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),11(floppy),20(dialout),26(tape),27(video)
ana@vm:~$ podman run --rm --network none docker.io/library/alpine:3.22 cat /proc/self/uid_map 2>&1 | grep -v "shared mount"
         0      30033          1
         1     165536      65536
ana@vm:~$ podman run -d --name sleeper --network none docker.io/library/alpine:3.22 sleep 300 2>&1 | grep -v "shared mount"
175e2046587a9c40349ff1efdccf12c10f2f6f207ade868ac14db6df0eab7c82
ana@vm:~$ ps -o user,pid,args -C sleep
USER       PID COMMAND
ana      28969 sleep 300
ana@vm:~$ podman ps --format "{{.Names}} {{.Image}} {{.Status}}" 2>&1 | grep -v "shared mount"
sleeper docker.io/library/alpine:3.22 Up Less than a second
```

**O `id` diz root, o mapa de usuários diz outra coisa, e o `ps` no host diz `ana`.** Leia o
`/proc/self/uid_map`: o UID 0 de dentro é o UID 30033 de fora, o da própria Ana; os UIDs 1 a 65536 de
dentro são 165536 em diante lá fora, a faixa que o `/etc/subuid` deu a ela. Esse é o namespace de
usuário que a aula 21 descreveu como opção do daemon: **no Podman ele é o padrão**, então um processo
que passasse por todas as paredes chegaria ao host como a Ana, sem nada que ela já não tenha.

Duas observações sobre o que o laboratório não consegue mostrar. A rede sem root precisa do
`/dev/net/tun`, que o laboratório não dá a um usuário sem privilégio, então estes containers rodam com
`--network none`; numa máquina normal eles ganham rede, e o `-p` funciona para portas acima de 1023. E o
aviso do Podman de que `/` não é uma montagem compartilhada, uma característica da máquina do
laboratório, é filtrado com `grep`.

## O mesmo Dockerfile

```
ana@vm:~$ cd shelf && podman build -q --network none --build-arg VERSION=1.0.0 -t shelf:1.0.0 . 2>&1 | grep -v "shared mount" | tail -1; cd ..
Error: creating build container: short-name "golang:1.25" did not resolve to an alias and no unqualified-search registries are defined in "/home/ana/.config/containers/registries.conf"
```

**O Podman recusou `golang:1.25`.** O Docker lê um nome sem registry como Docker Hub (aula 15); o Podman
não chuta, porque um nome curto que resolve para o primeiro registry que responder é um jeito de rodar a
imagem de outra pessoa. A Ana diz que registry os nomes curtos querem dizer:

```toml
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry.mirror]]
location = "mirror.gcr.io"
```

```
ana@vm:~$ cd shelf && podman build -q --network none --build-arg VERSION=1.0.0 -t shelf:1.0.0 . 2>&1 | grep -v "shared mount" | tail -1; cd ..
fc1c9fefdd83c88203bea789f26245b6a45e30822e694becf1fd68e80b224e87
ana@vm:~$ podman run -d --name shelf --network none localhost/shelf:1.0.0 2>&1 | grep -v "shared mount"
3dc2b41e879241301284f70845ea9906defecb1112423aa5d8643b458494d520
ana@vm:~$ podman logs shelf 2>&1 | grep -v "shared mount"
2026/10/06 21:44:52 catalogue: built in, 3 books
2026/10/06 21:44:52 shelf 1.0.0 listening on :8080
ana@vm:~$ podman images --format "{{.Repository}}:{{.Tag}}" 2>&1 | grep -v "shared mount"
localhost/shelf:1.0.0
<none>:<none>
docker.io/library/alpine:3.22
docker.io/library/golang:1.25
gcr.io/distroless/static-debian12:nonroot
ana@vm:~$ docker images --format "{{.Repository}}:{{.Tag}}" | grep shelf
shelf:1.0.0
```

**O mesmo Dockerfile foi construído, e o `shelf` rodou no Podman.** A imagem dele é
`localhost/shelf:1.0.0`, o nome que o Podman dá a uma imagem construída localmente, e ela mora no
armazenamento da própria Ana: o `shelf:1.0.0` do Docker é uma cópia separada em outro lugar. O Podman
também roda arquivos do Compose pelo `podman compose`, que os entrega a um provedor de Compose, e o
pacote de compatibilidade `docker` dele deixa scripts que digitam `docker` rodarem sem mudança; nenhum
dos dois foi usado aqui.
