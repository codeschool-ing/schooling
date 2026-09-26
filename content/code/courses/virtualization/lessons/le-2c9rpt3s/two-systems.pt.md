---
title: Dois sistemas, não um
version: 1
---

Com a vm1 ligada, há dois sistemas operacionais no computador, e eles são mais separados do que
parecem:

```
ana@host:~$ uname -r; hostname
6.18.44-fc-v37
host
ana@vm1:~$ uname -r; hostname
6.8.0-139-generic
vm1
ana@host:~$ echo "written on host" > ~/note.txt; ls ~
note.txt
ana@vm1:~$ ls -A ~; ls ~/note.txt
.bash_logout
.bashrc
.cache
.profile
.ssh
ls: cannot access '/home/ana/note.txt': No such file or directory
```

**Cada um tem o próprio kernel.** O host roda o `6.18.44-fc-v37` e a vm1 roda o `6.8.0-139-generic`, o do
próprio Ubuntu, que veio com o disco base. Nem são a mesma versão, e não precisam ser. Um convidado
poderia ser Windows no mesmo host, e o kernel do host nunca saberia.

**Cada um tem os próprios arquivos e os próprios usuários.** A ana escreveu `note.txt` na pasta
pessoal dela no host, e a ana da vm1 não tem esse arquivo: é outra conta, em outro `/etc/passwd`, em
outro disco, que por acaso tem o mesmo nome porque o laboratório fez assim.

O que vem a seguir é a parte que pega as pessoas de surpresa:

| no host | dentro de um convidado |
|---|---|
| as próprias atualizações | as próprias atualizações, que as do host não instalam |
| os próprios usuários e senhas | os próprios, e uma senha do host vazada não o abre |
| o próprio firewall | o próprio firewall, e o tráfego entre eles passa pelos dois |
| o próprio antivírus, se houver | nenhum, a não ser que o convidado tenha o dele |

**Um convidado é um computador para manter.** Dez convidados num laptop são dez sistemas que precisam
de atualização, e o convidado que ninguém liga há um ano está um ano atrasado nas correções de
segurança no dia em que for ligado de novo.
