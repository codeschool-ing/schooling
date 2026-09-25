---
title: Quem está escutando, e em qual porta
version: 1
---

A aula 1 seção 05 usou o `ss -tln` para listar portas TCP escutando. Mais três letras o tornam muito
mais útil: `-u` acrescenta UDP, `-p` dá nome ao programa, e o `sudo` é necessário para ver programas
de outros usuários. No resolver de DNS do provedor:

```
ana@resolver:~$ sudo ss -tulpn
Netid State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                            
udp   UNCONN 0      0          127.0.0.1:53        0.0.0.0:*    users:(("unbound",pid=44351,fd=5))
udp   UNCONN 0      0      198.51.100.53:53        0.0.0.0:*    users:(("unbound",pid=44351,fd=3))
tcp   LISTEN 0      256    198.51.100.53:53        0.0.0.0:*    users:(("unbound",pid=44351,fd=4))
tcp   LISTEN 0      256        127.0.0.1:8953      0.0.0.0:*    users:(("unbound",pid=44351,fd=7))
tcp   LISTEN 0      256        127.0.0.1:53        0.0.0.0:*    users:(("unbound",pid=44351,fd=6))
ana@www:~$ sudo ss -tlpn
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                                                   
LISTEN 0      128       192.0.2.80:22        0.0.0.0:*    users:(("sshd",pid=44385,fd=3))                          
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=44364,fd=5),("nginx",pid=44363,fd=5))
LISTEN 0      511          0.0.0.0:443       0.0.0.0:*    users:(("nginx",pid=44364,fd=6),("nginx",pid=44363,fd=6))
ana@laptop:~$ grep -wE '^(ssh|domain|http|https|smtp|imaps)' /etc/services
ssh             22/tcp                          # SSH Remote Login Protocol
smtp            25/tcp          mail
domain          53/tcp                          # Domain Name Server
domain          53/udp
http            80/tcp          www             # WorldWideWeb HTTP
https           443/tcp                         # http protocol over TLS/SSL
https           443/udp                         # HTTP/3
domain-s        853/tcp                         # DNS over TLS [RFC7858]
domain-s        853/udp                         # DNS over DTLS [RFC8094]
imaps           993/tcp                         # IMAP over SSL
http-alt        8080/tcp        webcache        # WWW caching service
```

O resolver, `unbound`, tem cinco sockets. **A porta 53 aparece duas vezes para cada endereço, uma como
`udp` e outra como `tcp`**: as perguntas de DNS normalmente viajam por UDP, e recorrem ao TCP quando
uma resposta é grande demais para um pacote. Sockets UDP mostram `UNCONN` em vez de `LISTEN`, porque o
UDP não tem conexões para esperar; um socket UDP simplesmente recebe o que chega. A porta 8953 em
`127.0.0.1` é a porta de controle do unbound, que só a própria máquina alcança.

No servidor web, o `nginx` tem as portas 80 e 443 e o `sshd` tem a 22. O nginx aparece duas vezes em
cada linha: um processo mestre, que abriu os sockets, e um worker, que atende os pedidos.

Os números são convenções, e o `/etc/services` os lista. O `https` tem uma linha UDP também: **o
HTTP/3 roda sobre UDP**, e a seção 08 volta a isso. Um programa escutando numa porta que não é a de
costume sempre merece uma segunda olhada; é assim que se esconde um servidor de teste esquecido, ou
coisa pior.
