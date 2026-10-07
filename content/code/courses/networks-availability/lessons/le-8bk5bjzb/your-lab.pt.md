---
title: O seu laboratório, no seu computador
version: 1
---

Este curso tem dezesseis máquinas: uma matriz com dois roteadores, um servidor de arquivos e um laptop;
uma filial com o roteador dela e um caixa; uma casa com o roteador dela e o laptop da Ana; um provedor;
um data center com um servidor DNS, dois balanceadores de carga e três servidores web; e uma máquina de
analista para capturar tráfego. **Você monta todas elas, dentro de uma máquina Linux, e cada comando de
cada aula é digitado lá.** Nada roda num computador nosso.

Não são dezesseis máquinas virtuais. Cada uma é um **namespace de rede**: uma cópia da pilha de rede do
Linux com interfaces, endereços, rotas e firewall próprios, dentro de um único sistema em execução. Um
cabo é um par de interfaces Ethernet virtuais, e um switch é uma bridge do Linux. Para os programas que
rodam nelas, são máquinas separadas; o `tcpdump` numa delas vê só o tráfego daquela máquina, e um ping
entre duas atravessa todos os roteadores do caminho. A rede inteira ocupa uns 70 MB de memória e 80 MB de
disco, e fica pronta em uns dez segundos, então uma aula que a quebre é uma aula que você pode repetir.

O que ela precisa é de **uma máquina Linux onde você seja root**: Ubuntu 24.04, o sistema em que todas as
transcrições deste curso foram gravadas. Há três jeitos de ter uma. Escolha a máquina virtual, a não ser
que tenha um motivo para não escolher.

| | o que é | quanto custa |
|---|---|---|
| instalado | Ubuntu 24.04 num computador só para isso, ou como sistema do computador que você usa | nada a comprar, e vinte e cinco pacotes nesse computador para sempre, entre eles um servidor DNS e um servidor de VPN |
| **uma máquina virtual com o Multipass** (recomendado) | a ferramenta da Canonical que cria uma máquina Ubuntu Server 24.04 com um comando, no Windows, no macOS e no Linux | 2 processadores, 2 GB de memória e 10 GB de disco enquanto ela roda |
| online | um servidor Linux pequeno alugado por hora de um provedor de nuvem | dinheiro por cada hora que ele existir, e uma máquina na internet desde o primeiro minuto |

**Instalado** funciona, e a rede em si não deixa nada para trás quando você a desmonta. Os pacotes ficam,
porém, e vários deles são servidores. Um computador sobrando, que você possa apagar, é o lugar certo; o
computador do dia a dia não é.

**A máquina virtual** é o caminho recomendado porque não custa nada e some com um comando. O Multipass
usa o hipervisor que cada sistema já tem: o Hyper-V no Windows, o framework de virtualização do macOS num
Mac, o KVM no Linux. Qualquer outro hipervisor também serve, com a imagem de instalação do Ubuntu Server
24.04 e meia hora de telas de instalador: VirtualBox no Windows, no Linux ou num Mac Intel, UTM num Mac
com Apple silicon, o Gerenciador do Hyper-V no Windows, GNOME Boxes ou virt-manager no Linux.

**Online** aparece aqui para você saber que existe. O menor servidor Ubuntu 24.04 de qualquer provedor
basta. A rede que o curso monta nunca chega à internet, então estar online não é um risco para ela, mas
o servidor em si é, e custa dinheiro enquanto existir. Alguns provedores têm um plano gratuito; este
curso não depende de nenhum, porque as regras de um plano gratuito são do provedor, e ele pode mudá-las.

## Com o Multipass

Instale o Multipass pelo site dele e, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name netlab --cpus 2 --memory 2G --disk 10G
multipass shell netlab
```

**Esses dois comandos não foram executados para este curso**, porque o computador em que ele foi gravado
não consegue rodar um hipervisor. O primeiro cria a máquina, chamada `netlab`, e o segundo abre um shell
dentro dela. Tudo daqui em diante acontece nesse shell, e as aulas muitas vezes querem dois ou três ao
mesmo tempo, um por máquina que você está observando: abra outro terminal e rode `multipass shell netlab`
de novo.

## Os pacotes

Todo programa que o curso usa vem do repositório do próprio Ubuntu:

```sh
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iproute2 nftables bind9 bind9-dnsutils \
    nginx openssl tcpdump tshark traceroute mtr-tiny iperf3 netcat-openbsd curl iputils-ping \
    ethtool wireguard-tools wireguard-go openvpn strongswan-swanctl strongswan-charon \
    libcharon-extra-plugins keepalived haproxy python3
```

O `DEBIAN_FRONTEND=noninteractive` impede o instalador de perguntar se usuários comuns podem capturar
pacotes; o script da próxima seção responde a essa pergunta por conta própria, de forma mais estreita. O
Ubuntu inicia alguns desses servidores enquanto os instala. Eles rodam na rede da própria máquina, fora
de qualquer namespace, então nunca encontram as cópias que o curso inicia dentro das máquinas dele, cada
uma com a sua configuração.
