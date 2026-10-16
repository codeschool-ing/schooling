---
title: "O mesmo contêiner, rodando em casa"
version: 1
---

Nada no moto roda um contêiner, então uma aula sobre ECS só contra o moto ensinaria a papelada e
nunca a coisa. **O que uma task faz numa instância é iniciar contêineres pelo Docker, com as
configurações que a definição de task nomeia**, e o Docker já está na sua máquina. Esta seção roda
o contêiner do `web.json` de verdade, com a mesma imagem e as mesmas configurações, e é a única
parte da aula em que alguma coisa serve uma página.

## Uma vez: o Docker e a imagem

O curso `docker` instala o Docker Engine no Ubuntu e põe o seu usuário no grupo `docker`, e esta
seção supõe isso. A imagem vem do Docker Hub e é baixada uma vez:

```sh
docker pull nginx:1.29-alpine
```

Depois de baixada, ela ocupa isto do seu disco:

```
ana@laptop:~/aws$ docker image ls nginx:1.29-alpine --format "{{.Repository}}:{{.Tag}}  {{.Size}}"
nginx:1.29-alpine  93.5MB
```

Se o `docker ps` responder com um erro de permissão, o seu usuário ainda não está no grupo
`docker`, ou o terminal foi aberto antes de ele entrar; a aula de instalação do curso `docker`
trata dos dois casos. O moto não precisa estar rodando para nada nesta seção.

## Da definição ao comando

Cada campo da definição de contêiner é uma flag do `docker run`. O agente do ECS faz a mesma
tradução, pela API do Docker em vez da linha de comando:

| no `web.json` | na linha de comando |
|---|---|
| `"image": "nginx:1.29-alpine"` | a imagem, por último |
| `"name": "web"` | `--name web` |
| `"portMappings"`, 8080 para 80 | `-p 8080:80` |
| `"environment"`, `SHOP_ENV` | `-e SHOP_ENV=staging` |
| `"cpu": 256` | `--cpu-shares 256` |
| `"memory": 512` | `--memory 512m` |
| `"logConfiguration"`, `awslogs` | nada aqui: o Docker guarda os logs sozinho |

A última linha é a única diferença real. No ECS o driver `awslogs` manda a saída para o CloudWatch
Logs com a permissão da execution role; aqui o driver padrão do Docker a guarda na máquina, e o
`docker logs` a lê de volta.

```
ana@laptop:~/aws$ docker run -d --name web -p 8080:80 -e SHOP_ENV=staging --cpu-shares 256 --memory 512m nginx:1.29-alpine | cut -c1-12
43b7274123fe
ana@laptop:~/aws$ docker ps --format "{{.Names}}  {{.Image}}  {{.Ports}}"
web  nginx:1.29-alpine  0.0.0.0:8080->80/tcp
ana@laptop:~/aws$ curl -s localhost:8080 | grep -o "<title>.*</title>"
<title>Welcome to nginx!</title>
```

Isso é o nginx, respondendo na porta 8080 do host exatamente como a task responderia na da
instância dela.

## As configurações, lidas de volta

```
ana@laptop:~/aws$ docker exec web printenv SHOP_ENV
staging
ana@laptop:~/aws$ docker inspect --format "{{.HostConfig.CpuShares}} {{.HostConfig.Memory}}" web
256 536870912
ana@laptop:~/aws$ docker logs web 2>/dev/null | tail -1 | cut -c1-80
172.17.0.1 - - [16/Oct/2026:16:30:29 +0000] "GET / HTTP/1.1" 200 896 "-" "curl/8
```

A variável de ambiente está dentro do contêiner, o peso de CPU é 256, e o limite de memória é
536.870.912 bytes, que são 512 MiB. **O `--cpu-shares` é um peso, não um teto**: sem mais nada
rodando, este contêiner pode usar todos os processadores da máquina, e só quando contêineres
disputam é que 256 contra os 1.024 de outro lhe dão um quinto do tempo. É também assim que o agente
aplica o `cpu` de um contêiner no EC2. **A memória é o contrário, um limite rígido**: passando de
512 MiB o kernel mata o processo, e no ECS a task para com um motivo de falta de memória. A última
linha é o log de acesso do nginx para o `curl` acima; no ECS essa linha estaria no grupo de logs
`/ecs/web`.

## A porta, uma segunda vez

O cluster da seção anterior recusou uma segunda cópia desta task numa instância. O Docker a recusa
pelo mesmo motivo:

```
ana@laptop:~/aws$ docker run -d --name web2 -p 8080:80 nginx:1.29-alpine > /dev/null
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint web2 (1a4ab521564d7986e218161edbfcdf7e0facc91e4e61ae6f44b3b5bee3e6fc83): Bind for 0.0.0.0:8080 failed: port is already allocated

Run 'docker run --help' for more information
ana@laptop:~/aws$ docker ps -a --filter name=web2 --format "{{.Names}}  {{.Status}}"
web2  Created
```

**Esta é a falha que o moto não mostraria.** O segundo contêiner foi criado e nunca iniciou, porque
a porta 8080 do host já estava ocupada pelo primeiro. O ECS vê isso antes e nem tenta, que é o
motivo `RESOURCE:PORTS`, e no seu laptop você vê o que teria sido.

## Parando

```
ana@laptop:~/aws$ docker stop web
web
ana@laptop:~/aws$ docker ps -a --filter name=web --format "{{.Names}}  {{.Status}}"
web2  Created
web  Exited (0) Less than a second ago
```

O `docker stop` manda `SIGTERM` ao processo principal do contêiner e, se ele ainda estiver rodando
depois de um prazo, `SIGKILL`. Parar uma task do ECS faz o mesmo com cada contêiner, esperando 30
segundos por padrão antes de matar, que é o `stopTimeout` da definição de contêiner e o assunto da
aula 9 quando o Fargate Spot toma uma task de volta. O nginx saiu na hora com status 0, um
encerramento limpo. Como `web` é o contêiner essencial da task, a saída dele teria parado a task, e
um serviço estaria agora iniciando outra. Nada aqui inicia outra; `docker rm web web2` limpa os dois.
