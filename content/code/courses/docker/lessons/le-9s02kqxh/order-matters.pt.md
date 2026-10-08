---
title: A ordem importa
version: 2
---

**Ponha no topo do Dockerfile o que muda raramente e embaixo o que muda com frequência.** As
dependências mudam uma vez por mês; o código muda a cada poucos minutos. Um Dockerfile que copia tudo
num passo só faz cada edição pagar de novo pelas dependências.

## O preço do `COPY . .` primeiro

A Ana muda uma mensagem de log no `main.go` e reconstrói:

```
ana@vm:~/shelf$ sed -i "s/listening on/serving on/" main.go
ana@vm:~/shelf$ time docker build --progress=plain -t shelf:dev . 2>&1 | awk '/^#[0-9]+ \[(stage-0 )?[0-9]/ {n[$1]=1; print; next} ($1 in n) && /DONE|CACHED/'
#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 DONE 0.0s
#6 [2/4] WORKDIR /src
#6 CACHED
#7 [3/4] COPY . .
#7 DONE 0.2s
#8 [4/4] RUN go build -o /usr/local/bin/shelf .
#8 DONE 14.4s

real	0m20.272s
user	0m0.152s
sys	0m0.106s
```

**20 segundos.** O `COPY . .` viu um arquivo mudado, então rodou de novo, e o `go build` embaixo dele
rodou de novo do zero: 14.4 segundos compilando a biblioteca padrão e o pgx, que não tinham mudado em
nada. Fica pior. Ela acrescenta um README, que o programa nunca lê:

```
ana@vm:~/shelf$ echo "# shelf" > README.md
ana@vm:~/shelf$ time docker build --progress=plain -t shelf:dev . 2>&1 | awk '/^#[0-9]+ \[(stage-0 )?[0-9]/ {n[$1]=1; print; next} ($1 in n) && /DONE|CACHED/'
#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 DONE 0.0s
#6 [2/4] WORKDIR /src
#6 CACHED
#7 [3/4] COPY . .
#7 DONE 0.3s
#8 [4/4] RUN go build -o /usr/local/bin/shelf .
#8 DONE 13.9s

real	0m19.798s
user	0m0.149s
sys	0m0.101s
```

**Mais 19.8 segundos**, por um arquivo que nem chega ao binário. O `COPY . .` o copiou, o checksum
dele entrou na chave, e tudo abaixo foi reconstruído.

## Dependências primeiro

A correção é copiar na ordem em que as coisas mudam. A Ana reescreve o Dockerfile:

```dockerfile
FROM golang:1.25
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
RUN go build -o /usr/local/bin/shelf .
CMD ["shelf"]
```

A descrição das dependências e o código vendorizado vêm primeiro, e um `RUN` compila os pacotes de que
o `shelf` depende, o `net/http` da biblioteca padrão e o pool de conexões do pgx, para o cache de build
do Go dentro dessa camada. Só depois os arquivos `.go` são copiados, e o `go build` final encontra todo
o resto já compilado. O primeiro build custa o mesmo de antes:

```
ana@vm:~/shelf$ time docker build --progress=plain -t shelf:dev . 2>&1 | awk '/^#[0-9]+ \[(stage-0 )?[0-9]/ {n[$1]=1; print; next} ($1 in n) && /DONE|CACHED/'
#4 [1/7] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 DONE 0.0s
#5 [2/7] WORKDIR /src
#5 CACHED
#7 [3/7] COPY go.mod go.sum ./
#7 DONE 0.2s
#8 [4/7] COPY vendor/ vendor/
#8 DONE 0.1s
#9 [5/7] RUN go build net/http github.com/jackc/pgx/v5/pgxpool
#9 DONE 13.3s
#10 [6/7] COPY *.go ./
#10 DONE 0.0s
#11 [7/7] RUN go build -o /usr/local/bin/shelf .
#11 DONE 0.9s

real	0m19.754s
user	0m0.141s
sys	0m0.094s
```

O passo lento agora é o 5, 13.3 segundos, e o build final do próprio `shelf` é 0.9. Depois, a mesma
edição no `main.go`:

```
ana@vm:~/shelf$ sed -i "s/serving on/listening on/" main.go
ana@vm:~/shelf$ time docker build --progress=plain -t shelf:dev . 2>&1 | awk '/^#[0-9]+ \[(stage-0 )?[0-9]/ {n[$1]=1; print; next} ($1 in n) && /DONE|CACHED/'
#4 [1/7] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 DONE 0.0s
#6 [2/7] WORKDIR /src
#6 CACHED
#7 [3/7] COPY go.mod go.sum ./
#7 CACHED
#8 [4/7] COPY vendor/ vendor/
#8 CACHED
#9 [5/7] RUN go build net/http github.com/jackc/pgx/v5/pgxpool
#9 CACHED
#10 [6/7] COPY *.go ./
#10 DONE 0.2s
#11 [7/7] RUN go build -o /usr/local/bin/shelf .
#11 DONE 1.0s

real	0m2.340s
user	0m0.165s
sys	0m0.067s
```

**2.3 segundos em vez de 20.** Os passos de 1 a 5 vieram do cache, porque nada acima do `COPY *.go`
mudou, e só a compilação final, pequena, rodou. E o README:

```
ana@vm:~/shelf$ echo "A bookshop catalogue over HTTP." >> README.md
ana@vm:~/shelf$ time docker build --progress=plain -t shelf:dev . 2>&1 | awk '/^#[0-9]+ \[(stage-0 )?[0-9]/ {n[$1]=1; print; next} ($1 in n) && /DONE|CACHED/'
#4 [1/7] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 DONE 0.0s
#6 [4/7] COPY vendor/ vendor/
#6 CACHED
#7 [2/7] WORKDIR /src
#7 CACHED
#8 [3/7] COPY go.mod go.sum ./
#8 CACHED
#9 [5/7] RUN go build net/http github.com/jackc/pgx/v5/pgxpool
#9 CACHED
#10 [6/7] COPY *.go ./
#10 CACHED
#11 [7/7] RUN go build -o /usr/local/bin/shelf .
#11 CACHED

real	0m0.331s
user	0m0.136s
sys	0m0.074s
```

**Tudo em cache, 0.3 segundo**: o `COPY *.go` só copia arquivos Go, então um README não muda chave
nenhuma. Copiar exatamente o que cada passo precisa é o mesmo hábito que a aula 11 recomendou para
manter segredos de fora, rendendo uma segunda vez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois Dockerfiles lado a lado, cada um uma coluna de passos, depois que o main.go mudou. À esquerda, FROM e WORKDIR estão em cache, e o COPY . . mudou, então ele e o go build abaixo rodam de novo, inclusive o passo lento. À direita, FROM, WORKDIR, COPY go.mod go.sum, COPY vendor e o passo que compila as dependências estão todos em cache; só o COPY *.go e o go build final rodam.\"><text x=\"10\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">COPY . . primeiro</text><rect x=\"10\" y=\"36\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">FROM golang:1.25</text><text x=\"250\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CACHED</text><rect x=\"10\" y=\"72\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">WORKDIR /src</text><text x=\"250\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CACHED</text><rect x=\"10\" y=\"108\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">COPY . .</text><text x=\"250\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">mudou</text><rect x=\"10\" y=\"144\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">RUN go build …</text><text x=\"250\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">roda de novo</text><text x=\"370\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">dependências primeiro</text><rect x=\"370\" y=\"36\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">FROM golang:1.25</text><text x=\"610\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CACHED</text><rect x=\"370\" y=\"72\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">WORKDIR /src</text><text x=\"610\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CACHED</text><rect x=\"370\" y=\"108\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COPY go.mod go.sum ./</text><text x=\"610\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CACHED</text><rect x=\"370\" y=\"144\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COPY vendor/ vendor/</text><text x=\"610\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CACHED</text><rect x=\"370\" y=\"180\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">RUN go build net/http …</text><text x=\"610\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CACHED</text><rect x=\"370\" y=\"216\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"380\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">COPY *.go ./</text><text x=\"610\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">mudou</text><rect x=\"370\" y=\"252\" width=\"230\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"380\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">RUN go build …</text><text x=\"610\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">roda de novo</text></svg>", "caption": "Um passo só é reaproveitado se ele e todos os passos acima estiverem iguais. O primeiro passo que mudou roda de novo, e tudo depois dele também, então o que muda com frequência vai embaixo.", "same": ["CACHED"]}
```

## O mesmo padrão em outras linguagens

O formato é sempre o mesmo, seja qual for a linguagem: o arquivo que lista as dependências, depois o
comando que as instala, depois o código.

| linguagem | primeiro copiar | depois rodar | depois copiar |
| --- | --- | --- | --- |
| Go, com módulos | `go.mod`, `go.sum` | `go mod download` | o código |
| Python | `requirements.txt` | `pip install -r requirements.txt` | o código |
| Node.js | `package.json`, `package-lock.json` | `npm ci` | o código |
| Java, com Maven | `pom.xml` | `mvn dependency:go-offline` | `src/` |

Esses comandos de instalação baixam da internet, que os containers do laboratório não alcançam, como
mostrou a última seção da aula 5; é por isso que o `shelf` mantém a dependência em `vendor/`, como a
aula 11 a deixou, e a compila. Na sua máquina o `go mod download` funciona, e os dois arranjos são
corretos. O argumento da ordem não muda: o passo lento fica acima do código, com a chave dependendo só dos arquivos que
descrevem as dependências.
