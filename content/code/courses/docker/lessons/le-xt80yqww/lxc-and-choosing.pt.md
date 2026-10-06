---
title: LXC, e como escolher
version: 1
---

**Tudo neste curso foi container de aplicação: um programa, os arquivos dele, e paredes em volta.** O
LXC, mais antigo que o Docker, faz outro tipo: um **container de sistema**, um userland Linux inteiro
com processo init, serviços e usuários próprios, que se comporta como uma máquina virtual pequena
enquanto divide o kernel do host como qualquer container.

O LXC não foi executado no laboratório: um container de sistema parte de uma imagem de distribuição
inteira, do servidor de imagens do próprio LXC, e este curso ficou nas imagens OCI. Para que ele serve
dá para dizer sem rodá-lo. O **Incus**, a continuação comunitária do LXD, administra containers LXC e
máquinas virtuais com um comando só, e é como a maioria das pessoas o conhece hoje.

- **Um container de sistema** é onde você poria uma máquina de vida longa em que se entra, se corrige e
  se mantém: um host de build, um laboratório, um serviço que espera o systemd.
- **Um container de aplicação** é o que este curso construiu: substituído, nunca corrigido, um processo,
  a imagem como unidade de versão.

## As ferramentas lado a lado

| ferramenta | daemon | usuário padrão | constrói imagens | arquivos do Compose | uso típico |
| --- | --- | --- | --- | --- | --- |
| Docker Engine | `dockerd` | root | sim, BuildKit | sim | desenvolvimento e hosts únicos |
| Podman | nenhum | o usuário | sim, Buildah | sim, `podman compose` | hosts sem root, família RHEL |
| containerd + nerdctl | `containerd` | root | sim, com BuildKit | sim | o runtime debaixo do Kubernetes |
| LXC / Incus | `incusd` | root | não; imagens de sistema | não | containers de sistema, VMs pequenas |

**Todos menos o último rodam as mesmas imagens OCI**, então a escolha é sobre a máquina e a equipe, e
não sobre reconstruir nada. Um notebook com Docker, um servidor com Podman, um cluster com containerd:
uma imagem, construída uma vez pelo pipeline da aula 26, e nomeada pelo digest.

## Onde o curso deixa você

A aula 1 começou de um programa que funcionava numa máquina e não em outra. Desde então, o `shelf` virou
uma imagem construída em estágios, pequena e sem root nem shell, varrida, com lista de materiais e
proveniência, publicada por um pipeline com todas as verificações à frente, e rodada com limites, health
checks e políticas de reinício, sozinha ou num swarm. O próximo curso na maioria das trilhas é o
`kubernetes`, e a primeira aula dele parte da última etapa da aula 27: o que uma máquina só não consegue
fazer.
