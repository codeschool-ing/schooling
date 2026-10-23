---
title: O seu laboratório, montado por você
version: 1
---

Nada neste curso roda numa máquina nossa. **Você monta o laboratório e digita ali cada comando de
cada aula.** Endurecimento é um assunto que se aprende mudando um sistema e conferindo o que mudou,
às vezes quebrando, então o laboratório foi feito para ser jogado fora: um comando devolve uma cópia
nova de todas as máquinas em mais ou menos um minuto.

O laboratório é um pequeno escritório de contabilidade, a Jatobá Contabilidade, em sete máquinas num
mesmo segmento de rede. `web` é o portal de clientes do escritório, o servidor que o curso mais
endurece. `desk` é uma estação de trabalho, `admin` é de onde um administrador trabalha, `jump` é a
porta única que a aula 15 constrói, `dns` é o servidor de nomes do escritório, `trap` é a isca da
aula 13 e `sw` é o switch em que todas estão ligadas. As sete são contêineres num único computador
Linux com **Ubuntu 24.04**, e esse computador é a única coisa que você precisa providenciar.

Há três jeitos de consegui-lo. Fique com a máquina virtual, a não ser que tenha um motivo para não
ficar.

| | o que é | quanto custa |
|---|---|---|
| **uma máquina virtual com Multipass** (recomendado) | a ferramenta da Canonical que cria uma máquina Ubuntu Server 24.04 com um comando, no Windows, no macOS e no Linux | 2 processadores, 4 GB de memória e 20 GB de disco enquanto roda |
| instalado | o Ubuntu 24.04 como sistema de um computador que você possa dispensar | nada a comprar, e os dois pacotes do laboratório e 7 GB de máquinas nesse computador até você apagá-los |
| online | uma pequena máquina Ubuntu 24.04 alugada por hora de um provedor de nuvem | dinheiro enquanto ela existir |

**O laboratório pede root no computador em que roda**, e é por isso que a máquina virtual vem
primeiro. Ele cria namespaces de rede, dá boot em contêineres e grava 7 GB em `/var/lib/hostlab`.
Numa máquina virtual, tudo isso some junto com a máquina, e uma aula que quebre o próprio computador,
e não um dos contêineres, custa uma máquina virtual nova e mais nada. **Instalado** só serve para um
computador que você possa apagar depois.

Qualquer outro hipervisor serve no lugar do Multipass, com uma imagem Ubuntu Server 24.04 LTS e os
mesmos 2 processadores, 4 GB e 20 GB: **VirtualBox** no Windows, no Linux ou num Mac Intel, **UTM**
num Mac com Apple silicon, **Hyper-V** no Windows, **GNOME Boxes** ou **virt-manager** no Linux.
Custam meia hora de telas de instalação que o Multipass pula. **Online** é qualquer provedor que
alugue uma máquina Ubuntu 24.04 com acesso de root. Um plano gratuito serve se você tiver um, mas
nada no curso depende dele, e nada que o laboratório sobe escuta no endereço público dessa máquina:
as sete máquinas vivem numa rede própria, que não está ligada a nada.

Um contêiner não serve como computador: nem Docker, nem LXD, nem o shell Linux que alguns sites abrem
numa aba do navegador. O laboratório é feito de contêineres, e só o root de uma máquina inteira, real
ou virtual, pode criá-los.

## Com Multipass

Instale o Multipass a partir do site dele e depois, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name hostlab --cpus 2 --memory 4G --disk 20G
multipass shell hostlab
```

**Esses dois comandos não foram executados para este curso**, porque o computador em que ele foi
gravado é ele mesmo uma máquina virtual e não consegue rodar um hipervisor. O primeiro cria a máquina
e o segundo abre um shell dentro dela, como o usuário `ubuntu`. Tudo daqui em diante acontece nesse
shell. Onde um transcrito do curso diz `ana`, as suas máquinas vão dizer `ubuntu`, ou o nome que a
sua conta tiver.

## Os dois pacotes

O script que monta o laboratório precisa de dois programas que um Ubuntu Server recém-instalado não
tem: `debootstrap`, que baixa um Ubuntu mínimo para dentro de um diretório, e `systemd-nspawn`, que dá
boot nele. Os dois vêm do próprio repositório do Ubuntu:

```sh
sudo apt-get update
sudo apt-get install -y debootstrap systemd-container
```

Todo o resto que o curso usa é instalado dentro das máquinas pelo script, do mesmo repositório, então
o computador que você escolheu fica como estava, tirando esses dois e o diretório do próprio
laboratório. A próxima seção é o script.
