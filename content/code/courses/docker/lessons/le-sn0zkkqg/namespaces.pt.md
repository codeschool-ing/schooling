---
title: Namespaces, as paredes que limitam a visão
version: 1
---

**Um namespace dá a um processo a própria cópia de um tipo de coisa que o kernel mantém, de modo que
ele enxerga essa cópia e não a do host.** Há um tipo para números de processo, um para interfaces de
rede, um para o nome de máquina, um para montagens, e mais alguns. Um container é um processo
colocado num conjunto de namespaces novos no momento em que inicia. Nada é escondido pelo Docker
depois; o kernel simplesmente responde a cada pergunta a partir do namespace onde o processo está.

A Ana inicia um container e pede o número do processo principal dele no host. O `--hostname` lhe dá
um nome próprio, o que vai ser útil daqui a pouco:

```
ana@vm:~$ docker run -d --name web --hostname web alpine:3.22 sleep 600
918c0d43edc431356c583e79dfb9cdeff3c0840743d1ab092f4964fa54e439ba
ana@vm:~$ PID=$(docker inspect -f "{{.State.Pid}}" web); echo $PID
20052
```

## Todo processo carrega uma lista de namespaces

Em `/proc/<pid>/ns/`, o kernel lista os namespaces a que um processo pertence, um link por tipo,
cada um apontando para um namespace por número. A Ana lê quatro deles para o processo do container,
e os mesmos quatro para o próprio shell, `$$`:

```
ana@vm:~$ sudo readlink /proc/$PID/ns/pid /proc/$PID/ns/net /proc/$PID/ns/uts /proc/$PID/ns/mnt
pid:[4026532265]
net:[4026532266]
uts:[4026532263]
mnt:[4026532262]
ana@vm:~$ readlink /proc/$$/ns/pid /proc/$$/ns/net /proc/$$/ns/uts /proc/$$/ns/mnt
pid:[4026531836]
net:[4026531833]
uts:[4026531838]
mnt:[4026531832]
```

**Quatro números diferentes para cada tipo.** Dois processos no mesmo namespace mostram o mesmo
número, então o container e o shell da Ana não compartilham nenhum desses quatro. Ler o processo de
outro usuário exige `sudo`; o `sleep` do container roda como root.

O `lsns` lista todos os namespaces de um processo, com o tipo e quantos processos há em cada um:

```
ana@vm:~$ sudo lsns -p $PID
        NS TYPE   NPROCS   PID USER COMMAND
4026531835 cgroup     89     2 root kthreadd
4026531837 user       89     2 root kthreadd
4026532262 mnt         1 20052 root sleep 600
4026532263 uts         1 20052 root sleep 600
4026532264 ipc         1 20052 root sleep 600
4026532265 pid         1 20052 root sleep 600
4026532266 net         1 20052 root sleep 600
4026532317 time        1 20052 root sleep 600
```

Seis namespaces foram criados para este container, cada um com exatamente um processo, `sleep 600`:
mount, UTS (o nome de máquina), IPC, PID, network e time. **Dois não foram**: as linhas `cgroup` e
`user` são compartilhadas com 89 processos do host, a começar por `kthreadd`, o do próprio kernel. O
namespace de usuários é o que mais importa dos dois: o Docker não dá um aos containers por padrão,
então **o root dentro deste container é o mesmo root do host**, contido só pelas outras paredes. O
bundle do runc da aula 3 tinha um, e a aula 21 volta ao que isso muda.

## Como cada parede aparece de dentro

O nome de máquina é o mais simples. A máquina da Ana é `vm`; o container responde com o nome que
recebeu:

```
ana@vm:~$ hostname
vm
ana@vm:~$ docker exec web hostname
web
```

A rede é a mais visível. Cada interface de rede aparece em `/sys/class/net`:

```
ana@vm:~$ docker exec web ls /sys/class/net
eth0
lo
ana@vm:~$ ls /sys/class/net
docker0
eth0
ifb0
ifb1
lo
vethb30f68a
```

Dentro, duas interfaces: `lo` e um `eth0` próprio. Fora, a lista do host, incluindo o `docker0`, a
bridge que o Docker criou, e uma interface `veth`, que é a ponta do host do cabo virtual cuja outra
ponta é o `eth0` do container. A aula 23 segue esse cabo.

## Atravessando a parede

O `nsenter` roda um programa dentro dos namespaces de outro processo, escolhidos tipo a tipo. É isso,
por baixo, o que o `docker exec` faz. A Ana entra só nos namespaces de UTS e de rede do container e
roda o `ip` do próprio host, um programa que a imagem do container nem tem nessa forma:

```
ana@vm:~$ sudo nsenter --target $PID --uts --net sh -c "hostname; ip -brief addr"
web
lo               UNKNOWN        127.0.0.1/8 
eth0@if97        UP             172.17.0.2/16 
```

Um programa do host enxergando o nome de máquina do container e a rede do container: o próprio
loopback e um `eth0` com o endereço `172.17.0.2`. Todo o resto, os arquivos, a lista de processos,
continuou sendo do host, porque esses namespaces não foram atravessados. **Um namespace é uma
propriedade de um processo, e um processo pode ser posto em qualquer combinação deles.**

A aula 1 desenhou o namespace de PID como uma parede em volta de um processo. O mesmo desenho vale
para cada tipo, com uma parede por tipo, e um container é o caso em que todas são levantadas de uma
vez.
