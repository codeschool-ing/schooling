---
title: ss: o que escuta, e quem está conectado
version: 1
---

Na outra ponta de toda conexão há um programa escutando numa porta. O `ss` lista esses programas, e as
conexões já feitas:

```
ana@www:~$ sudo ss -tlnp
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                                                     
LISTEN 0      32        192.0.2.80:21        0.0.0.0:*    users:(("vsftpd",pid=110849,fd=3))                         
LISTEN 0      128       192.0.2.80:22        0.0.0.0:*    users:(("sshd",pid=110831,fd=4))                           
LISTEN 0      511          0.0.0.0:443       0.0.0.0:*    users:(("nginx",pid=110812,fd=6),("nginx",pid=110811,fd=6))
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=110812,fd=5),("nginx",pid=110811,fd=5))
ana@laptop:~$ ss -tnp
State Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
ESTAB 0      0      192.168.10.20:48548   192.0.2.80:80   users:(("nc",pid=111540,fd=3))
ana@laptop:~$ netstat -tn
bash: line 1: netstat: command not found
```

No `www`, `-tlnp` quer dizer TCP, escutando, números em vez de nomes, e o processo. O nginx escuta nas
portas 80 e 443 em todo endereço, `0.0.0.0`; o sshd e o vsftpd escutam só em `192.0.2.80`. No laptop, o
`-tnp` sem o `-l` mostra as conexões estabelecidas: um `ESTAB` de uma porta local para `192.0.2.80:80`,
do `nc`. A aula 3 leu a mesma tabela para os estados de uma conexão.

**O `netstat` é a ferramenta mais antiga para o mesmo serviço**, e neste Ubuntu ele nem está instalado:
faz parte do pacote `net-tools`, que as distribuições modernas deixam de fora. Ainda é o que o Windows e
o macOS têm, e o `netstat -tlnp` num Linux que o tenha imprime quase a mesma tabela. No Linux, o `ss` é o
que vale aprender.
