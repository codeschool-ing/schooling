---
title: O que o host vê
version: 1
---

Um servidor web num contêiner, e a mesma pergunta feita a ele e à vm1 pelo lado do host:

```
ana@host:~$ sudo podman run -d --name web -p 8080:80 docker.io/library/nginx:alpine
bc637711447c880b4e4c4b7bd2bcaebb7e5c98ea73faed40b1cb6298b5075321
ana@host:~$ curl -s localhost:8080 | grep "<title>"
<title>Welcome to nginx!</title>
ana@host:~$ ps -o pid,user,rss,comm -C nginx
    PID USER       RSS COMMAND
  44733 root      6240 nginx
  44751 sshd      3368 nginx
  44752 sshd      3040 nginx
  44753 sshd      3040 nginx
  44754 sshd      3024 nginx
ana@host:~$ ps -o pid,user,rss,comm -C qemu-system-x86_64
    PID USER       RSS COMMAND
  44562 libvirt+ 1518104 qemu-system-x86
ana@host:~$ sudo podman images
REPOSITORY                TAG         IMAGE ID      CREATED      SIZE
docker.io/library/nginx   alpine      3dd08163706a  3 days ago   64.3 MB
docker.io/library/ubuntu  24.04       6232b3879100  2 weeks ago  80.7 MB
```

O `podman run -d` ligou o nginx num contêiner e o `-p 8080:80` mandou a porta 8080 do host para ele, o
redirecionamento de portas da aula 11. A parte interessante é o `ps`. O host vê **os processos do
contêiner um por um**, como seus: um mestre e quatro trabalhadores, um por processador do host, usando
18712 KiB entre eles. Da vm1 ele vê **um processo** de 1518104 KiB, e nada do que roda lá dentro.

E olhe a coluna `USER`. Os trabalhadores do nginx rodam dentro do contêiner como o usuário número 101, e no
host o número 101 por acaso se chama **`sshd`**. Os usuários do contêiner são os usuários do host, pelo
número; nada os traduziu. É a finura da parede de um contêiner vista de fora, e é por isso que contêineres
que rodam como `root` lá dentro são tratados com cuidado: sem outras configurações, esse é o `root` do
host numa visão restrita.
