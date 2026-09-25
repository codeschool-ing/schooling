---
title: Quando a chave do servidor muda
version: 1
---

O servidor do escritório foi reinstalado, e uma reinstalação cria uma chave de host nova. A conexão
seguinte:

```
ana@laptop:~$ ssh -o BatchMode=yes office true
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ED25519 key sent by the remote host is
SHA256:q2DsZDFL+zKzCidnXG2dZNjvraaltILaeMZyqrkLhKU.
Please contact your system administrator.
Add correct host key in /home/ana/.ssh/known_hosts to get rid of this message.
Offending ED25519 key in /home/ana/.ssh/known_hosts:1
  remove with:
  ssh-keygen -f '/home/ana/.ssh/known_hosts' -R '192.168.10.10'
Host key for 192.168.10.10 has changed and you have requested strict checking.
Host key verification failed.
ana@server:~$ ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
256 SHA256:q2DsZDFL+zKzCidnXG2dZNjvraaltILaeMZyqrkLhKU root@server (ED25519)
ana@laptop:~$ ssh-keygen -R 192.168.10.10
# Host 192.168.10.10 found: line 1
/home/ana/.ssh/known_hosts updated.
Original contents retained as /home/ana/.ssh/known_hosts.old
ana@laptop:~$ eval $(ssh-agent) >/dev/null
ana@laptop:~$ ssh-add
Enter passphrase for /home/ana/.ssh/id_ed25519: 
Identity added: /home/ana/.ssh/id_ed25519 (ana@laptop)
ana@laptop:~$ ssh office hostname
The authenticity of host '192.168.10.10 (192.168.10.10)' can't be established.
ED25519 key fingerprint is SHA256:q2DsZDFL+zKzCidnXG2dZNjvraaltILaeMZyqrkLhKU.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.10.10' (ED25519) to the list of known hosts.
server
```

O ssh recusa de vez. **A chave que ele recebeu, `SHA256:q2DsZD…`, não é a que está no
`known_hosts`**, e de onde o ssh está um servidor reinstalado e alguém no meio fingindo ser ele parecem
exatamente iguais. O aviso diz as duas coisas, e não há `yes` para digitar.

Qual das duas é, precisa ser descoberto em outro lugar. A impressão digital no servidor, lida no console
ou por quem o reinstalou, é `SHA256:q2DsZD…`, a que o ssh recebeu. Só então o `ssh-keygen -R` apaga a
linha velha (e guarda o arquivo como estava em `known_hosts.old`), e a conexão seguinte volta a ser uma
primeira conexão, perguntando pela chave nova.

**Nunca faça este aviso sumir sem saber por que ele apareceu.** Um servidor que não foi reinstalado,
nem refeito, nem mudou de endereço não deveria ter chave nova, e um aviso que ninguém sabe explicar é
para relatar, e não para contornar.
