---
title: Quando a preparação falha
version: 1
---

Toda falha abaixo aconteceu enquanto esta aula era gravada, no computador em que foi gravada, e cada uma
vem com a cara que tem e o que a corrige. A maioria falha alto. Duas não, e são essas que vale lembrar.

**O processador não ajuda.** O `kvm-ok` disse `KVM acceleration can NOT be used` na seção 03, e o
dispositivo pelo qual o KVM trabalha nem existe:

```
ana@host:~$ ls -l /dev/kvm
ls: cannot access '/dev/kvm': No such file or directory
```

O laboratório funciona assim mesmo: o `virt-install` volta sozinho para a imitação do QEMU, com o aviso da
seção 06, e todo convidado fica várias vezes mais lento, o que a aula 2 mede. Para ter a velocidade de
volta, primeiro ligue *Intel Virtualization Technology*, *VT-x*, *SVM Mode* ou *AMD-V* no setup UEFI do
computador, já que muitos PCs saem de fábrica com isso desligado. No Windows, um laboratório numa máquina
virtual disputa o mesmo recurso com o Hyper-V, o WSL 2 e a integridade de memória, o que a aula 2
explica. Numa máquina virtual ou num servidor alugado, ligue a virtualização aninhada, seção 02, ou
aceite a velocidade.

**O `virsh list` não mostra nada, e nenhum erro.** É a sessão de antes do seu próximo login, seção 03: o
`virsh uri` diz `qemu:///session`, e você está olhando uma lista particular e vazia enquanto os seus
convidados rodam na do sistema. Saia e entre de novo, e confira se o `groups` inclui `libvirt`.

**Um disco na sua pasta pessoal.** O libvirt abre os discos de um convidado como um usuário só dele, e a
sua pasta pessoal é fechada para os outros usuários:

```
ana@host:~$ ls -ld ~ && sudo virt-install --name vm2 --memory 1024 --vcpus 2 --import --disk ~/vm2.qcow2,bus=virtio --os-variant ubuntu24.04 --network network=default --graphics none --noautoconsole
drwxr-x--- 5 ana ana 4096 Oct  7 05:42 /home/ana
WARNING  KVM acceleration not available, using 'qemu'
WARNING  /home/ana/vm2.qcow2 may not be accessible by the hypervisor. You will need to grant the 'libvirt-qemu' user search permissions for the following directories: ['/home/ana']
WARNING  Requested memory 1024 MiB is less than the recommended 3072 MiB for OS ubuntu24.04
ERROR    Cannot access storage file '/home/ana/vm2.qcow2' (as uid:64055, gid:995): Permission denied
Domain installation does not appear to have been successful.
If it was, you can restart your domain by running:
  virsh --connect qemu:///system start vm2
otherwise, please restart your installation.

Starting install...
```

O `drwxr-x---` deixa entrar você e o seu grupo, e o `uid:64055` é o `libvirt-qemu`, que não é nenhum dos
dois. A correção é guardar os discos do laboratório em `/var/lib/libvirt/images`, como todo comando deste
curso faz, e não abrir a sua pasta pessoal para todo mundo.

**A rede default não sobe.** Um computador que é ele mesmo um convidado do libvirt é o segundo caminho
da seção 02 com o QEMU como hypervisor de fora, e a rede de fora dele muitas vezes usa a mesma
`192.168.122.0/24` que a de dentro. Aqui uma segunda interface recebeu essa faixa de propósito, para
mostrar:

```
ana@host:~$ virsh net-start default
error: Failed to start network default
error: internal error: Network is already in use by interface office0
```

O libvirt se recusa a fazer duas redes com uma faixa. A correção é dar outra faixa à rede de dentro:
`virsh net-edit default`, trocar `192.168.122` por `192.168.123` nos três lugares em que aparece, e
`virsh net-start default`.

**O virt-customize não alcança a internet.** É isto que acontece no Ubuntu 24.04 sem o
`isc-dhcp-client`:

```
ana@host:~$ cp ubuntu-24.04-minimal-cloudimg-amd64.img try.qcow2
ana@host:~$ sudo virt-customize -a try.qcow2 --install qemu-guest-agent,nginx-light,curl,netcat-openbsd,tcpdump --run-command "systemctl disable nginx" --truncate /etc/machine-id
[   0.0] Examining the guest ...
[  53.4] Setting a random seed
virt-customize: warning: random seed could not be set for this type of guest
[  53.8] Setting the machine ID in /etc/machine-id
[  53.8] Installing packages: qemu-guest-agent nginx-light curl netcat-openbsd tcpdump
Ign:1 http://security.ubuntu.com/ubuntu noble-security InRelease
Ign:2 http://archive.ubuntu.com/ubuntu noble InRelease
Ign:3 http://archive.ubuntu.com/ubuntu noble-updates InRelease
Ign:4 http://archive.ubuntu.com/ubuntu noble-backports InRelease
Ign:1 http://security.ubuntu.com/ubuntu noble-security InRelease
Ign:2 http://archive.ubuntu.com/ubuntu noble InRelease
Ign:3 http://archive.ubuntu.com/ubuntu noble-updates InRelease
Ign:4 http://archive.ubuntu.com/ubuntu noble-backports InRelease
Ign:1 http://security.ubuntu.com/ubuntu noble-security InRelease
Ign:2 http://archive.ubuntu.com/ubuntu noble InRelease
Ign:3 http://archive.ubuntu.com/ubuntu noble-updates InRelease
Ign:4 http://archive.ubuntu.com/ubuntu noble-backports InRelease
Err:1 http://security.ubuntu.com/ubuntu noble-security InRelease
  Temporary failure resolving 'security.ubuntu.com'
Err:2 http://archive.ubuntu.com/ubuntu noble InRelease
  Temporary failure resolving 'archive.ubuntu.com'
Err:3 http://archive.ubuntu.com/ubuntu noble-updates InRelease
  Temporary failure resolving 'archive.ubuntu.com'
Err:4 http://archive.ubuntu.com/ubuntu noble-backports InRelease
  Temporary failure resolving 'archive.ubuntu.com'
Reading package lists...
W: Failed to fetch http://archive.ubuntu.com/ubuntu/dists/noble/InRelease  Temporary failure resolving 'archive.ubuntu.com'
W: Failed to fetch http://archive.ubuntu.com/ubuntu/dists/noble-updates/InRelease  Temporary failure resolving 'archive.ubuntu.com'
W: Failed to fetch http://archive.ubuntu.com/ubuntu/dists/noble-backports/InRelease  Temporary failure resolving 'archive.ubuntu.com'
W: Failed to fetch http://security.ubuntu.com/ubuntu/dists/noble-security/InRelease  Temporary failure resolving 'security.ubuntu.com'
W: Some index files failed to download. They have been ignored, or old ones used instead.
Reading package lists...
Building dependency tree...
Reading state information...
E: Unable to locate package qemu-guest-agent
E: Unable to locate package nginx-light
E: Unable to locate package netcat-openbsd
E: Unable to locate package tcpdump
virt-customize: error: 
      export DEBIAN_FRONTEND=noninteractive
      apt_opts='-q -y -o Dpkg::Options::=--force-confnew'
      apt-get $apt_opts update
      apt-get $apt_opts install 'qemu-guest-agent' 'nginx-light' 'curl' 'netcat-openbsd' 'tcpdump'
    : command exited with an error

If reporting bugs, run virt-customize with debugging enabled and include the complete output:

  virt-customize -v -x [...]
```

`Temporary failure resolving` quer dizer que o sistema ajudante não tinha rede nenhuma. A partida dele
pede um endereço com o `dhclient`, que esse pacote fornece e o Ubuntu 24.04 não instala mais, e nada diz
que o motivo é esse. `sudo apt install isc-dhcp-client` resolve. Depois, **recomece de uma cópia nova**
da imagem baixada, porque a execução que falhou já tinha escrito nesta.

**O convidado roda, tem endereço, e não deixa você entrar.** Esta é silenciosa, e é um erro no seed. Aqui
a primeira linha do `user-data` ficou de fora:

```
ana@host:~$ head -2 user-data
hostname: vm2
users:
ana@host:~$ ssh vm2 hostname
ana@vm2: Permission denied (publickey).
ana@host:~$ virsh domifaddr vm2 --source agent
 Name       MAC address          Protocol     Address
-------------------------------------------------------------------------------
 lo         00:00:00:00:00:00    ipv4         127.0.0.1/8
 -          -                    ipv6         ::1/128
 enp1s0     52:54:00:95:11:31    ipv4         192.168.122.116/24
 -          -                    ipv6         fe80::5054:ff:fe95:1131/64
```

O agente do convidado respondeu, então o convidado está de pé e na rede, e o ssh ainda disse `Permission
denied (publickey)`: sem o `#cloud-config` o arquivo foi ignorado, nenhum usuário foi criado e nenhuma
chave entrou. Apague o convidado, `virsh destroy vm2` e `virsh undefine vm2`, corrija o arquivo, e faça o
seed e o convidado de novo; um seed só é lido no primeiro boot.

**`REMOTE HOST IDENTIFICATION HAS CHANGED`.** O ssh diz isto, em maiúsculas, quando um nome que ele
conhece apresenta outra chave. Neste laboratório acontece toda vez que um convidado é apagado e um novo é
feito com o mesmo nome, o que é frequente. `ssh-keygen -R vm1` esquece a chave antiga, e o `newvm.sh` faz
isso por você.
