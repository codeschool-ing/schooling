---
title: Um kernel, muitas distribuições
version: 1
---

**Todo container de uma máquina roda no kernel do host, seja qual for a distribuição que dá nome à
imagem dele.** Uma imagem chamada `debian` não traz o kernel do Debian. Ela traz os arquivos do
Debian: o shell, as bibliotecas, o gerenciador de pacotes, o `/etc`. O kernel embaixo é o que já
estava rodando.

O `uname -r` imprime a versão do kernel em execução. A Ana pergunta ao host, depois a um container
Alpine, depois a um Debian:

```
ana@vm:~$ uname -r
6.18.44-fc-v70
ana@vm:~$ docker run --rm alpine:3.22 uname -r
6.18.44-fc-v70
ana@vm:~$ docker run --rm debian:trixie-slim uname -r
6.18.44-fc-v70
```

Três vezes a mesma resposta, `6.18.44-fc-v70`, que é a compilação de kernel da própria máquina do
laboratório. Agora os três são perguntados sobre qual distribuição são, o que fica escrito no
arquivo `/etc/os-release`:

```
ana@vm:~$ grep PRETTY_NAME /etc/os-release
PRETTY_NAME="Ubuntu 24.04.5 LTS"
ana@vm:~$ docker run --rm alpine:3.22 grep PRETTY_NAME /etc/os-release
PRETTY_NAME="Alpine Linux v3.22"
ana@vm:~$ docker run --rm debian:trixie-slim grep PRETTY_NAME /etc/os-release
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
```

**Três distribuições diferentes num kernel só.** O host é Ubuntu 24.04; um container enxerga um
sistema de arquivos Alpine, o outro um Debian 13. É isso que "uma imagem Debian" quer dizer: o
espaço de usuário do Debian, rodando no kernel Linux que o host tiver. Funciona porque o kernel
Linux mantém estável a interface que oferece aos programas de uma versão para outra, então um `ls`
do Debian 13 roda num kernel que o Debian 13 nunca distribuiu.

## Quanto custa iniciar

O `time` informa quanto tempo um comando levou. Aqui ele mede um container completo: criado a
partir da imagem, iniciado, rodando `true` (um programa que termina na hora, com sucesso) e
removido:

```
ana@vm:~$ time docker run --rm alpine:3.22 true

real	0m0.328s
user	0m0.023s
sys	0m0.014s
```

**Cerca de um terço de segundo, do nada até terminado e limpo.** A linha `real` é o tempo de
relógio; quase tudo é trabalho do próprio Docker para montar o container, porque o `true` em si não
leva tempo mensurável. Não há sistema operacional para dar boot, então não há boot para esperar. O
número é desta máquina e desta execução, e o seu vai ser outro.

## Quanto custa um container parado

Um container que roda `sleep` não faz absolutamente nada por dez minutos. O `docker stats` mostra o
que ele usa enquanto isso; o `--no-stream` pede uma leitura só, em vez de uma tela ao vivo:

```
ana@vm:~$ docker run -d --name idle alpine:3.22 sleep 600
e49019bd143ec6cdeae6b87c0423c182b43ba89b78527d92a30b4f2428d55f92
ana@vm:~$ docker stats --no-stream idle
CONTAINER ID   NAME      CPU %     MEM USAGE / LIMIT   MEM %     NET I/O    BLOCK I/O   PIDS
e49019bd143e   idle      0.00%     668KiB / 15.72GiB   0.00%     0B / 84B   0B / 0B     1
```

**668KiB de memória e nada de CPU**, que é o que custa o único processo `sleep`, porque é tudo o
que há. Uma máquina virtual parada manteria na memória o kernel e o sistema operacional inteiros
sem fazer nada; essa comparação é a que o laboratório não consegue fazer, como disse a etapa
anterior. O `LIMIT` de 15.72GiB também não é uma reserva: sem limite definido, ele é simplesmente
toda a memória que o host tem, e o container poderia usar qualquer parte dela. A aula 17 define um.
