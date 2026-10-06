---
title: Quatro conferências depois de instalar
version: 1
---

**Quatro comandos dizem se uma instalação funciona, e eles fazem as mesmas perguntas no Docker
Desktop e no Docker Engine.** As transcrições abaixo são do laboratório do curso, um servidor Linux
rodando o Engine. Onde o Desktop responde diferente, o texto diz como, e não mostra nenhuma saída que
não tenha sido gravada aqui.

## 1. As duas metades respondem

```
ana@vm:~$ docker version
Client: Docker Engine - Community
 Version:           29.8.2
 API version:       1.56
 Go version:        go1.26.8
 Git commit:        7fc2dff
 Built:             Wed Sep 30 19:32:28 2026
 OS/Arch:           linux/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          29.8.2
  API version:      1.56 (minimum version 1.40)
  Go version:       go1.26.8
  Git commit:       8af9fe3
  Built:            Wed Sep 30 19:32:28 2026
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          v2.3.6
  GitCommit:        ee2735368117d2eb259779949d5e75cdafec9761
 runc:
  Version:          1.5.1
  GitCommit:        v1.5.1-0-g8f2685a4
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
```

**O `docker version` responde em dois blocos, e os dois precisam estar lá.** `Client` é o próprio
comando `docker`; `Server` é o motor com que ele falou, com as versões do containerd e do runc
embaixo, que a aula 6 explica. Se só o bloco do cliente aparece, seguido de um erro, o comando está
instalado e o motor não está acessível; a conferência 4 abaixo mostra esse erro.

No Docker Desktop, o bloco do servidor dá o nome do Docker Desktop, e as duas linhas `OS/Arch`
discordam: o cliente é `windows/amd64` ou `darwin/arm64`, porque roda no seu sistema, e o servidor é
`linux/…`, porque roda na VM. Essa discordância é o desenho da etapa anterior, impresso.

## 2. Um container roda

```
ana@vm:~$ docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
4f55086f7dd0: Pulling fs layer
4f55086f7dd0: Download complete
4f55086f7dd0: Pull complete
d5e71e642bf5: Download complete
Digest: sha256:5e23090353324d887c48ad5e5c56d294eab81588df9605b07d1afe895f9cc8f8
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

**O `hello-world` é o menor teste de ponta a ponta que existe.** Tudo até o `Status:` é o pull: a
imagem não estava na máquina, então o motor a buscou, uma camada só, e a nomeou pelo digest. Depois
o container rodou um programa que imprime o texto de baixo, e o texto descreve a viagem que acabou de
fazer: do cliente ao daemon, do daemon ao Docker Hub, da imagem ao container, da saída de volta ao
cliente. Se isso funciona, o motor, a rede até o registry e o runtime funcionam.

## 3. Com que motor você está falando

```
ana@vm:~$ docker context ls
NAME        DESCRIPTION                               DOCKER ENDPOINT               ERROR
default *   Current DOCKER_HOST based configuration   unix:///var/run/docker.sock   
```

Um **contexto** é um motor com nome com o qual o comando `docker` pode falar; o `*` marca o atual. No
laboratório só existe o `default`, o motor no socket desta própria máquina. O Docker Desktop
acrescenta um chamado `desktop-linux` e o torna o atual, e é por isso que o mesmo comando chega à VM.
Quando uma máquina tem mais de um motor, o `docker context use <nome>` alterna entre eles, e o
`docker context ls` é a primeira coisa a rodar quando os containers parecem ter sumido: em geral eles
estão no outro motor.

## 4. O que o motor tem

```
ana@vm:~$ docker info --format "{{.OperatingSystem}} | {{.OSType}}/{{.Architecture}} | {{.NCPU}} CPUs | {{.MemTotal}} bytes"
Ubuntu 24.04.5 LTS | linux/x86_64 | 4 CPUs | 16876511232 bytes
```

O `docker info` pode ser consultado campo a campo, assim. No laboratório ele informa o próprio
servidor: Ubuntu, `x86_64`, 4 processadores e cerca de 16 GB. **No Docker Desktop, os mesmos campos
descrevem a VM**, e não o seu notebook: outro nome de sistema operacional, e os processadores e a
memória que a tela de ajustes deu à VM. É esse o número que limita os containers, então este comando
é o jeito rápido de conferir o ajuste.

## E o erro que você vai ver primeiro

Quando o motor não está rodando, ou o comando `docker` aponta para onde nada escuta, o cliente avisa.
O laboratório o produz apontando o `DOCKER_HOST` para um socket que não existe:

```
ana@vm:~$ DOCKER_HOST=unix:///run/not-running.sock docker ps
failed to connect to the docker API at unix:///run/not-running.sock; check if the path is correct and if the daemon is running: dial unix /run/not-running.sock: connect: no such file or directory
```

**"failed to connect to the docker API" quer dizer que o cliente está bem e o motor não está lá.** No
Docker Desktop isso quase sempre significa que o aplicativo ainda não foi aberto ou ainda está
iniciando; abra-o e espere. No Linux significa que o serviço `docker` está parado, e a aula 6 mostra
como iniciá-lo. O caminho na mensagem diz qual socket o cliente tentou, o que resolve o caso do
contexto errado da conferência 3.
