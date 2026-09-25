---
title: scp: um arquivo por SSH
version: 1
---

Entre máquinas que rodam SSH, e isso é todo servidor Linux, não é preciso servidor FTP nenhum. O `scp`
copia arquivos por uma conexão SSH, com a mesma chave, o mesmo agente e o mesmo `~/.ssh/config` da aula
7:

```
ana@laptop:~$ ls -l licences.tar.gz
-rw-r--r-- 1 ana ana 67581 Sep 25 15:25 licences.tar.gz
ana@laptop:~$ scp licences.tar.gz office:
ana@laptop:~$ scp -r Documents office:
ana@laptop:~$ scp office:/etc/hostname from-server.txt && cat from-server.txt
server
ana@server:~$ ls -l licences.tar.gz Documents
-rw-r--r-- 1 ana ana 67581 Sep 25 15:26 licences.tar.gz

Documents:
total 80
-rw-r--r-- 1 ana ana 11358 Sep 25 15:26 Apache-2.0
-rw-r--r-- 1 ana ana  1499 Sep 25 15:26 BSD
-rw-r--r-- 1 ana ana 35149 Sep 25 15:26 GPL-3
-rw-r--r-- 1 ana ana  7652 Sep 25 15:26 LGPL-3
-rw-r--r-- 1 ana ana 16726 Sep 25 15:26 MPL-2.0
```

**Os dois-pontos é que tornam um caminho remoto.** `office:` é a pasta pessoal da ana no servidor,
`office:/etc/hostname` é um caminho completo lá, e um caminho sem dois-pontos é nesta máquina. O `-r`
copia uma pasta e tudo o que há nela. O lado que tem os dois-pontos é o que é lido ou gravado, então o
mesmo comando copia nos dois sentidos.

O scp não imprimiu nada, porque nada deu errado. A cópia no servidor tem o mesmo tamanho, `67581`
bytes. Tudo viajou dentro do SSH, na porta 22: uma conexão, cifrada, sem faixa passiva e sem nada para o
NAT errar. Desde o OpenSSH 9.0, o scp usa por baixo o protocolo SFTP da seção 09, e só o comando ficou
igual.
