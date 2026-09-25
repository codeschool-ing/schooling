---
title: Onde o programa para e o kernel começa
version: 1
---

Um programa nunca monta um pacote. Ele pede ao kernel um **socket**, uma ponta de onde pode ler e
onde pode escrever, e diz a ele para onde conectar. O `strace` imprime cada pedido que um programa faz
ao kernel, e, filtrado para essas duas chamadas, o `curl` buscando uma página fica assim:

```
ana@laptop:~$ strace -f -e trace=socket,connect curl -s -o /dev/null http://www.example.com/
socket(AF_UNIX, SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK, 0) = 3
connect(3, {sa_family=AF_UNIX, sun_path="/var/run/nscd/socket"}, 110) = -1 ENOENT (No such file or directory)
socket(AF_UNIX, SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK, 0) = 3
connect(3, {sa_family=AF_UNIX, sun_path="/var/run/nscd/socket"}, 110) = -1 ENOENT (No such file or directory)
socket(AF_INET6, SOCK_DGRAM, IPPROTO_IP) = -1 EAFNOSUPPORT (Address family not supported by protocol)
strace: Process 25328 attached
[pid 25328] socket(AF_UNIX, SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK, 0) = 7
[pid 25328] connect(7, {sa_family=AF_UNIX, sun_path="/var/run/nscd/socket"}, 110) = -1 ENOENT (No such file or directory)
[pid 25328] socket(AF_UNIX, SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK, 0) = 7
[pid 25328] connect(7, {sa_family=AF_UNIX, sun_path="/var/run/nscd/socket"}, 110) = -1 ENOENT (No such file or directory)
[pid 25328] socket(AF_INET, SOCK_DGRAM|SOCK_CLOEXEC|SOCK_NONBLOCK, IPPROTO_IP) = 7
[pid 25328] connect(7, {sa_family=AF_INET, sin_port=htons(53), sin_addr=inet_addr("198.51.100.53")}, 16) = 0
[pid 25328] +++ exited with 0 +++
socket(AF_INET, SOCK_STREAM, IPPROTO_TCP) = 5
connect(5, {sa_family=AF_INET, sin_port=htons(80), sin_addr=inet_addr("192.0.2.80")}, 16) = -1 EINPROGRESS (Operation now in progress)
+++ exited with 0 +++
```

Leia em ordem:

1. Dois sockets `AF_UNIX` tentam `/var/run/nscd/socket`, um cache local de consultas de nomes, e
   recebem `ENOENT`: esta máquina não roda um, e a consulta segue sem ele.
2. O `socket(AF_INET6, …)` falha com `EAFNOSUPPORT`. **A máquina do laboratório não tem IPv6
   nenhum**, e é aqui que um programa descobre.
3. **`SOCK_DGRAM` é UDP, e vai para a porta 53 de `198.51.100.53`**: a pergunta de DNS, assunto da aula
   4, feita numa thread só dela (`pid 25328`).
4. **`SOCK_STREAM` é TCP, e vai para a porta 80 de `192.0.2.80`**: o servidor web, no endereço que a
   resposta do DNS deu. `EINPROGRESS` quer dizer que o kernel começou o handshake e vai avisar o
   `curl` quando terminar.

Tudo o que as próximas seções olham aconteceu abaixo dessa última linha, dentro do kernel, sem o
`curl` saber. O programa deu o endereço e a porta de destino. **O kernel escolheu a porta de origem**,
de uma faixa que ele reserva para isso:

```
ana@laptop:~$ cat /proc/sys/net/ipv4/ip_local_port_range
32768   60999
```

Uma conexão é esses quatro números: endereço e porta de origem, endereço e porta de destino. É assim
que um laptop mantém duzentas conexões com o mesmo servidor web ao mesmo tempo: cada uma tem a sua
porta de origem.
