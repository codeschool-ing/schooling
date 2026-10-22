---
title: Docker Engine, para um teste ter um banco
version: 1
---

Os testes até aqui não precisam de nada além de um JDK. Os próximos precisam de um PostgreSQL 16 de
verdade, e não o que a aula 9 instalou: aquele banco guarda o que você fez nele à mão por último, e um
teste que passa por causa de uma linha que você inseriu na terça passada não prova nada. **O
Testcontainers sobe um banco novo num contêiner a cada execução dos testes e o joga fora depois**, e
para isso a máquina precisa de um engine de contêineres. Este curso usa o **Docker Engine**, o daemon de
código aberto da Docker, e o comando `docker`, que conversa com ele.

Um **contêiner** é um processo que o engine inicia com um sistema de arquivos próprio, desempacotado de
uma **imagem**, e isolado do resto da máquina: ele enxerga os próprios arquivos, os próprios processos e
o próprio endereço de rede. Uma imagem do PostgreSQL 16 contém o servidor e tudo de que ele precisa,
então um contêiner criado a partir dela é um servidor de banco que existe enquanto durar a execução dos
testes. A aula 1 já usou isso uma vez, como uma máquina limpa criada em uma linha, para mostrar o que um
Ubuntu recém-instalado diz quando falta o Java.

Isto é o mínimo de Docker de que o curso precisa. O curso `docker` é onde contêineres são ensinados de
verdade, e a aula 5 dele instala o engine exatamente do jeito mostrado aqui, então quem chegar a ele
depois deste curso vai encontrar tudo pronto.

## Três jeitos de ter um engine

| | o que é | quanto custa |
| --- | --- | --- |
| **na mesma máquina virtual** (recomendado) | o Docker Engine do repositório de pacotes da própria Docker, dentro da VM Ubuntu 24.04 que o curso usa desde a aula 1 | algumas centenas de megabytes de disco para o engine, mais as imagens, que a última seção desta aula mede; e 4 GB de memória para a VM, como a aula 1 a dimensionou, porque os testes rodam uma JVM e um banco lado a lado |
| Docker Desktop no seu computador | o aplicativo da Docker para Windows e macOS, que roda uma VM Linux própria | a memória e o disco dessa VM, definidos nas configurações dele; uma licença paga numa empresa grande; e o `docker` passa a rodar no seu computador, então os testes também teriam de rodar ali, fora da VM |
| um engine remoto | `DOCKER_HOST` apontando para um Docker Engine em outra máquina | nada local; uma máquina que você precisa manter ligada, e o banco que os testes sobem fica nela, alcançado pela rede |

**Escolha o primeiro.** Os testes desta aula rodam dentro da VM, com o Maven, e o Testcontainers procura
o engine na mesma máquina. O Desktop funciona quando o projeto inteiro mora no seu computador em vez da
VM; um engine remoto funciona e faz cada execução de testes esperar a rede. Nenhum dos dois volta a ser
usado neste curso.

## Instalando

Dentro da VM, os comandos são as instruções de instalação da própria Docker para Ubuntu. Eles
acrescentam ao `apt` a chave de assinatura e o repositório de pacotes da Docker e depois instalam o
engine e o cliente de linha de comando. A documentação da Docker é o primeiro lugar para conferi-los,
porque os detalhes mudam:

```sh
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Mais uma linha deixa o seu usuário falar com o engine sem `sudo`:

```sh
sudo usermod -aG docker $USER
```

**Um grupo novo só vale a partir do próximo login.** Saia da VM e faça login de novo; uma aba nova num
terminal que já estava aberto não é um login novo. Nada acima foi executado na máquina em que este curso foi gravado, que já tinha os pacotes
da Docker instalados antes de o curso começar; o que vem a seguir é como se confere o resultado, e isso
foi executado.

```
ana@vm:~/bookshop$ id -nG
ana docker
ana@vm:~/bookshop$ ls -l /var/run/docker.sock
srw-rw---- 1 root docker 0 Oct 22 19:09 /var/run/docker.sock
```

`docker` na lista de grupos quer dizer que o novo login valeu. O socket é a porta do engine: pertence ao
`root`, e só o grupo `docker` pode ler e escrever nele, mais ninguém. Estar nesse grupo, portanto, é o
mesmo que poder iniciar qualquer contêiner, inclusive um que monte o disco inteiro, e é por isso que a
aula 6 de `docker` chama essa participação pelo nome: root naquela máquina. Numa VM que existe para ser
jogada fora, é uma troca justa.

Duas verificações decidem se o engine funciona:

```
ana@vm:~/bookshop$ docker version
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

**`docker version` responde em dois blocos, e os dois precisam estar lá.** `Client` é o comando
`docker`; `Server` é o engine que ele alcançou pelo socket, com as versões das peças por baixo dele. Um
bloco de cliente seguido de um erro quer dizer que o comando está instalado e o engine não está
acessível, e a próxima seção trata exatamente disso.

```
ana@vm:~/bookshop$ docker run --rm hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
4f55086f7dd0: Pulling fs layer
4f55086f7dd0: Download complete
4f55086f7dd0: Pull complete
d5e71e642bf5: Download complete
Digest: sha256:11a3eb1597e864c51b3f56733cb2e8a90bf0c284bfc05f9444d81c558bc848aa
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

**`hello-world` é o menor teste que vai até o fim**: o engine não tinha a imagem, buscou-a no Docker
Hub, criou um contêiner a partir dela e o executou, e o programa do contêiner imprimiu o texto, que
descreve o caminho que acabou de fazer. O `--rm` removeu o contêiner quando ele terminou. O
Testcontainers faz as mesmas quatro coisas para cada banco que sobe, pelo mesmo socket.
