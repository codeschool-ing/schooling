---
title: O que foi transferido
version: 1
---

Dois passos levam a captura de "uma conversa aconteceu" para "este é o arquivo". O primeiro remonta a conversa em
ordem, como os dois programas a viram (Wireshark: *Follow, TCP Stream*). Os fluxos são numerados a partir de 0:

```
ana@soc:~$ tshark -r web.pcap -q -z follow,tcp,ascii,0 | head -22

===================================================================
Follow: tcp,ascii
Filter: tcp.stream eq 0
Node 0: 192.168.20.10:50542
Node 1: 203.0.113.200:8080
95
GET /price-list.csv HTTP/1.1
Host: 203.0.113.200:8080
User-Agent: curl/8.5.0
Accept: */*


	188
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.13.16
Date: Thu, 08 Oct 2026 00:10:25 GMT
Content-type: text/csv
Content-Length: 49524
Last-Modified: Thu, 08 Oct 2026 00:10:21 GMT
```

O nó 0 é o `files`, o nó 1 o servidor. O número antes de cada bloco é quantos bytes aquele lado mandou: 95 bytes de
requisição, o `GET` com os cabeçalhos do curl, e então a resposta do servidor, começando pelos cabeçalhos. O corpo
da resposta, os 49.524 bytes da lista, vem em seguida; o `head` o cortou aqui.

O segundo passo reconstrói o próprio arquivo a partir dos pacotes (Wireshark: *File, Export Objects, HTTP*):

```
ana@soc:~$ tshark -r web.pcap -q --export-objects http,objects
ana@soc:~$ ls -l objects
total 52
-rw-r--r-- 1 ana ana 49524 Oct  7 21:10 price-list.csv
root@soc:~# sha256sum www/price-list.csv /home/ana/objects/price-list.csv
355da1417a322b56fa40dcfc8368a2cabdcb77452dc65630641fad01b457d4b1  www/price-list.csv
355da1417a322b56fa40dcfc8368a2cabdcb77452dc65630641fad01b457d4b1  /home/ana/objects/price-list.csv
```

`--export-objects http,objects` escreve todo arquivo transferido por HTTP na pasta `objects`. Um arquivo, 49.524
bytes. E o hash, tirado como root porque o original está na pasta do root, resolve: **o arquivo reconstruído a
partir dos pacotes é, byte a byte, o arquivo do servidor.** É um achado do tipo mais forte, com a mesma forma da
imagem da aula 16: qualquer pessoa com a captura consegue reconstruir o arquivo e conferir o hash.

Na noite de quinta, uma captura no `fw` teria respondido diretamente a pergunta em aberto da aula 12, arquivo por
arquivo, se a transferência fosse HTTP simples. Se era, é o problema da próxima seção.
