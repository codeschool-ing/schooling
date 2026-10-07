---
title: Construir numa imagem, entregar em outra
version: 1
---

**Um Dockerfile multiestágio tem várias linhas `FROM`, e só o último estágio vira a imagem.** Os
estágios anteriores guardam o que o build precisar, um compilador, o código, caches, e o último
estágio copia só o resultado. É a maior melhoria que a maioria das imagens pode receber, e custa
poucas linhas.

A Ana guarda o Dockerfile ordenado da aula 12 como `Dockerfile.single` e escreve um de dois estágios
ao lado:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM golang:1.25 AS build\nWORKDIR /src\nCOPY go.mod go.sum ./\nCOPY vendor/ vendor/\nRUN go build net/http github.com/jackc/pgx/v5/pgxpool\nCOPY *.go ./\n", "note": "O primeiro estágio, chamado `build`, é o Dockerfile ordenado da aula 12: o conjunto de ferramentas do Go, as dependências compiladas primeiro, depois o código."}, {"code": "RUN CGO_ENABLED=0 go build -o /out/shelf .\n", "note": "O `CGO_ENABLED=0` faz o Go pôr tudo dentro do binário, sem depender da biblioteca C. A próxima etapa mostra o que acontece sem ele."}, {"code": "\nFROM gcr.io/distroless/static-debian12\n", "note": "Uma linha em branco e um segundo `FROM` iniciam um estágio novo, com base nova. Nada do primeiro estágio vem junto a menos que seja pedido."}, {"code": "COPY --from=build /out/shelf /shelf\n", "note": "O `COPY --from=build` tira um arquivo do primeiro estágio. O compilador, o código e o cache de build ficam para trás."}, {"code": "CMD [\"/shelf\"]\n", "note": "O comando da imagem, na forma exec, com o caminho completo, porque esta base não tem shell para procurar no `PATH`."}]}
```

Ela constrói os dois:

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.single -t shelf:single .
sha256:5dda2a49c2b9dd76a3dd79c4d43998738ebd134733a4ea6fec877e96ab8bb83f
ana@vm:~/shelf$ docker build -q -t shelf:slim .
sha256:7cf63664c09b72351f9ead83d5568307c886e857676d48988987c6f1da32dbe1
```

```
ana@vm:~/shelf$ docker image ls shelf
IMAGE          ID             DISK USAGE   CONTENT SIZE   EXTRA
shelf:single   5dda2a49c2b9       1.44GB          343MB        
shelf:slim     7cf63664c09b         28MB         7.84MB        
```

**1.44GB contra 28MB**, para o mesmo programa. A imagem de um estágio leva o conjunto de ferramentas
inteiro do Go e o cache de build; a de dois estágios leva um binário de 14.7MB sobre uma base de
poucos megabytes, como o histórico dela mostra:

```
ana@vm:~/shelf$ docker history shelf:slim
IMAGE          CREATED         CREATED BY                                      SIZE      COMMENT
7cf63664c09b   2 seconds ago   CMD ["/shelf"]                                  0B        buildkit.dockerfile.v0
<missing>      2 seconds ago   COPY /out/shelf /shelf # buildkit               14.7MB    buildkit.dockerfile.v0
<missing>      N/A             bazel build //common:cacerts_debian12_amd64_…   319kB     
<missing>      N/A             bazel build //common:os_release_debian12        16.4kB    
<missing>      N/A             bazel build //static:nsswitch                   12.3kB    
<missing>      N/A             bazel build //common:tmp                        8.19kB    
<missing>      N/A             bazel build //common:group                      12.3kB    
<missing>      N/A             bazel build //common:home                       16.4kB    
<missing>      N/A             bazel build //common:passwd                     12.3kB    
<missing>      N/A             bazel build //common:rootfs                     4.1kB     
<missing>      N/A             bazel build @bookworm//media-types/amd64:dat…   152kB     
<missing>      N/A             bazel build @bookworm//tzdata/amd64:data_sta…   4.24MB    
<missing>      N/A             bazel build @bookworm//netbase/amd64:data_st…   86kB      
<missing>      N/A             bazel build @bookworm//base-files/amd64:data…   582kB     
```

As duas linhas de cima são da Ana. Tudo abaixo é **distroless**, uma família de imagens base do
Google construídas com o Bazel em vez de um Dockerfile, daí as linhas `bazel build` e a falta de
datas. Ela guarda só o que um programa estático pode precisar de um sistema operacional: certificados
CA para verificar conexões TLS, dados de fuso horário, um `/etc/passwd` com alguns usuários e o
`/tmp`. Nenhum gerenciador de pacotes, e nenhum shell.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Dois estágios. À esquerda, o estágio de build, golang:1.25: o conjunto de ferramentas do Go, os diretórios de código e vendor, o cache de build e o /out/shelf compilado; a imagem de um estágio só, com tudo isso, tem 1.44GB. Uma seta chamada COPY --from=build leva só o /out/shelf para a direita, o estágio final: distroless static com certificados CA, fusos horários e /etc/passwd, mais o /shelf, 28MB em disco.\"><defs><marker id=\"l13stages-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"320\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"26\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">estágio build · golang:1.25</text><rect x=\"26\" y=\"56\" width=\"288\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"71\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ferramentas do Go, Debian</text><rect x=\"26\" y=\"96\" width=\"288\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">/src  vendor/  *.go</text><rect x=\"26\" y=\"136\" width=\"288\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cache de build</text><rect x=\"26\" y=\"176\" width=\"288\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">/out/shelf</text><text x=\"170\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">guardado como imagem: 1.44GB</text><path d=\"M316 191 L436 191\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l13stages-ah-amber)\"></path><text x=\"376\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">COPY --from=build</text><rect x=\"440\" y=\"20\" width=\"270\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"456\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">estágio final · distroless</text><rect x=\"456\" y=\"56\" width=\"238\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">certificados CA, fusos horários</text><text x=\"470\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">/etc/passwd  /tmp</text><rect x=\"456\" y=\"176\" width=\"238\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">/shelf</text><text x=\"575\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a imagem: 28MB</text></svg>", "caption": "Tudo o que o build precisou fica no primeiro estágio. A imagem é o último estágio, e ele recebe um arquivo."}
```

## Rodando, e o que falta

```
ana@vm:~/shelf$ docker run -d --name slim -p 127.0.0.1:8080:8080 shelf:slim
dc7983dde1fea02af672268ace862bc294ae3f9de4456393b033664f8b717d8c
ana@vm:~/shelf$ curl -s localhost:8080/health
ok
ana@vm:~/shelf$ docker exec slim sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
ana@vm:~/shelf$ docker exec slim ls /
OCI runtime exec failed: exec failed: unable to start container process: exec: "ls": executable file not found in $PATH
```

O serviço responde exatamente como antes. Os dois `exec` são o que mudou: **não há `sh` nem `ls` na
imagem**, então nada pode ser rodado lá dentro além do `shelf`. Isso é uma propriedade, não um
acidente. Um atacante que ganhe um ponto de apoio por um bug no programa não encontra shell para
continuar, e um scanner encontra pouquíssimos pacotes onde apontar vulnerabilidades; a aula 20 mede a
diferença. Custa conveniência na depuração, e a aula 22 mostra como olhar dentro de um container
desses pelo lado de fora quando algo dá errado.
