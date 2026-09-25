---
title: sftp: uma sessão, por SSH
version: 1
---

Para navegar e mover vários arquivos, o `sftp` abre uma sessão com comandos bem parecidos com os do
FTP. O protocolo por baixo não tem nada a ver com o FTP: **é um subsistema do SSH**.

```
ana@laptop:~$ sftp office
Connected to office.
sftp> pwd
Remote working directory: /home/ana
sftp> ls
Documents
licences.tar.gz
sftp> cd Documents
sftp> ls -l
-rw-r--r--    ? ana      ana         11358 Sep 25 15:26 Apache-2.0
-rw-r--r--    ? ana      ana          1499 Sep 25 15:26 BSD
-rw-r--r--    ? ana      ana         35149 Sep 25 15:26 GPL-3
-rw-r--r--    ? ana      ana          7652 Sep 25 15:26 LGPL-3
-rw-r--r--    ? ana      ana         16726 Sep 25 15:26 MPL-2.0
sftp> get MPL-2.0
Fetching /home/ana/Documents/MPL-2.0 to MPL-2.0
MPL-2.0                                       100%   16KB  20.0MB/s   00:00    
sftp> put index.html
Uploading index.html to /home/ana/Documents/index.html
index.html                                    100%  109   273.5KB/s   00:00    
sftp> bye
ana@laptop:~$ ls -l MPL-2.0
-rw-r--r-- 1 ana ana 16726 Sep 25 15:26 MPL-2.0
ana@server:~$ ls -l Documents/index.html
-rw-r--r-- 1 ana ana 109 Sep 25 15:26 Documents/index.html
ana@laptop:~$ printf "cd Documents\nls\n" | sftp -b - office
sftp> cd Documents
sftp> ls
Apache-2.0   BSD          GPL-3        LGPL-3       MPL-2.0      index.html   
```

`cd`, `ls` e `pwd` agem no servidor; os mesmos comandos com um `l` na frente, `lcd`, `lls` e `lpwd`,
agem no laptop. `get` baixa e `put` sobe, cada um com uma linha de progresso. O `?` na listagem é um
detalhe do protocolo: ele não leva o número de links que o `ls -l` normalmente mostra.

O `-b -` lê os comandos da entrada em vez de um teclado, e é assim que o sftp entra num script. Os
clientes gráficos que a maioria usa, como o FileZilla e o WinSCP, falam o mesmo SFTP, e neles isto é uma
janela com dois painéis.
