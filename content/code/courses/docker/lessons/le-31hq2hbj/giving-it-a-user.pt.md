---
title: Dando um usuário à imagem
version: 1
---

**O `USER` define com quem o processo do container roda, e ele pertence a todo estágio final.** A
correção da Ana são duas linhas: a variante `nonroot` do distroless como base, e um `USER` que nomeia
a conta sem privilégio dela pelo número:

```dockerfile
FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
RUN CGO_ENABLED=0 go build -o /out/shelf .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/shelf /shelf
USER 65532:65532
CMD ["/shelf"]
```

```
ana@vm:~/shelf$ docker build -q -t shelf:nonroot .
sha256:d013d9af0537955c50a0e59dcbcb72fb0a5969d2c321b8cd769c29fb8d89e73d
ana@vm:~/shelf$ docker image inspect shelf:nonroot --format "User: [{{.Config.User}}]"
User: [65532:65532]
ana@vm:~/shelf$ docker run -d --name as-nonroot shelf:nonroot
c263c53c95dcfa89303c6b30c6956d512b9e2224e325e52e9594471e0adcc486
ana@vm:~/shelf$ docker top as-nonroot -o pid,uid,args
PID                 UID                 COMMAND
3256                65532               /shelf
```

**UID 65532.** O número é o usuário que o distroless chama de `nonroot`, como o próprio `/etc/passwd`
dele diz; o `docker cp` consegue ler um arquivo de dentro de um container mesmo quando a imagem não tem
`cat` para isso:

```
ana@vm:~/shelf$ docker cp as-nonroot:/etc/passwd - | tar -xO
root:x:0:0:root:/root:/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/sbin/nologin
nonroot:x:65532:65532:nonroot:/home/nonroot:/sbin/nologin
```

## Por que um número e não um nome

`USER nonroot` funcionaria aqui, e `USER 65532:65532` continua sendo o hábito melhor. **Um nome é
procurado no `/etc/passwd` da imagem quando o container inicia, e um número não precisa de busca
nenhuma.** Orquestradores conferem, antes de iniciar um container, que ele não vai rodar como root, e
só conseguem ter certeza a partir de um número: o `runAsNonRoot` do Kubernetes recusa uma imagem cujo
`USER` é um nome que ele não consegue verificar. Escrever o grupo também, `:65532`, impede o processo
de herdar o grupo 0 do root.

## Uma porta baixa não exige mais root

O motivo antigo para rodar como root era escutar numa porta abaixo de 1024, que antes era reservada ao
root. A Ana pede ao `shelf`, como UID 65532, que escute na porta 80:

```
ana@vm:~/shelf$ docker run -d --name low-port -e PORT=80 shelf:nonroot
5d0bec73eee313d51dfa2afcc1ea9f7c814ab554ea167f5f439db73773a8f6d5
ana@vm:~/shelf$ docker logs low-port
2026/10/06 17:30:47 catalogue: built in, 3 books
2026/10/06 17:30:47 shelf dev listening on :80
ana@vm:~/shelf$ docker run --rm alpine:3.22 cat /proc/sys/net/ipv4/ip_unprivileged_port_start
0
```

**Funciona.** O Docker define o `ip_unprivileged_port_start` como 0 dentro do namespace de rede de cada
container, então qualquer usuário pode usar qualquer porta ali. A porta dentro do container raramente
importa, de qualquer jeito, já que o `-p` mapeia nela o que o host precisar, como a aula 17 mostra.

## A outra metade: arquivos que o usuário pode escrever

Um usuário sem privilégio só consegue escrever onde recebeu permissão. A Ana experimenta uma imagem
pequena sobre Alpine, onde usuários são criados com `adduser`, e um diretório para a saída do
programa:

```dockerfile
FROM alpine:3.22
RUN addgroup -S -g 10001 app && adduser -S -u 10001 -G app app
RUN mkdir /data
USER 10001:10001
CMD ["sh", "-c", "id; touch /data/report.txt"]
```

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.alpine -t user-demo .
sha256:78f2d6e7dca31b6938d7ac03f8cc9ffa9443bd999b656b499669def0a8ce7472
ana@vm:~/shelf$ docker run --rm user-demo
uid=10001(app) gid=10001(app) groups=10001(app)
touch: /data/report.txt: Permission denied
```

O usuário existe com o número que a Ana escolheu, e **não consegue escrever em `/data`**, que o
`RUN mkdir` criou como root. Arquivos e diretórios feitos durante o build pertencem ao root a menos
que o Dockerfile diga outra coisa, então o diretório precisa ser entregue antes de o `USER` trocar de
usuário:

```dockerfile
FROM alpine:3.22
RUN addgroup -S -g 10001 app && adduser -S -u 10001 -G app app
RUN mkdir /data && chown app:app /data
USER 10001:10001
CMD ["sh", "-c", "id; touch /data/report.txt && ls -l /data"]
```

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.alpine -t user-demo .
sha256:015916e39e517b57a6251d9700080a6b511be646c7bfe800286d4810bf2c3db1
ana@vm:~/shelf$ docker run --rm user-demo
uid=10001(app) gid=10001(app) groups=10001(app)
total 0
-rw-r--r--    1 app      app              0 Oct  6 17:30 report.txt
```

A regra é dar ao usuário exatamente os diretórios em que ele escreve, e mais nada; o `COPY --chown=`
faz o mesmo com arquivos copiados. E para dados que devem sobreviver ao container, o diretório é um
volume, e o volume é o da aula 8.
