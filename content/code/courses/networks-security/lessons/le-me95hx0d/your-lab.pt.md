---
title: O seu laboratório, montado por você
version: 1
---

Nada neste curso roda numa máquina nossa. **Você monta o laboratório, e todo comando de toda aula é
digitado lá.** O laboratório é a rede de uma pequena empresa: um firewall, mais onze máquinas em seis
segmentos ao redor dele, e os serviços que elas rodam. Tudo isso vive dentro de um único computador
Linux, então basta uma máquina Ubuntu 24.04. A rede inteira fica pronta em poucos segundos, e uma
aula que quebra alguma coisa é uma aula que você pode recomeçar.

Há três jeitos de ter essa máquina. Escolha a máquina virtual, a não ser que tenha um motivo para não
escolher.

| | o que é | quanto custa |
|---|---|---|
| **uma máquina virtual com o Multipass** (recomendado) | a ferramenta da Canonical que cria uma máquina Ubuntu Server 24.04 com um comando, no Windows, no macOS e no Linux | 2 processadores, 2 GB de memória e 10 GB de disco enquanto ela roda |
| instalado | o Ubuntu 24.04 como sistema de um computador que você pode dispensar | nada a comprar, e todos os pacotes da lista abaixo instalados nesse computador de vez |
| online | uma pequena máquina Ubuntu 24.04 alugada por hora num provedor de nuvem | dinheiro enquanto ela existir |

**O laboratório altera o computador em que roda**, e é por isso que a máquina virtual vem primeiro.
Ele precisa de 32 pacotes, entre eles nginx, BIND e Suricata; guarda as máquinas em `/lab`, põe um
comando em `/usr/local/bin` e acrescenta a autoridade certificadora do próprio laboratório à lista
de autoridades em que o computador confia. Numa máquina virtual, tudo isso vai embora junto com a
máquina. **Instalado** só é a escolha certa num computador que você pode apagar depois.

Qualquer outro hipervisor serve no lugar do Multipass, com uma imagem do Ubuntu Server 24.04 LTS e os
mesmos 2 processadores, 2 GB e 10 GB: **VirtualBox** no Windows, no Linux ou num Mac com Intel,
**UTM** num Mac com Apple silicon, **Hyper-V** no Windows, **GNOME Boxes** ou **virt-manager** no
Linux. Eles custam meia hora de telas de instalação que o Multipass pula. **Online** é qualquer
provedor que alugue uma máquina Ubuntu 24.04 com acesso de root. Um plano gratuito serve, se você
tiver um, mas nada no curso depende dele. Nada do que o laboratório sobe escuta no endereço público
da máquina; todo serviço roda dentro das máquinas do próprio laboratório.

Um contêiner não serve: nem o Docker, nem o shell Linux que alguns sites abrem numa aba do navegador.
O laboratório cria namespaces de rede, e só o root de uma máquina inteira, real ou virtual, pode
criá-los.

## Com o Multipass

Instale o Multipass pelo site dele e então, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name nslab --cpus 2 --memory 2G --disk 10G
multipass shell nslab
```

**Esses dois comandos não foram rodados para este curso**, porque o computador em que ele foi gravado
é ele mesmo uma máquina virtual e não consegue rodar um hipervisor. O primeiro cria a máquina e o
segundo abre um shell dentro dela, como o usuário `ubuntu`. Tudo daqui em diante acontece nesse
shell.

## Os pacotes

Todo programa que o laboratório usa vem do repositório do próprio Ubuntu, então um `apt-get` instala
todos:

```sh
sudo apt-get update
sudo apt-get install -y iproute2 nftables conntrack tcpdump openssl nginx \
    libnginx-mod-http-modsecurity modsecurity-crs suricata jq wireguard-tools wireguard-go \
    dnsmasq-base bind9 bind9-dnsutils unbound netcat-openbsd curl iputils-ping iputils-arping \
    socat openssh-server ulogd2 ulogd2-json rsyslog aide hostapd wpasupplicant python3 \
    python3-cryptography python3-cffi-backend ethtool
```

No computador em que o curso foi gravado, que já tinha alguns deles, foram 134 pacotes: 30 MB para
baixar e 109 MB em disco. `dnsmasq-base` é o programa do servidor de nomes sem o serviço que o
iniciaria no próprio computador; o laboratório sobe a sua própria cópia dentro das máquinas, e faz o
mesmo com todos os outros servidores da lista.

A próxima seção é o script que monta a rede.
