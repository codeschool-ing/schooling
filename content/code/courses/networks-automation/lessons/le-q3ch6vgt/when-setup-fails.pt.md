---
title: Quando a instalação falha
version: 1
---

A maioria das pessoas que desiste de um curso como este desiste aqui, num erro sobre uma máquina
que ainda não terminou de construir. Estas são as falhas que acontecem, mais ou menos na ordem em
que você as encontraria. Cada transcrição abaixo é a mensagem real, provocada de propósito na
máquina deste curso.

**A máquina virtual não liga, e a mensagem fala em virtualização, VT-x, AMD-V ou SVM.** O suporte
do processador a máquinas virtuais está desligado no firmware do computador. É uma opção no menu da
BIOS ou da UEFI, normalmente em *Advanced* ou *CPU configuration*, e muitos notebooks saem de fábrica
com ela desligada. Nenhum programa consegue ligá-la por você. Essa não foi provocada aqui, porque a
máquina do curso não roda hipervisor.

**O `multipass launch` desiste antes de a máquina ficar pronta.** A primeira criação baixa uma
imagem do Ubuntu de várias centenas de megabytes, e uma conexão lenta demora mais do que o Multipass
espera por padrão. Acrescente `--timeout 1800` ao comando e deixe terminar.

**O `apt-get` ou o `pip` não conseguem baixar nada.** Dentro da máquina virtual, `curl -sI
https://archive.ubuntu.com` deve imprimir uma linha de status. Se o nome não resolve, a máquina
virtual está sem DNS, o que normalmente quer dizer uma VPN ou um firewall no seu computador no
caminho.

**Você esqueceu o `sudo`.** Criar namespaces exige root, e o script avisa antes de mexer em
qualquer coisa:

```
ubuntu@netlab:~$ ~/netlab/netlab.sh up
run it with sudo
```

**O ambiente virtual não existe**, ou foi criado em outro lugar. A API dos roteadores e todo script
do curso rodam no Python de `/opt/netauto`, então o script se recusa a construir um laboratório com
que nada conseguiria conversar:

```
ubuntu@netlab:~$ sudo ~/netlab/netlab.sh reset
missing /opt/netauto: make the virtual environment first
```

Rode as duas linhas de `/opt/netauto` da seção sobre o software, no começo desta aula. Um pacote
faltando dá o mesmo tipo de mensagem, `install first:` seguido do nome dele, e a linha do `apt-get`
resolve.

**O laboratório já está de pé.** O `up` constrói um laboratório que não existe e não faz nada com
um que existe:

```
ubuntu@netlab:~$ sudo ~/netlab/netlab.sh up
netlab: already up; reset rebuilds it
```

O `reset` é o que você queria: ele derruba o laboratório e o constrói de novo.

**A máquina virtual foi reiniciada**, ou desligada e ligada de novo. Os network namespaces vivem na
memória do kernel, então um reinício leva o laboratório inteiro junto, e o primeiro comando nele
falha:

```
ubuntu@netlab:~$ sudo ~/netlab/netlab.sh enter ctl
Cannot open network namespace "ctl": No such file or directory
ubuntu@netlab:~$ sudo ~/netlab/netlab.sh up 2>&1 | tail -1
netlab: up: OSPF is Full and every service above answers
```

Nada quebrou, e o `up` o constrói de novo: ele limpa o que o laboratório antigo deixou em disco
antes de começar, então um laboratório interrompido no meio da construção volta do mesmo jeito. Os
arquivos da `ana` estão onde ela os deixou.

**O script foi salvo no Windows e copiado para dentro.** O Windows termina cada linha com dois
caracteres onde o Linux espera um, e a primeira linha do script passa a nomear um programa chamado
`bash` mais um retorno de carro invisível:

```
ubuntu@netlab:~$ sudo ~/netlab/netlab.sh up
/usr/bin/env: ‘bash\r’: No such file or directory
/usr/bin/env: use -[v]S to pass options in shebang lines
ubuntu@netlab:~$ file ~/netlab/netlab.sh
/home/ubuntu/netlab/netlab.sh: Bourne-Again shell script, ASCII text executable, with CRLF line terminators
ubuntu@netlab:~$ sed -i 's/\r$//' ~/netlab/netlab.sh
ubuntu@netlab:~$ file ~/netlab/netlab.sh
/home/ubuntu/netlab/netlab.sh: Bourne-Again shell script, ASCII text executable
netlab: devapi: started on core1, edge1 and edge2
netlab: nc1: started
netlab: tickets: started
netlab: napalm_frr: installed
netlab: netbox: started
netlab: sw1: started
netlab: up: OSPF is Full and every service above answers
```

O `file` diz `with CRLF line terminators`, o `sed` tira o caractere a mais de toda linha, e o
`file` concorda. Salvar o script de dentro da máquina virtual, com `nano ~/netlab/netlab.sh` e um
colar, evita o problema de vez.

**Um serviço não subiu.** Cada linha do `up` que termina em `started` foi conferida: a última coisa
que o script faz é esperar até cada um deles aceitar uma conexão, e ele nomeia o que nunca aceitou
com `nothing answers on` e o endereço. Essa linha quer dizer que o programa começou e parou de
novo, quase sempre porque foi cortado ou alterado no caminho para o arquivo. O erro dele está no
arquivo para onde o `netlab.sh` o manda, ao lado da linha que o liga: `/var/log/devapi.err` em cada
roteador, por exemplo, que o `enter` lê como `root`:
`sudo ~/netlab/netlab.sh enter core1 root 'tail /var/log/devapi.err'`. Um programa que nem está em
`~/netlab`, ou está lá com outro nome, não é um erro: a linha dele diz `skipped`.

**E quando nada mais funciona**, apague a máquina virtual e construa de novo: `multipass delete
--purge netlab`, e depois os comandos desta aula desde o começo. Parece desistir, e é o que quem
mantém laboratórios por profissão faz com uma máquina cujo estado ninguém mais sabe explicar. O
laboratório está escrito inteiro nesta aula, e é isso que torna barato jogá-lo fora.
