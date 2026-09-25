---
title: Mandando um arquivo por FTP
version: 1
---

O site da empresa fica no `www`, num provedor de hospedagem, e a conta dona dos arquivos dele é a
`example`. O provedor oferece FTP, o File Transfer Protocol, e é assim que o site é atualizado há anos.
A Ana tem uma página inicial nova para publicar:

```
ana@laptop:~$ ftp www.example.com
Trying 192.0.2.80:21 ...
Connected to www.example.com.
220 (vsFTPd 3.0.5)
Name (www.example.com:ana): example
331 Please specify the password.
Password: 
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> pwd
Remote directory: /
ftp> ls
229 Entering Extended Passive Mode (|||40007|)
150 Here comes the directory listing.
-rw-r--r--    1 1001     1001          173 Sep 25 18:25 index.html
226 Directory send OK.
ftp> put index.html
local: index.html remote: index.html
229 Entering Extended Passive Mode (|||40001|)
150 Ok to send data.
100% |***********************************|   109      686.74 KiB/s    00:00 ETA
226 Transfer complete.
109 bytes sent in 00:00 (246.40 KiB/s)
ftp> bye
221 Goodbye.
ana@laptop:~$ curl -s https://www.example.com/ | grep Closed
<p>Closed on 12 October for the holiday.</p>
```

Como o HTTP da aula 5, **o FTP é texto**: o cliente manda um comando e o servidor responde com um código de
três dígitos e uma frase. `220` é a saudação, `331` pede a senha, `230` a aceita, `226` diz que uma
transferência terminou. O primeiro dígito diz que tipo de resposta é: 2 feito, 3 continue, 4 e 5
falhou.

O `pwd` respondeu `/`, e essa `/` é a pasta do próprio site, não a raiz do servidor. O servidor tranca a
conta dentro dela, então `example` alcança os arquivos do site e nada mais na máquina. O `put` mandou o
`index.html` novo, e o `curl` mostra o site servindo-o na hora.
