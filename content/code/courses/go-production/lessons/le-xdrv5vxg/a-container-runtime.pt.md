---
title: Um runtime de contêineres para a lição 18
version: 1
---

A lição 18 põe o binário que esta lição construiu numa imagem de contêiner e o roda. Para isso é
preciso um runtime de contêineres, a única coisa que este curso acrescenta ao laboratório da lição 1, e
a tabela da lição 1 o prometeu aqui. **O runtime que este curso usa é o Podman, do repositório do Ubuntu
24.04, rodado por um usuário comum.** Ele não precisa de daemon nem de root: cada comando `podman` é um
programa que a Ana roda, e os contêineres que ele inicia pertencem a ela.

## Os passos, em resumo

Um pacote, e ele traz o que precisa:

```sh
sudo apt install podman
```

**Contêineres rootless precisam de uma faixa de ids de usuário própria.** Dentro de um contêiner há um
usuário root e muitas vezes outros, e o Podman os mapeia para ids que o kernel deixa a conta da Ana
usar, listados em `/etc/subuid` e `/etc/subgid`. As ferramentas do Ubuntu que criam contas dão a cada
conta nova uma faixa de 65.536, então na maioria das máquinas não há nada a fazer. Dois auxiliares de
que o Podman precisa vêm como pacotes recomendados, que o `apt install` instala a menos que mandem não
instalar.

## Quatro verificações

Como Ana, em qualquer diretório:

```
ana@vm:~/small$ podman --version
podman version 4.9.3
ana@vm:~/small$ podman info --format "{{.Host.Security.Rootless}}"
true
ana@vm:~/small$ grep ana /etc/subuid /etc/subgid
/etc/subuid:ana:165536:65536
/etc/subgid:ana:165536:65536
ana@vm:~/small$ apt-cache depends podman | grep -E "uidmap|slirp4netns"
  Recommends: slirp4netns
  Recommends: uidmap
ana@vm:~/small$ podman run --rm --network=none docker.io/library/busybox:1.36 echo ok
ok
```

**`podman version 4.9.3` é a versão com que todas as transcrições da lição 18 foram gravadas.** O
`Rootless` diz `true`: este Podman roda como Ana, sem daemon por trás. A faixa dela começa no id 165536 e
tem 65.536 ids. O `apt-cache depends` mostra o `slirp4netns`, que dá rede a um contêiner rootless, e o
`uidmap`, cujos auxiliares montam o mapeamento de ids, sob `Recommends`. O último comando iniciou um
contêiner a partir do `busybox`, uma imagem minúscula de ferramentas Unix padrão no Docker Hub, e
imprimiu `ok` lá de dentro. A imagem já estava no armazenamento da Ana, então nenhum download aparece; a
primeira execução do Ben, no fim desta seção, mostra um.

Esse último comando leva `--network=none`, e nesta máquina precisa levar. Sem ele:

```
ana@vm:~/small$ podman run --rm docker.io/library/busybox:1.36 echo ok; echo $?
Error: /usr/bin/slirp4netns failed: "open(\"/dev/net/tun\"): Permission denied\nWARNING: Support for seccomp is experimental\nWARNING: Support for IPv6 is experimental\nchild failed(1)\nWARNING: Support for seccomp is experimental\nWARNING: Support for IPv6 is experimental\n"
126
ana@vm:~/small$ stat -c "%A %U %n" /dev/net/tun
crw------- root /dev/net/tun
```

**Status de saída 126, e uma mensagem sobre o `/dev/net/tun`.** A rede de um contêiner rootless é
montada pelo `slirp4netns` através desse dispositivo, e nesta máquina ele só pode ser lido e escrito
pelo root, o que é uma característica do sandbox em que o laboratório roda. Numa instalação comum do
Ubuntu, o comando sem a flag imprime `ok`. Todo contêiner da lição 18 roda com `--network=none` por esse
motivo, e não perde nada com isso, já que o `hits` lê um arquivo e nunca abre uma conexão.

## Três jeitos de ter um runtime de contêineres

```
ana@vm:~/small$ dpkg-query -W -f="\${Installed-Size} KB  \${Package} \${Version}\n" podman
42601 KB  podman 4.9.3+ds1-1ubuntu0.2
ana@vm:~/small$ apt-cache show --no-all-versions docker.io containerd | grep -E "^(Package|Version|Installed-Size)"
Package: docker.io
Installed-Size: 134107
Version: 29.1.3-0ubuntu3~24.04.2
Package: containerd
Installed-Size: 100805
Version: 2.2.1-0ubuntu1~24.04.3
```

| caminho | o que você ganha | quanto custa ao seu computador | as transcrições |
|---|---|---|---|
| **Podman** (recomendado) | contêineres rootless, sem daemon | 42.601 KB para o Podman em si, mais o runtime e os auxiliares que ele traz | batem |
| **Docker Engine** | o comando `docker`, e um daemon rodando como root | 134.107 KB para o `docker.io` e 100.805 KB para o `containerd`, os candidatos do repositório | `podman` vira `docker`; a saída difere em alguns pontos |
| **uma máquina virtual ou um sandbox online** | o Podman dentro da máquina virtual da lição 1, ou um playground de contêineres numa página web | o disco e a memória da máquina virtual, ou nada | na máquina virtual, batem |

**O Docker Engine é a outra escolha comum**, e o repositório do Ubuntu o traz como `docker.io`. A linha
de comando do Podman foi feita para seguir a do Docker, então `docker run --rm busybox:1.36 echo ok` é o
mesmo pedido. A diferença é o daemon: o `docker` pede a um serviço que roda como root que faça o
trabalho, e ter permissão para pedir, por estar no grupo `docker`, equivale a ser root naquela máquina.
Nenhum comando deste curso foi rodado com o Docker.

Uma máquina virtual é de novo o caminho da lição 1, com os passos acima lá dentro, e é o certo no
Windows e no macOS, onde contêineres precisam de um kernel Linux para rodar. Playgrounds online como o
Play with Docker existem, mas vêm e vão, e nada neste curso depende de um deles.

## Quando falha

A falha que para mais gente é uma conta sem faixa de ids: criada por uma ferramenta que não escreve no
`/etc/subuid`, ou numa máquina onde alguém arrumou o arquivo. Aqui está ela numa segunda conta, `ben`,
cujas linhas foram tiradas dos dois arquivos. O `sed` tira o carimbo de hora que o Podman põe no começo
de cada linha de log:

```
ben@vm:~$ grep ben /etc/subuid /etc/subgid; echo $?
1
ben@vm:~$ podman run --rm --network=none docker.io/library/busybox:1.36 echo ok 2>&1 | sed "s/^time=\"[^\"]*\" //"
level=warning msg="\"/\" is not a shared mount, this could cause issues or missing mounts with rootless containers"
level=error msg="cannot find UID/GID for user ben: no subuid ranges found for user \"ben\" in /etc/subuid - check rootless mode in man pages."
level=warning msg="Using rootless single mapping into the namespace. This might break some images. Check /etc/subuid and /etc/subgid for adding sub*ids if not using a network user"
Trying to pull docker.io/library/busybox:1.36...
Getting image source signatures
Copying blob sha256:034d6572bf287fa79604fee9be062f0683809ae3a3685bc7b0e17bd1c48c50e8
Error: copying system image from manifest list: writing blob: adding layer with blob "sha256:034d6572bf287fa79604fee9be062f0683809ae3a3685bc7b0e17bd1c48c50e8": processing tar file(potentially insufficient UIDs or GIDs available in user namespace (requested 65534:65534 for /home): Check /etc/subuid and /etc/subgid if configured locally and run "podman system migrate": lchown /home: invalid argument): exit status 1
```

**`no subuid ranges found for user "ben"` é a causa, e tudo o que vem depois é consequência.** O Podman
cai para o mapeamento de um id só, o do próprio Ben. Os arquivos da imagem pertencem a vários donos,
entre eles `nobody`, com id 65534, e não há para onde mapear esse dono, então descompactar a imagem
falha com `insufficient UIDs or GIDs`. A correção é uma faixa que não se sobreponha à de ninguém. A da
Ana termina em 231071, então a do Ben pode começar em 231072:

```sh
sudo usermod --add-subuids 231072-296607 --add-subgids 231072-296607 ben
```

Depois, como Ben, o `podman system migrate` faz o Podman passar a usar a faixa nova, e o mesmo comando
funciona:

```
ben@vm:~$ grep ben /etc/subuid /etc/subgid
/etc/subuid:ben:231072:65536
/etc/subgid:ben:231072:65536
ben@vm:~$ podman system migrate
ben@vm:~$ podman run --rm --network=none docker.io/library/busybox:1.36 echo ok 2>&1 | sed "s/^time=\"[^\"]*\" //"
level=warning msg="\"/\" is not a shared mount, this could cause issues or missing mounts with rootless containers"
Trying to pull docker.io/library/busybox:1.36...
Getting image source signatures
Copying blob sha256:034d6572bf287fa79604fee9be062f0683809ae3a3685bc7b0e17bd1c48c50e8
Copying config sha256:b116e155074440ffd9e449559433feb4cd2341eb3554b1da1c638c976e56451d
Writing manifest to image destination
ok
```

Desta vez a imagem foi baixada e descompactada, e o `ok` veio de dentro do contêiner. A primeira linha é
um aviso sobre como este sandbox monta o sistema de arquivos raiz; aparece para a conta nova do Ben e
não impede nada. Com `podman run ... echo ok` imprimindo `ok`, o laboratório está pronto para a lição
18.
