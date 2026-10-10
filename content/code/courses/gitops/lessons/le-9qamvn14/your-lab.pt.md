---
title: Sua máquina é o laboratório
version: 1
---

**Tudo o que este curso mostra, você roda, num computador seu.** Ninguém entrega um cluster ou um
servidor Git. Esta aula monta a base que todas as outras usam: Docker, um cluster Kubernetes de um
nó criado pelo `kind`, um registry de imagens ao lado e o `kubectl`. A aula 2 acrescenta um servidor
Git num container, e cada aula seguinte instala a ferramenta de que trata, com os comandos para
isso, na seção que precisa dela primeiro:

| aula | o que acrescenta |
|---|---|
| 1 | Docker, `kind`, `kubectl`, o registry, o cluster |
| 2 | Gitea, um servidor Git, num container |
| 3 | o Argo CD no cluster, e o comando `argocd` |
| 4 | o Flux no cluster, e o comando `flux` |
| 6 | `helm` |
| 8 | `cosign` |
| 9 | o controlador do Sealed Secrets e o `kubeseal`; `sops` e `age`; o Vault, num container, e o comando `vault` |
| 10 | o External Secrets Operator |
| 11 | PostgreSQL, num container |

Tudo nessa lista é software livre, e nada exige conta em lugar nenhum.

## Três caminhos

| caminho | o que é | o que custa ao seu computador |
|---|---|---|
| instalado | as ferramentas num computador que já roda Linux | cerca de 1,5 GiB de memória com o cluster, o registry e o Gitea rodando, até 3 GiB nas aulas 3 e 4, e 15 GiB de disco |
| **uma máquina virtual com Multipass** (recomendado) | Ubuntu Server 24.04 numa VM criada com um comando, no Windows, no macOS ou no Linux, com as mesmas ferramentas dentro | 4 processadores, 8 GiB de memória e 40 GiB de disco enquanto roda |
| online | uma máquina virtual Linux alugada por hora em qualquer provedor de nuvem | nada no seu computador; dinheiro por cada hora em que ela existir, e ela precisa ser apagada quando você parar |

**A máquina virtual é a recomendação**, porque tudo aqui foi escrito para Linux e parte disso passa
do `kubectl` para a máquina de baixo: o nó é um container Docker em que você entra com `docker exec`,
e o registry e o Gitea são alcançados pelo nome do container de dentro do cluster. Numa VM Ubuntu
isso funciona igual em qualquer máquina. O Multipass, ferramenta da Canonical, cria a VM com um
comando e usa o hipervisor que o seu sistema tiver: Hyper-V no Windows (VirtualBox no Windows Home),
o framework de virtualização embutido no macOS e KVM no Linux. Qualquer outro hipervisor serve
também, VirtualBox, UTM num Mac com Apple silicon ou GNOME Boxes, ao preço de um instalador para
clicar. O curso `virtualization` monta uma à mão na aula 4.

**Instalado** é a mesma coisa sem a VM, e é a melhor escolha se o seu computador já roda Ubuntu ou
outro Linux: nada abaixo muda, exceto que você pula os próximos dois comandos. O Docker Desktop no
Windows ou no macOS também roda o `kind`, e quase todo o curso funciona lá, mas os nomes dos
containers da rede do Docker não são alcançáveis do seu terminal, e alguns comandos que os usam
falham.

**Online** funciona e custa dinheiro. A menor máquina de qualquer provedor com 4 processadores e 8
GiB roda o curso, e os comandos são os de baixo, digitados por SSH. Ele é citado para você saber que
existe; nenhuma aula depende dele, e uma máquina esquecida ligada cobra quer você use, quer não.

## A máquina virtual

Instale o Multipass pelo site dele e, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name gitops --cpus 4 --memory 8G --disk 40G
multipass shell gitops
```

**Esses dois comandos não foram executados para este curso**, porque o computador em que ele foi
gravado não roda um hipervisor. O primeiro cria a VM e o segundo abre um shell dentro dela, como o
usuário `ubuntu`. Tudo daqui em diante acontece nesse shell. Com 6 GiB de memória todas as aulas
ainda funcionam, desde que você não mantenha o Argo CD e o Flux rodando ao mesmo tempo; a aula 4 diz
quando remover um deles.

Um snapshot da VM depois que a próxima seção funcionar, com `multipass stop gitops` e depois
`multipass snapshot gitops`, dá a você um começo limpo sempre que um experimento der errado.
