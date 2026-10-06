---
title: As instruções que importam
version: 1
---

**Um Dockerfile tem mais ou menos uma dúzia de instruções, e dois pares delas causam quase toda a
confusão: as duas formas do `CMD`, e `ARG` contra `ENV`.** Os dois são mais fáceis de entender vendo
o que dá errado.

## Forma exec e forma de shell

`CMD ["shelf"]` é a **forma exec**: uma lista JSON, e o Docker roda esse programa direto como o
processo 1 do container. A Ana para o container que iniciou na etapa anterior e mede o tempo:

```
ana@vm:~/shelf$ time docker stop shelf
shelf

real	0m0.219s
user	0m0.019s
sys	0m0.013s
ana@vm:~/shelf$ docker logs shelf
2026/10/06 16:59:12 catalogue: built in, 3 books
2026/10/06 16:59:12 shelf dev listening on :8080
2026/10/06 16:59:13 received terminated, shutting down
2026/10/06 16:59:13 stopped
```

Um quinto de segundo. O `docker stop` mandou `SIGTERM`, o `shelf` o recebeu, registrou que estava
encerrando, terminou as requisições abertas e saiu. Agora a mesma imagem com uma linha mudada, para a
**forma de shell**, do jeito de que o aviso do hadolint na aula 10 reclamava:

```dockerfile
FROM golang:1.25
WORKDIR /src
COPY . .
RUN go build -o /usr/local/bin/shelf .
EXPOSE 8080
CMD shelf
```

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.shell -t shelf:shell-form .
sha256:6e1b75f0cc9c2eab5b2699127fad0a316f14e4564e1e6778af6bd9476f92f943
ana@vm:~/shelf$ docker run -d --name shell-form shelf:shell-form
e0e947263a5484f9bcf2f4ef859a420fb8f62d71ce2634c082a1c24231215c99
```

O container roda como antes. A lista de processos dele, não:

```
ana@vm:~/shelf$ docker top shell-form -o pid,ppid,args
PID                 PPID                COMMAND
17709               17681               /bin/sh -c shelf
17723               17709               shelf
```

**O processo 1 é `/bin/sh -c shelf`, e o `shelf` é filho dele.** A forma de shell embrulha o comando
num shell, e este shell não repassa sinais ao filho. Parando:

```
ana@vm:~/shelf$ time docker stop shell-form
shell-form

real	0m10.155s
user	0m0.017s
sys	0m0.014s
ana@vm:~/shelf$ docker logs shell-form
2026/10/06 16:59:34 catalogue: built in, 3 books
2026/10/06 16:59:34 shelf dev listening on :8080
```

**Dez segundos, e nenhum "shutting down" no log.** O `SIGTERM` foi para o shell, que o ignorou;
depois dos dez segundos padrão, o Docker mandou `SIGKILL`, que encerrou os dois de uma vez. O `shelf`
nunca soube: requisições em andamento foram cortadas, e um programa que grava dados ao sair os teria
perdido. É o mesmo 137 que a aula 7 viu no `sleep`. **Escreva `CMD` e `ENTRYPOINT` na forma exec**, e
se um shell for mesmo necessário, termine o script dele com `exec shelf`, para o programa substituir o
shell como processo 1.

## `ENTRYPOINT` e `CMD` juntos

O `ENTRYPOINT` é o programa que sempre roda; o `CMD` fornece os argumentos padrão dele, que qualquer
coisa digitada depois do nome da imagem no `docker run` substitui. A imagem `postgres` da aula 9 usava
exatamente isso, `docker-entrypoint.sh` com `postgres` como argumento, e as ferramentas da aula 10 o
usavam para que `docker run mikefarah/yq:4 ".x"` rodasse `yq ".x"`. Para um serviço como o `shelf`,
só o `CMD` basta.

## `ARG` para o build, `ENV` para o container

A Ana quer que a imagem saiba a própria versão, que o `shelf` imprime em `/version`, e uma porta
padrão que possa ser mudada na execução:

```dockerfile
FROM golang:1.25
ARG VERSION=dev
WORKDIR /src
COPY . .
RUN go build -ldflags "-X main.version=${VERSION}" -o /usr/local/bin/shelf .
ENV PORT=8080
EXPOSE 8080
CMD ["shelf"]
```

**`ARG VERSION=dev` é uma variável só do build.** O `--build-arg` a define, e a linha `RUN` a passa ao
linker do Go, que a grava no binário. **`ENV PORT=8080` é uma variável da imagem**: ela fica guardada
na configuração da imagem e é definida em todo container, onde o `docker run -e` pode sobrescrevê-la.

```
ana@vm:~/shelf$ docker build -q --build-arg VERSION=1.0.0 -t shelf:1.0.0 .
sha256:ba7af0568d99f60b56cb23c181ac458cd468b982fd09a138d52d80eed248bdf5
ana@vm:~/shelf$ docker run -d --name v1 -e PORT=9090 -p 127.0.0.1:9090:9090 shelf:1.0.0
e8846b8482d687d64eb1d2ee08a538b8d8f7bfefc46464bb5b74da4e0a9cbd83
ana@vm:~/shelf$ curl -s localhost:9090/version
1.0.0
ana@vm:~/shelf$ docker logs v1
2026/10/06 17:00:06 catalogue: built in, 3 books
2026/10/06 17:00:06 shelf 1.0.0 listening on :9090
```

A versão veio do argumento de build, e a porta do `-e`, que venceu o `ENV` da imagem. A configuração
da imagem guarda uma e não a outra:

```
ana@vm:~/shelf$ docker image inspect shelf:1.0.0 --format "{{json .Config.Env}}"
["PATH=/go/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin","GOLANG_VERSION=1.25.14","GOTOOLCHAIN=local","GOPATH=/go","PORT=8080"]
```

O `PORT=8080` está lá, ao lado das variáveis que a imagem base `golang` definiu. O `VERSION` não está:
ele existiu enquanto o build rodava. **É por isso que um segredo nunca deve ser passado com `ENV`**,
que todo container e qualquer pessoa com a imagem consegue ler, e é por isso que a aula 18 mostra que
um `ARG` também não é lugar seguro para um.

## O resto, numa tabela

| instrução | o que faz | onde se ensina |
| --- | --- | --- |
| `FROM` | a imagem base; vários `FROM` fazem um build multiestágio | aqui, e aula 13 |
| `RUN` | roda um comando na hora do build e guarda o resultado como camada | aqui, e aula 12 |
| `COPY` | copia arquivos do contexto de build, ou de outro estágio | aqui, e aula 13 |
| `ADD` | como o `COPY`, mas também desempacota arquivos locais e busca URLs; use `COPY` a menos que precise disso | aqui |
| `WORKDIR` | o diretório onde as instruções seguintes e o container começam | aqui |
| `ENV`, `ARG` | variáveis da imagem, e do build | aqui |
| `EXPOSE` | documenta uma porta; não publica nada | aqui, e aula 17 |
| `USER` | o usuário com que as instruções seguintes e o container rodam | aula 14 |
| `CMD`, `ENTRYPOINT` | o que o container roda | aqui |
| `HEALTHCHECK` | como o Docker testa se o programa está saudável | aula 18 |
| `LABEL` | metadados, como o repositório de origem e a versão | aula 16 |
