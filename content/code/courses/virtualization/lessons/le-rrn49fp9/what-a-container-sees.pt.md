---
title: O que um contêiner vê
version: 1
---

Por dentro, um contêiner parece um pequeno sistema próprio:

```
ana@host:~$ sudo podman run --rm docker.io/library/ubuntu:24.04 bash -c "echo my pid is \$\$; hostname; ls /"
my pid is 1
96e7cc50c11d
bin
boot
dev
etc
home
lib
lib64
media
mnt
opt
proc
root
run
sbin
srv
sys
tmp
usr
var
```

O shell dele é o **processo 1**, o primeiro processo do mundo dele, embora no host seja um processo entre
muitos. Ele tem **o próprio hostname**, o id do contêiner. E tem **os próprios arquivos**, uma árvore de
diretórios do Ubuntu inteira, que veio da imagem. É isso que os *namespaces* do kernel fazem: cada um dá a
um grupo de processos uma visão própria de uma coisa, a lista de processos, o nome, os arquivos, a rede,
enquanto todos rodam no mesmo kernel.

A imagem é pequena porque não guarda kernel nem firmware, só arquivos: a `ubuntu:24.04` tem
80.7 MB, onde o disco Ubuntu do laboratório guarda um sistema de 3,5 GiB. E **a imagem não muda**: o
contêiner escreve numa camada própria por cima dela, a sobreposição da aula 1 de novo, e essa camada vai
embora quando o contêiner é removido.
