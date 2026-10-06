---
title: Fixando pelo digest
version: 1
---

**Um digest nomeia conteúdo, então uma referência com ele só pode querer dizer aqueles bytes.** A aula
15 trouxe o `shelf` de volta pelo digest. Esta etapa usa digests nos dois lugares que decidem o que
roda: as linhas `FROM` de um Dockerfile e a imagem que um deploy inicia.

## Fixando as bases

A máquina da Ana já sabe o digest de cada imagem base que baixou:

```
ana@vm:~/shelf$ docker image inspect golang:1.25 --format "{{index .RepoDigests 0}}"
golang@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
ana@vm:~/shelf$ docker image inspect gcr.io/distroless/static-debian12:nonroot --format "{{index .RepoDigests 0}}"
gcr.io/distroless/static-debian12@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
```

Ela os escreve no Dockerfile, depois da tag. **A tag fica para as pessoas**, para que quem lê ainda
veja "Go 1.25" e "distroless static, nonroot"; **o digest é o que o Docker usa**:

```dockerfile
FROM golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -ldflags "-X main.version=${VERSION}" -o /out/shelf .

FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
COPY --from=build /out/shelf /shelf
USER 65532:65532
CMD ["/shelf"]
```

```
ana@vm:~/shelf$ docker build --build-arg VERSION=1.3.0 -t shelf:1.3.0 . 2>&1 | grep -E "load metadata|\[(build|stage-1) 1/" | awk '!seen[$0]++'
#2 [internal] load metadata for gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
#3 [internal] load metadata for docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#5 [stage-1 1/2] FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
#6 [build 1/7] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
```

O BuildKit resolve as duas bases pelo digest. Se a `golang:1.25` passar amanhã para um build com uma
correção nova do Go, este Dockerfile não percebe. **Esse é o objetivo, e também o custo**: a correção
de segurança na base nova também não chega, até alguém mudar a linha.

## Mantendo os pinos em dia

Um pino que ninguém atualiza é um jeito lento de rodar software velho. A resposta de costume é um bot
que vigia as tags e abre um pull request quando uma delas muda, com o digest novo, para a mudança ser
revisada e testada como qualquer outra. O **Dependabot**, embutido no GitHub, e o **Renovate** fazem
isso para Dockerfiles. Nenhum dos dois roda no laboratório, que não tem um servidor de repositórios; o
que o pull request muda é exatamente a parte `@sha256:` de uma linha como as de cima.

Então a troca não é "fixar ou receber correções". É **quem decide quando a base muda**: quem publica,
num momento que você não escolheu, ou um pull request revisado, num momento que você escolheu.

## Fazendo deploy pelo digest

A Ana envia o `shelf:1.3.0` e o inicia pelo digest, e não pela tag:

```
ana@vm:~/shelf$ docker tag shelf:1.3.0 localhost:5000/shelf:1.3.0 && docker push -q localhost:5000/shelf:1.3.0
localhost:5000/shelf:1.3.0
ana@vm:~/shelf$ D=$(docker image inspect shelf:1.3.0 --format "{{.Id}}"); echo $D
sha256:e836fe6cf919996615b001372a8bb55f76268c6d1f43de798f02d7909e33638e
ana@vm:~/shelf$ docker run -d --name web localhost:5000/shelf@$D
c70c0addfb590dea86799365df113ffb26873b97ea1fd6a78a995068f20675e1
ana@vm:~/shelf$ docker inspect web --format "{{.Config.Image}}"
localhost:5000/shelf@sha256:e836fe6cf919996615b001372a8bb55f76268c6d1f43de798f02d7909e33638e
ana@vm:~/shelf$ docker logs web 2>&1 | tail -1
2026/10/06 17:48:06 shelf 1.3.0 listening on :8080
```

O `docker inspect` registra a referência a partir da qual o container foi iniciado, e ela é o digest.
Aconteça o que acontecer com a tag `1.3.0` depois, inclusive a sobrescrita da etapa anterior, este
container e todos os iniciados a partir da mesma linha rodam os mesmos bytes.

**Deployments do Kubernetes, arquivos do Compose e pipelines de CI aceitam `nome@sha256:…`**, e o
pipeline da aula 26 escreve na saída o digest do que enviou, para o passo que faz o deploy poder
usá-lo. Tags são para pessoas lerem e procurarem; digests são para máquinas rodarem.
