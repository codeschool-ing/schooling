---
title: Seu laboratório, no seu computador
version: 1
---

Nada neste curso roda numa máquina hospedada por nós. **Você monta sozinho a rede do desenho acima, e
cada comando de cada aula é digitado lá.** É uma máquina Linux com Ubuntu 24.04, com treze máquinas
pequenas dentro dela, montadas por quatro arquivos que as próximas quatro seções mostram por inteiro.
Dá para desmontar e montar de novo em uns dez segundos. Isso importa mais do que tudo aqui: uma aula
que quebra a rede é uma aula que você pode repetir.

Há três jeitos de ter essa máquina Linux. Escolha a máquina virtual, a não ser que tenha um motivo
para não escolher.

| | o que é | quanto custa |
|---|---|---|
| instalado | Ubuntu 24.04 como sistema de um computador | nada a comprar; num computador que você usa para outras coisas, as mudanças listadas abaixo, para sempre |
| **uma máquina virtual com o Multipass** (recomendado) | a ferramenta da Canonical que cria uma máquina com Ubuntu Server 24.04 com um comando, no Windows, no macOS e no Linux | 2 processadores, 2 GB de memória e 10 GB de disco enquanto ela roda |
| online | uma pequena máquina virtual alugada por hora de um provedor de nuvem | dinheiro por cada hora em que ela existe, e uma máquina na internet desde o primeiro minuto |

**Instalado** serve num computador sobrando que você possa apagar, e é a escolha errada no que você
usa todo dia. O laboratório instala dez pacotes de servidor, cria quatro contas cujas senhas estão
impressas neste curso (`ana`, `bruno`, `example`, `scans`, e `ana` pode usar `sudo`), põe uma
autoridade certificadora de teste no repositório de confiança do sistema e mexe nas configurações de
login do servidor SSH. Numa máquina virtual nada disso toca o seu sistema. **Online** funciona porque
o laboratório não precisa de rede própria, só de uma máquina Linux com root. Qualquer provedor serve;
um plano gratuito é uma conveniência, não algo de que este curso dependa, e a máquina deve ser apagada
quando você parar no dia. No lugar do Multipass, qualquer hipervisor roda a mesma imagem de
instalação do Ubuntu Server 24.04: Hyper-V ou VirtualBox no Windows, UTM num Mac com Apple silicon,
GNOME Boxes ou virt-manager no Linux. Um container é a única coisa que não funciona, por um motivo que
a seção sobre falhas mostra: montar o laboratório é criar namespaces de rede, e um container em geral
não tem permissão para isso.

## Com o Multipass

Instale o Multipass pelo site dele e depois, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name netlab --cpus 2 --memory 2G --disk 10G
multipass shell netlab
```

**Esses dois comandos não foram rodados para este curso**, porque o computador em que ele foi
gravado não roda hipervisor. O primeiro cria a máquina e o segundo abre um shell dentro dela, como o
usuário `ubuntu`, num prompt que diz `ubuntu@netlab`. Tudo daqui em diante acontece nesse shell. Em
outro hipervisor, instale o Ubuntu Server 24.04 pela imagem, chame a máquina de `netlab` e dê à sua
conta qualquer nome menos `ana`, que o laboratório cria para si.

## Desligando o IPv6

O computador em que estas aulas foram gravadas não tinha IPv6 nenhum, e algumas transcrições mostram
isso: a aula 2 seção 03 pega um programa pedindo um socket IPv6 e sendo recusado. A sua máquina
virtual tem IPv6, então **desligue-o na máquina inteira**, com uma linha para o carregador de boot e
uma reinicialização:

```sh
sudo mkdir -p /etc/default/grub.d
echo 'GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT ipv6.disable=1"' | sudo tee /etc/default/grub.d/99-netlab.cfg
sudo update-grub
sudo reboot
```

A reinicialização fecha o seu shell; abra de novo com `multipass shell netlab`. Depois confira:

```
ubuntu@netlab:~$ ls /proc/sys/net/ipv6
ls: cannot access '/proc/sys/net/ipv6': No such file or directory
```

Esse erro é a resposta que você quer: o kernel não tem IPv6 para configurar. Se o `ls` listar
arquivos, a configuração não chegou ao carregador de boot, e a seção sobre falhas diz o que tentar.
É uma escolha para o laboratório ficar igual às gravações. Nada no curso precisa que o IPv6 falte; a
aula 2 seção 08 trata do que o IPv6 faz.

## Os pacotes

Todo programa que o laboratório roda vem do próprio repositório do Ubuntu:

```sh
echo 'postfix postfix/main_mailer_type select No configuration' | sudo debconf-set-selections
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iproute2 bind9 bind9-dnsutils unbound \
    nginx openssl tcpdump traceroute mtr-tiny netcat-openbsd curl openssh-server nftables vsftpd \
    tnftp rsync postfix dovecot-imapd dovecot-pop3d opendkim opendkim-tools opendmarc swaks \
    iputils-ping iputils-tracepath strace python3
sudo systemctl disable --now named unbound nginx vsftpd postfix dovecot opendkim opendmarc
```

A primeira linha responde de antemão a única pergunta que o servidor de e-mail faria durante a
instalação. **A última linha para as cópias que o Ubuntu inicia sozinho.** O laboratório inicia as
suas, uma por máquina, cada uma com sua própria configuração; as cópias do sistema inteiro só
gastariam memória e confundiriam um `ss` mais tarde. O servidor SSH continua ligado, porque é por ele
que o Multipass chega à máquina. Essa última linha também não foi rodada para este curso: o
computador em que ele foi gravado não tinha systemd para parar nada.

A próxima seção põe o primeiro dos quatro arquivos no lugar.
