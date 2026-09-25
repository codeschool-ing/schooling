---
title: A primeira conexão
version: 1
---

A Ana está no laptop do escritório e quer um shell no servidor do escritório. O `ssh` recebe um
endereço, ou um nome, e entra com o mesmo usuário se ninguém disser outro:

```
ana@laptop:~$ ssh 192.168.10.10
The authenticity of host '192.168.10.10 (192.168.10.10)' can't be established.
ED25519 key fingerprint is SHA256:lnt8eQvQ3cgVbp6gskjE+zbhlBcPdROpmRKsk6xZHN8.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.10.10' (ED25519) to the list of known hosts.
ana@192.168.10.10's password: 
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

ana@server:~$ hostname
server
ana@server:~$ exit
logout
Connection to 192.168.10.10 closed.
```

Antes de pedir a senha, o ssh parou. **Ele nunca tinha visto este servidor, e não tinha como
distingui-lo de um impostor.** Todo servidor SSH tem uma **chave de host**, um par de chaves criado na
instalação, e se prova com ela a cada conexão. O ssh imprimiu a impressão digital dessa chave,
`SHA256:lnt8eQ…`, e perguntou se devia confiar nela. Digitar `yes` guardou a chave em
`~/.ssh/known_hosts`; dali em diante, o ssh confere a chave com esse arquivo, a cada conexão, sem
perguntar.

A impressão digital só vale a conferência se houver com o que comparar. No servidor, ou com quem o
montou:

```
ana@server:~$ ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
256 SHA256:lnt8eQvQ3cgVbp6gskjE+zbhlBcPdROpmRKsk6xZHN8 root@server (ED25519)
ana@laptop:~$ cat ~/.ssh/known_hosts | cut -c1-60
|1|Z4o3ko8n8gxDudnQpco+eMRBD7A=|Qi+oN+fkW6rG6mcqFTeRHaOXGBQ=
```

O mesmo `SHA256:lnt8eQ…`. Uma diferente, numa primeira conexão, quereria dizer que a Ana não estava
falando com o servidor. A linha do `known_hosts` é ilegível, começando com `|1|`, porque o Ubuntu guarda
o nome do servidor como hash, e assim um arquivo roubado não lista as máquinas em que a Ana entra. O
`ssh-keygen -F 192.168.10.10` ainda acha a entrada.

A senha foi para o servidor dentro da conexão cifrada, nunca às claras, e nada apareceu na tela
enquanto ela digitava. Depois do `exit`, a sessão acabou e o prompt voltou a ser o do laptop.
