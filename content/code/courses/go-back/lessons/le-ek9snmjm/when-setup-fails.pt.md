---
title: Quando a preparação falha
version: 1
---

O primeiro comando que a maioria das pessoas digita depois de instalar é recusado:

```
ana@vm:~$ docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"
client 29.8.2, server 
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

**O cliente funciona e não alcança o servidor.** O `docker` é um cliente que fala com o daemon pelo
socket `/var/run/docker.sock`, e só o root e o grupo `docker` podem abri-lo:

```
ana@vm:~$ docker ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
ana@vm:~$ sudo usermod -aG docker $USER
ana@vm:~$ id -nG; docker ps
ana docker
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

Adicione-se ao grupo e depois saia e entre de novo, porque uma sessão em andamento mantém os grupos com que
começou; o `id -nG` lista os que o shell tem agora. **Saiba antes o que o grupo concede.** O daemon roda
como root e faz o que um membro pedir, inclusive iniciar um container com qualquer diretório da máquina
montado dentro dele, então pertencer ao grupo é ser root naquela máquina por outro caminho. A aula 6 do
curso `docker` mostra isso lendo um arquivo que só o root pode ler. Na sua própria máquina, tudo bem; num
servidor compartilhado, o grupo recebe o mesmo cuidado que o `sudo`, e o Docker rootless ou o Podman são a
resposta quando essa confiança não pode ser dada.

Quando o daemon nem está rodando, a mensagem nomeia o socket e pergunta se ele está:

```
ana@vm:~$ DOCKER_HOST=unix:///run/nobody-here.sock docker ps
failed to connect to the docker API at unix:///run/nobody-here.sock; check if the path is correct and if the daemon is running: dial unix /run/nobody-here.sock: connect: no such file or directory
```

Essa foi produzida apontando o `docker` para um socket em que ninguém escuta; um daemon parado aparece
igual, com o caminho de verdade. Numa máquina com systemd, o `sudo systemctl start docker` o inicia e o
`sudo journalctl -u docker` diz por que ele não iniciou.

Mais duas falhas vêm de fora da sua máquina:

- **Um registry recusando o pull.** O Docker Hub limita quantas imagens um cliente anônimo pode baixar num
  período, e passado o limite ele responde `429 Too Many Requests`. Entrar com `docker login` aumenta o
  limite. A imagem sobre a qual esta aula constrói vem do registry do Google, `gcr.io`, que é outro
  serviço, com limites próprios.
- **Sem espaço.** Imagens e caches de build se acumulam. O `docker system df` mostra quanto ocupam, e o
  `docker image prune` e o `docker builder prune` devolvem o espaço.
