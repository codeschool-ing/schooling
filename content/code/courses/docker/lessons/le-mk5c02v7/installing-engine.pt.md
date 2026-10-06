---
title: Instalando o Docker Engine, e quem pode usá-lo
version: 1
---

**No Linux, instale o Docker Engine pelo repositório de pacotes do próprio Docker, e não pelo da
distribuição nem pelo Docker Desktop.** Os pacotes da distribuição ficam para trás e às vezes têm
outros nomes; o repositório do Docker tem o motor atual, o containerd e os plugins Compose e Buildx,
compilados para cada distribuição suportada.

## Como fica uma instalação

A máquina do laboratório foi instalada desse jeito antes de o curso começar, e os pacotes e o arquivo
de repositório dela mostram o resultado:

```
ana@vm:~$ dpkg-query -W -f '${Package} ${Version}\n' docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
containerd.io 2.3.6-1~ubuntu.24.04~noble
docker-buildx-plugin 0.37.1-1~ubuntu.24.04~noble
docker-ce 5:29.8.2-1~ubuntu.24.04~noble
docker-ce-cli 5:29.8.2-1~ubuntu.24.04~noble
docker-compose-plugin 5.6.0-1~ubuntu.24.04~noble
ana@vm:~$ cat /etc/apt/sources.list.d/docker.list
deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu   noble stable
```

Cinco pacotes: o motor (`docker-ce`), o comando (`docker-ce-cli`), o containerd e os dois plugins que
fornecem `docker buildx` e `docker compose`. A linha do repositório nomeia o servidor do Docker, a
arquitetura da máquina, a versão do Ubuntu pelo codinome, `noble`, e a chave que assina os pacotes,
então o `apt` recusa qualquer coisa que não tenha sido assinada pelo Docker.

Estes são os comandos que montam isso no Ubuntu, das instruções de instalação do Docker. **Eles não
foram executados para este curso**, porque o laboratório já tinha o resultado, e a documentação do
Docker é o lugar para conferi-los antes de rodar, já que os detalhes mudam:

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

Numa máquina que inicia com systemd, que é quase todo servidor e notebook Linux, o pacote inicia o
daemon e o habilita no boot; o `sudo systemctl status docker` o mostra rodando, e o
`sudo systemctl start docker` o inicia se ele tiver parado. **A máquina do laboratório é a exceção**:
ela não inicia com systemd, então o daemon dela é iniciado pelo script do próprio laboratório, e o
`systemctl` diz isso:

```
ana@vm:~$ systemctl status docker
System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
```

## O grupo docker

Por padrão, só o root pode usar o socket da etapa anterior. Para deixar um usuário comum rodar
`docker` sem `sudo`, as instruções de instalação o acrescentam ao grupo `docker`, que é dono do
socket. A Ana está nele; o Bruno, outro usuário da mesma máquina, não está:

```
ana@vm:~$ id
uid=30033(ana) gid=30033(ana) groups=30033(ana),996(docker)
ana@vm:~$ getent group docker
docker:x:996:ana
```

```
ana@vm:~$ sudo -u bruno docker ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

A mensagem é o socket recusando o Bruno, o que está certo. **Antes de acrescentá-lo, entenda o que o
grupo concede.** Pertencer a ele deixa o Bruno pedir qualquer coisa ao `dockerd`, e o `dockerd` roda
como root. Um pedido que ele aceita é "inicie um container com este diretório do host montado lá
dentro". O laboratório tem um diretório que só o root pode ler, com números de salário inventados. A
Ana não consegue listá-lo como ela mesma, e consegue lê-lo através de um container:

```
ana@vm:~$ ls /srv/payroll
ls: cannot open directory '/srv/payroll': Permission denied
ana@vm:~$ docker run --rm -v /srv/payroll:/p alpine:3.22 cat /p/salaries.csv
name,monthly_brl
ana,9800
bruno,10400
```

**Pertencer ao grupo `docker` é ser root naquela máquina, por outro caminho.** Isso não é um bug a
corrigir; é o que significa um daemon rodando como root e aceitando montagens, e a própria
documentação do Docker avisa que o grupo concede privilégios de nível root. Então o grupo recebe o
mesmo cuidado que a lista do `sudo`: num servidor compartilhado, só as pessoas a quem se confiaria o
root. A aula 21 volta ao mesmo socket pelo outro lado, como algo que nunca se monta dentro de um
container.

**O modo rootless é a alternativa** quando essa confiança não pode ser dada: o próprio daemon roda
como um usuário comum, dentro de um namespace de usuários, então o root de um container é esse
usuário e nada mais. O Docker publica uma ferramenta de configuração para ele no pacote
`docker-ce-rootless-extras`. Ele tem limites, com portas abaixo de 1024 e alguns recursos de rede e
armazenamento, e a documentação do Docker os lista; ele não foi configurado para este curso.
