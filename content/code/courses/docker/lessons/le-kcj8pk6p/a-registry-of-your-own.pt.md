---
title: Um registry só seu
version: 2
---

**Um registry é um programa como outro qualquer, e o de referência é uma imagem: `registry:3`, o
projeto Distribution da CNCF.** Colocá-lo para rodar leva um minuto, e é o jeito mais rápido de ver
tudo o que um registry faz, porque o Docker Hub e todos os registries de nuvem falam a mesma API.

## Iniciando, com senha

Um registry em que qualquer um pode enviar imagens é um registry que alguém vai encher com as suas,
então a Ana dá um usuário ao dela desde o começo. O registry confere senhas num arquivo `htpasswd`, e
a ferramenta que escreve esse arquivo está dentro da imagem `httpd`:

```
ana@vm:~$ mkdir auth && docker run --rm --entrypoint htpasswd httpd:2 -Bbn ana lab-only > auth/htpasswd
ana@vm:~$ cut -c1-20 auth/htpasswd
ana:$2y$05$XsINzn15f
```

A senha fica guardada como um hash bcrypt, o prefixo `$2y$`, e nunca como ela mesma. Depois, o
registry, com o armazenamento num volume nomeado e o arquivo de senhas montado só para leitura:

```
ana@vm:~$ docker run -d --name registry -p 127.0.0.1:5000:5000 -v registry-data:/var/lib/registry -v "$PWD/auth":/auth:ro -e REGISTRY_AUTH=htpasswd -e REGISTRY_AUTH_HTPASSWD_REALM=lab -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd registry:3
159da126c53391067054553254509daad82e5ce143073def39ea190c7bd7ff26
```

## Dando à imagem um nome para ele

A imagem a enviar é a `shelf:1.0.0`. Ela vem do Dockerfile da aula 14 com o `ARG VERSION` da aula
11 no estágio de build, para que a versão fique gravada no programa e o `/version` responda com ela.
Este é o Dockerfile a partir do qual as próximas aulas constroem:

```dockerfile
FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -ldflags "-X main.version=${VERSION}" -o /out/shelf .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/shelf /shelf
USER 65532:65532
CMD ["/shelf"]
```

A Ana a construiu antes da primeira transcrição desta aula; o `-q` faz o build imprimir só o id da
imagem nova:

```sh
cd ~/shelf
docker build -q --build-arg VERSION=1.0.0 -t shelf:1.0.0 .
cd ~
```

**Uma imagem vai para o registry que o nome dela diz.** Para enviar `shelf:1.0.0` ao registry da Ana,
ela precisa de um nome que comece com o endereço do registry. O `docker tag` acrescenta um segundo
nome à mesma imagem, e os dois nomes têm um único id:

```
ana@vm:~$ docker tag shelf:1.0.0 localhost:5000/shelf:1.0.0
ana@vm:~$ docker image ls --format "{{.Repository}}:{{.Tag}}\t{{.ID}}" | grep shelf
shelf:1.0.0	f13bb63f689b
localhost:5000/shelf:1.0.0	f13bb63f689b
```

## Enviando

Primeiro, sem fazer login:

```
ana@vm:~$ docker push localhost:5000/shelf:1.0.0
The push refers to repository [localhost:5000/shelf]
287d7fef7bb7: Waiting
a5789fc40e82: Waiting
44136fa355b3: Waiting
990a9c434e5e: Waiting
push access denied, repository does not exist or may require authorization: authorization failed: no basic auth credentials
```

`no basic auth credentials`: o registry recusou antes de qualquer camada ser enviada. A Ana faz login,
passando a senha pela entrada padrão para que ela nunca apareça no histórico do shell nem na lista de
processos:

```
ana@vm:~$ echo lab-only | docker login localhost:5000 -u ana --password-stdin

WARNING! Your credentials are stored unencrypted in '/home/ana/.docker/config.json'.
Configure a credential helper to remove this warning. See
https://docs.docker.com/go/credential-store/

Login Succeeded
ana@vm:~$ jq . ~/.docker/config.json
{
  "auths": {
    "localhost:5000": {
      "auth": "YW5hOmxhYi1vbmx5"
    }
  }
}
ana@vm:~$ jq -r ".auths[\"localhost:5000\"].auth" ~/.docker/config.json | base64 -d; echo
ana:lab-only
```

**Leia o aviso.** O `docker login` guardou as credenciais em `~/.docker/config.json`, e o campo `auth`
não está criptografado, só codificado: `base64 -d` devolve `ana:lab-only` num comando. Quem consegue
ler esse arquivo tem a conta. Num notebook, configure um **credential helper**, que guarda o segredo
no chaveiro do sistema operacional; o Docker Desktop já configura um por padrão. Num runner de CI,
faça login no início do job com um token de vida curta e logout no fim, que é o que a aula 26 faz.

```
ana@vm:~$ docker push localhost:5000/shelf:1.0.0
The push refers to repository [localhost:5000/shelf]
3214acf345c0: Pushed
52630fc75a18: Pushed
dd64bf2dd177: Pushed
dcaa5a89b0cc: Pushed
7c12895b777b: Pushed
44136fa355b3: Pushed
bf7a4185f015: Pushed
2780920e5dbf: Pushed
98143612ed16: Waiting
287d7fef7bb7: Pushed
b839dfae01f6: Pushed
990a9c434e5e: Pushed
a5789fc40e82: Pushed
39dc083afc39: Pushed
96ed2737ae31: Pushed
98143612ed16: Pushed
1.0.0: digest: sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11 size: 856
```

## O que o registry guarda agora

A API HTTP do registry responde a requisições comuns. A lista de repositórios, as tags do `shelf` e os
cabeçalhos do manifesto para o qual `1.0.0` aponta:

```
ana@vm:~$ curl -s -u ana:lab-only localhost:5000/v2/_catalog
{"repositories":["shelf"]}
ana@vm:~$ curl -s -u ana:lab-only localhost:5000/v2/shelf/tags/list
{"name":"shelf","tags":["1.0.0"]}
ana@vm:~$ curl -s -u ana:lab-only -o /dev/null -D - -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/shelf/manifests/1.0.0 | grep -i -E "content-type|docker-content-digest"
Content-Type: application/vnd.oci.image.index.v1+json
Docker-Content-Digest: sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11
```

**O `Docker-Content-Digest` é o digest que o push imprimiu**, `sha256:f13b…`, e também o id da imagem
local: os mesmos bytes, com o mesmo nome, dos dois lados. A Ana apaga as cópias locais e baixa a
imagem de volta por esse digest, e não pela tag:

```
ana@vm:~$ docker image rm shelf:1.0.0 localhost:5000/shelf:1.0.0
Untagged: shelf:1.0.0
Untagged: localhost:5000/shelf:1.0.0
Deleted: sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11
ana@vm:~$ docker pull localhost:5000/shelf@sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11
localhost:5000/shelf@sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11: Pulling from shelf
98143612ed16: Pulling fs layer
44136fa355b3: Download complete
98143612ed16: Already exists
287d7fef7bb7: Download complete
98143612ed16: Pull complete
Digest: sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11
Status: Downloaded newer image for localhost:5000/shelf@sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11
localhost:5000/shelf@sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11
ana@vm:~$ docker run -d --name from-registry localhost:5000/shelf@sha256:f13bb63f689b9a6af18ddd859e492acf9e4c332d041a90d5970f55c0c0823f11
9d6907334998d9800338f1f354ede4e52f56667eb77202b4a6fa8f57fd51311e
ana@vm:~$ docker logs from-registry
2026/10/06 17:36:22 catalogue: built in, 3 books
2026/10/06 17:36:22 shelf 1.0.0 listening on :8080
```

O pull cita o digest que pediu e recebe o mesmo de volta, e o container iniciado a partir dele diz
`shelf 1.0.0`. **Um deploy que nomeia imagens assim roda exatamente o que foi testado**, aconteça o
que acontecer com a tag depois.

## Saindo

```
ana@vm:~$ docker logout localhost:5000
Removing login credentials for localhost:5000
ana@vm:~$ jq . ~/.docker/config.json
{
  "auths": {}
}
```

A entrada sumiu do `config.json`. Numa máquina compartilhada, esse é o último comando da sessão.
