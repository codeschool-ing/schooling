---
title: Escolhendo a base final
version: 1
---

**A base do estágio final é uma escolha entre quão pouco a imagem contém e quanto o programa espera
encontrar.** Um programa que não precisa de nada pode ser entregue sobre nada; a maioria precisa de
um pouco, e descobrir qual pouco é o trabalho.

## `scratch`, e a biblioteca que não estava lá

O `scratch` não é uma imagem: é o sistema de arquivos vazio, o começo do histórico de toda imagem. A
Ana o experimenta, com um estágio de build que esquece o `CGO_ENABLED=0`:

```dockerfile
FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
COPY *.go ./
RUN go build -o /out/shelf .

FROM scratch
COPY --from=build /out/shelf /shelf
CMD ["/shelf"]
```

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.scratch -t shelf:scratch .
sha256:4c2ff6d60a8337b3f7007acc8ecc01790fa8585e21d136b28a403f3e10b14c43
ana@vm:~/shelf$ docker run --rm shelf:scratch
exec /shelf: no such file or directory
```

**`exec /shelf: no such file or directory`, sobre um arquivo que claramente está lá.** A mensagem
engana de um jeito que custa horas às pessoas. O arquivo existe; o que não existe é o programa que
precisa carregá-lo. O `--target build` constrói só o primeiro estágio, então a Ana pode olhar o
binário na imagem onde ele foi feito:

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.scratch --target build -t shelf:build-stage .
sha256:554a36b60c66936487fad95a782e028698b3779d6bb956333f2ba5f9c9c6e377
ana@vm:~/shelf$ docker run --rm shelf:build-stage ldd /out/shelf
	linux-vdso.so.1 (0x00007f00c83c1000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f00c81c2000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f00c83c3000)
```

O `ldd` lista as bibliotecas compartilhadas de que um binário precisa para rodar. Este precisa da
biblioteca C, `libc.so.6`, e do carregador dinâmico, `/lib64/ld-linux-x86-64.so.2`, porque o Go se
liga à biblioteca C quando há um compilador C disponível, o que acontece na `golang:1.25`, e o código
de rede da biblioteca padrão a usa. O `scratch` não tem nenhum dos dois, então o kernel não consegue
iniciar o programa, e diz "no such file" sobre o carregador que não achou. Com `CGO_ENABLED=0`:

```
ana@vm:~/shelf$ sed -i "s/RUN go build -o/RUN CGO_ENABLED=0 go build -o/" Dockerfile.scratch
ana@vm:~/shelf$ docker build -q -f Dockerfile.scratch -t shelf:scratch .
sha256:cce8089a2be62e97415b2bf0467b62244fef68587302c6f5a9d660f81109e726
ana@vm:~/shelf$ docker run --rm -d --name scratch shelf:scratch
486dabeb53ca6c75043dbc02c7ca15d230403a7df15ef570732096defdf82504
ana@vm:~/shelf$ docker logs scratch
2026/10/06 17:23:36 catalogue: built in, 3 books
2026/10/06 17:23:36 shelf dev listening on :8080
ana@vm:~/shelf$ docker image ls shelf:scratch
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
shelf:scratch   cce8089a2be6       21.9MB         7.12MB   U    
```

Um binário totalmente estático, que roda sobre nada, numa imagem de 21.9MB em disco.

## O que cada base lhe dá

| base | o que tem dentro | quando serve |
| --- | --- | --- |
| `scratch` | nada | um binário totalmente estático que não precisa de certificados, fusos horários nem usuários |
| `gcr.io/distroless/static-debian12` | certificados CA, fusos horários, `/etc/passwd`, um usuário sem privilégio; nenhum shell | um binário estático que faz conexões TLS ou imprime horas locais, que é a maioria |
| `gcr.io/distroless/base-debian12` | o de cima mais a biblioteca C | um binário ligado dinamicamente que precisa da `libc` e de mais nada |
| `alpine:3.22` | um Linux pequeno com shell e gerenciador de pacotes, feito sobre `musl` | quando você quer um shell lá dentro, ou precisa de pacotes do Alpine |
| `debian:trixie-slim` | um Debian pequeno com `glibc`, shell e `apt` | linguagens interpretadas e programas que esperam um Linux normal |

Duas armadilhas moram nessa tabela. **O `scratch` não tem certificados CA**, então um programa nele
que chame um serviço HTTPS não consegue verificar certificado nenhum; o distroless `static` existe
justamente para resolver isso. E **o Alpine usa `musl` em vez de `glibc`**: um binário compilado
contra a `glibc` não roda nele, pelo mesmo motivo que o `shelf` não rodou no `scratch`, e alguns
programas se comportam diferente sobre `musl`. Linguagens interpretadas levam o próprio runtime e por
isso são entregues sobre imagens `-slim` próprias, como a `python:3.13-slim` da aula 10, construídas
do mesmo jeito, com um estágio de build que instala o que precisa ser compilado.
