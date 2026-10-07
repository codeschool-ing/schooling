---
title: O seu laboratório, e três jeitos de ter um
version: 1
---

Todo comando deste curso foi executado, e toda linha de saída é o que o comando imprimiu. **Você
também os executa, num laboratório que constrói nesta aula.** Nada roda numa máquina nossa.

O laboratório é uma rede pequena: três roteadores com OSPF entre eles, um equipamento gerido só
pelo seu modelo de dados, o NetBox, uma central de chamados, um switch OpenFlow, alguns
computadores para testar, e o `ctl`, o host de automação onde você trabalha. Comprar isso custaria
um rack. Aqui custa uma máquina Linux, porque cada um desses equipamentos é um **network
namespace**: uma cópia da pilha de rede do Linux com as próprias interfaces, endereços e rotas,
ligada às outras por cabos virtuais. O software de roteamento é real, as APIs são reais, e os
pacotes trafegam de verdade entre os namespaces; o que falta é só o hardware.

Essa máquina precisa rodar o **Ubuntu 24.04 LTS**. Os roteadores são o FRR dos pacotes do próprio
Ubuntu, e as transcrições das aulas foram feitas exatamente com as versões que o Ubuntu 24.04 traz.

| caminho | o que é | quanto custa ao seu computador | as transcrições |
|---|---|---|---|
| **uma máquina virtual** (recomendado) | Ubuntu Server 24.04 numa VM feita com o Multipass | 2 processadores, 4 GB de memória e 20 GB de disco enquanto roda | batem como impresso |
| instalado | Ubuntu 24.04 como sistema de um computador que você pode ceder | nada a mais, e o equivalente a nove máquinas de serviços somados a esse computador | batem como impresso |
| online | um servidor Ubuntu 24.04 alugado por hora de um provedor de nuvem | nada; o provedor cobra por hora | batem como impresso |

Esses tamanhos têm folga, e a folga foi medida. Na máquina em que este curso foi gravado, o
laboratório inteiro usou 830 MB de memória com o NetBox e todos os outros serviços rodando. Em
disco, os dois ambientes Python que ele instala ocupam 214 MB e 542 MB, o código-fonte do Clixon
51 MB e o banco salvo do NetBox 84 MB, mais os pacotes do Ubuntu. O resto dos 4 GB é para o próprio
Ubuntu e para compilar o Clixon na aula 3. O disco padrão do Multipass, 5 GB, é pequeno demais.

**A máquina virtual é o caminho recomendado.** O laboratório instala software de roteamento, um
banco de dados, um cache e um switch em software, e precisa de `sudo` para criar namespaces. Tudo
isso fica melhor dentro de uma máquina que você pode apagar. O **Multipass**, a ferramenta da
Canonical, cria uma VM Ubuntu com um comando no Windows, no macOS e no Linux. Qualquer outro
hipervisor serve no lugar dele, ao preço de passar por um instalador: VirtualBox no Windows e no
Linux, UTM num Mac com Apple silicon, Hyper-V no Windows Pro, GNOME Boxes no Linux. Num Mac com
Apple silicon a máquina virtual é ARM em vez de x86; os pacotes do Ubuntu e as bibliotecas Python
existem para os dois, e o único download da aula 4 diz qual escolher.

**Instalado** serve num computador de sobra que já roda o Ubuntu 24.04. No computador que você usa
todo dia é a escolha errada, porque tudo o que o laboratório instala continua instalado.

**Online** é qualquer provedor que alugue um servidor Ubuntu 24.04: as três grandes nuvens e as
empresas de hospedagem menores alugam. Algumas dão uma cota gratuita para contas novas, e os termos
são delas para mudar, então nenhuma aula depende de uma. Um servidor alugado está na internet desde
o primeiro minuto; o laboratório em si nunca escuta no endereço público, mas deixe o SSH do
próprio servidor fechado com chave. Este curso foi gravado numa máquina exatamente desse tipo.

## Com o Multipass

Instale o Multipass pelo site dele e então, no terminal do seu próprio computador:

```
$ multipass launch 24.04 --name netlab --cpus 2 --memory 4G --disk 20G
$ multipass shell netlab
```

**Esses dois comandos não foram executados para este curso**, porque o computador em que ele foi
gravado não roda hipervisor. O primeiro cria a máquina virtual e o segundo abre um shell dentro
dela, como o usuário `ubuntu`, numa máquina chamada `netlab`. Tudo daqui em diante é digitado nesse
shell.

## O software

Tudo menos quatro programas vem do repositório do Ubuntu, então um `apt-get` instala: o FRR e sua
ferramenta de reload, o OpenSSH, o Open vSwitch, o Ansible, o PostgreSQL e o Redis do NetBox, e as
ferramentas pequenas que as aulas usam.

```sh
sudo apt-get update
sudo apt-get install -y frr frr-pythontools openssh-server openvswitch-switch python3-venv \
    ansible yamllint git curl jq openssl postgresql redis-server libyang-tools libxml2-utils \
    iproute2 iputils-ping traceroute netcat-openbsd python3-paramiko
```

O Ubuntu liga alguns deles como serviços da própria máquina virtual. O laboratório roda as suas
próprias cópias dentro das suas máquinas e nunca usa estas, então pare-as e economize a memória:

```sh
sudo systemctl disable --now frr postgresql redis-server openvswitch-switch
```

**Essa linha não foi executada para este curso**: a máquina em que ele foi gravado não tem
systemd, então nada foi ligado para começo de conversa.

As bibliotecas Python vão num **ambiente virtual**, um diretório com o próprio Python e os próprios
pacotes, para que nada aqui mexa no Python em que o Ubuntu roda. Ele fica em `/opt/netauto`, fora
da home de qualquer pessoa, porque as máquinas do laboratório o compartilham. As versões são fixas,
porque uma biblioteca mais nova pode imprimir algo diferente da transcrição que você está lendo:

```sh
sudo python3 -m venv /opt/netauto
sudo /opt/netauto/bin/pip install netmiko==4.8.0 napalm==5.2.0 nornir==3.6.0 nornir-netmiko==1.0.1 \
    nornir-napalm==0.6.0 nornir-utils==0.3.0 nornir-netbox==0.3.0 ncclient==0.7.0 pygnmi==0.8.15 \
    paramiko==5.0.0 Jinja2==3.1.6 pyang==2.7.1 requests==2.34.2 pytest==9.1.1 PyYAML==6.0.3 \
    xmltodict==1.0.4 grpcio==1.84.0 pynetbox==7.8.0 ansible-pylibssh==1.4.0 os-ken==4.2.2
```

Os quatro programas que não estão no repositório chegam com as aulas que os usam: o Clixon na aula
3, o `gnmic` na aula 4, os modelos da OpenConfig na aula 5 e o NetBox na aula 12. Cada uma dessas
aulas dá os comandos onde eles fazem falta pela primeira vez.
