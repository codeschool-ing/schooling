---
title: Uma conta que só pode deixar arquivos
version: 1
---

O scanner do escritório salva as digitalizações no servidor por SFTP, coisa que muitos scanners e
copiadoras sabem fazer. A conta dele, `scans`, precisa pôr arquivos numa pasta e mais nada: nenhum
shell, e nenhuma visão do resto do servidor. Quatro linhas no fim do `sshd_config` do servidor fazem
isso:

```
ana@server:~$ tail -4 /etc/ssh/sshd_config
Match User scans
    ForceCommand internal-sftp
    ChrootDirectory /srv/scans
    AllowTcpForwarding no
ana@server:~$ ls -ld /srv/scans /srv/scans/inbox
drwxr-xr-x 3 root  root  4096 Sep 25 15:20 /srv/scans
drwxr-xr-x 2 scans scans 4096 Sep 25 15:24 /srv/scans/inbox
ana@laptop:~$ ssh scans@192.168.10.10
scans@192.168.10.10's password: 
Connection from user scans 192.168.10.20 port 47716: refusing non-sftp session
This service allows sftp connections only.
Connection to 192.168.10.10 closed.
ana@laptop:~$ sftp scans@192.168.10.10
scans@192.168.10.10's password: 
Connected to 192.168.10.10.
sftp> pwd
Remote working directory: /
sftp> ls
inbox
sftp> cd /etc
stat remote: No such file or directory
sftp> cd inbox
sftp> put scan-0001.pdf
Uploading scan-0001.pdf to /inbox/scan-0001.pdf
scan-0001.pdf                                 100%   16KB  22.0MB/s   00:00    
sftp> bye
ana@server:~$ ls -l /srv/scans/inbox
total 20
-rw-r--r-- 1 scans scans 16726 Sep 25 15:27 scan-0001.pdf
```

`Match User scans` aplica o que vem depois só a essa conta. `ForceCommand internal-sftp` dá SFTP à
conta, peça o cliente o que pedir, e por isso o `ssh` foi mandado embora com `This service allows sftp
connections only`. `ChrootDirectory /srv/scans` faz dessa pasta a `/` da conta: o `pwd` disse `/`, o
`ls` mostrou só `inbox`, e `/etc` não existe de onde ela está.

**A pasta do chroot precisa ser do root e não pode ser gravável por mais ninguém**, senão o sshd recusa
o login. É por isso que `/srv/scans` é `root root drwxr-xr-x` e o lugar gravável é o `inbox` dentro
dela. A digitalização chegou como sendo de `scans`, onde as pessoas que as arquivam podem pegá-la.
