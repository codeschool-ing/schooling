---
title: Instalando o Docker
version: 1
---

A aula 16 montou um servidor à mão: pacotes, um ambiente virtual, um arquivo de ambiente, units. Uma
**imagem de contêiner** empacota a aplicação e tudo de que ela precisa para rodar num único retrato de
sistema de arquivos, e a mesma imagem roda num notebook, num executor de CI e num servidor. O curso
`docker` ensina o próprio Docker; esta aula o usa para o agenda.

## Três lugares para tê-lo

| caminho | o que você ganha | o que custa ao seu computador |
|---|---|---|
| **na sua máquina virtual** (recomendado) | o Docker Engine do repositório do próprio Docker para Ubuntu, como o curso `docker` o instala | o engine, e as imagens que ele guarda, alguns gigabytes com o tempo |
| **instalado no seu próprio computador** | o Docker Desktop para Windows ou macOS, que roda uma máquina virtual Linux própria | o mesmo, mais essa máquina virtual; a licença do Docker Desktop pede que empresas maiores paguem |
| **online** | uma plataforma que constrói e roda um Dockerfile para você | nada; a plataforma decide a rede, os volumes e os logs |

**A máquina virtual é a escolha**: os pacotes do Docker para Ubuntu são os que o curso `docker` usa e
confere, e os comandos abaixo são do Linux.

## Instalando

Na máquina virtual, o repositório do Docker e depois os pacotes, exatamente como a primeira aula do
curso `docker` os dá:

```sh
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

A última linha deixa você rodar `docker` sem `sudo`. **Fazer parte do grupo `docker` vale tanto quanto
ser root naquela máquina**, o que o curso `docker` mostra em detalhe; numa máquina virtual sua, isso é
aceitável. A mudança vale a partir do próximo login:

```
ana@vm:~$ docker --version
Docker version 29.8.2, build 7fc2dff
ana@vm:~$ docker compose version
Docker Compose version v5.6.0
ana@vm:~$ id -nG
ana docker
ana@vm:~$ docker run --rm hello-world | head -2
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
4f55086f7dd0: Pulling fs layer
4f55086f7dd0: Download complete
4f55086f7dd0: Pull complete
d5e71e642bf5: Download complete
Digest: sha256:11a3eb1597e864c51b3f56733cb2e8a90bf0c284bfc05f9444d81c558bc848aa
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
```

## Quando falha

| sintoma | causa | conserto |
|---|---|---|
| `permission denied while trying to connect to the Docker daemon socket` | a mudança de grupo ainda não valeu | saia e entre de novo; o `id -nG` precisa listar `docker` |
| `Cannot connect to the Docker daemon` | o engine não está rodando | `sudo systemctl start docker` |
| `toomanyrequests` ao baixar imagens | o limite do Docker Hub para downloads anônimos | `docker login`, ou espere; o curso `docker` mostra um espelho |

Essas não foram produzidas para este curso; as mensagens são as do Docker para essas causas.
