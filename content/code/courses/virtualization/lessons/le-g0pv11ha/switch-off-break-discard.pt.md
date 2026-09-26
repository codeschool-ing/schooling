---
title: Desligar, quebrar, jogar fora
version: 1
---

Um convidado é desligado e ligado a partir do host, como se alguém apertasse o botão de ligar dele:

```
ana@host:~$ virsh shutdown vm1
Domain 'vm1' is being shutdown

ana@host:~$ virsh list --all
 Id   Name   State
-----------------------
 -    vm1    shut off

ana@host:~$ virsh start vm1
Domain 'vm1' started

ana@vm1:~$ uptime -p
up 1 minute
```

O `virsh shutdown` não para o processo. Ele **pede ao convidado que desligue**, o mesmo sinal que um
computador de verdade recebe de um toque curto no botão de ligar, e o Ubuntu lá dentro fecha os
serviços e se desliga sozinho. Trinta segundos depois o convidado está `shut off`: nenhum processo,
nenhuma memória em uso, e um arquivo no disco. O `virsh start` dá boot de novo a partir desse arquivo,
e o `uptime` lá dentro diz que está `up 1 minute`. Tudo o que havia no disco dele continua lá.

Agora a coisa que não dá para fazer num computador com que você se importa. Dentro do convidado, a ana
apaga tudo, da raiz para baixo:

```
ana@vm1:~$ sudo rm -rf --no-preserve-root / 2>/dev/null; ls /
bash: line 1: ls: command not found
ana@host:~$ virsh destroy vm1 && virsh undefine vm1 && sudo rm /var/lib/libvirt/images/vm1.qcow2
Domain 'vm1' destroyed

Domain 'vm1' has been undefined

ana@host:~$ virsh list --all
 Id   Name   State
--------------------
```

O `ls` sumiu, e todo o resto também; o convidado continua ligado, sem nada para rodar. Num computador
de verdade isso é uma reinstalação e uma tarde perdida. Aqui é uma linha no host. O `virsh
destroy` é o oposto do `shutdown`: ele **puxa o fio da tomada**, o que serve para uma máquina que vai
ser apagada e é um mau hábito para uma que não vai. O `virsh undefine` apaga a descrição que o libvirt
tinha dela, e o `rm` apaga o arquivo. A lista está vazia.

O disco base nunca foi tocado, porque toda escrita foi para o `vm1.qcow2`. O próximo convidado deste
curso sai da mesma base em um minuto, como se nada tivesse acontecido.
