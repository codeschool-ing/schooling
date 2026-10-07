---
title: O contexto de build e o .dockerignore
version: 1
---

**O builder não lê o seu disco.** O `docker build .` empacota o diretório `.` e o manda ao builder, e
essa cópia, o **contexto de build**, é o único lugar de onde o `COPY` consegue pegar arquivos. O que
estiver no diretório vai, a menos que um arquivo chamado `.dockerignore` diga outra coisa, e dois
tipos de coisa tornam isso importante: o que é grande, e o que é segredo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"À esquerda, o diretório do projeto da Ana: .git, .env, testdata com um dump de 300 MB, vendor, go.mod e os arquivos .go. Um filtro .dockerignore no meio descarta .git, .env e testdata. À direita, o contexto de build que o builder recebe: vendor, go.mod, go.sum e os arquivos .go. O COPY . . só copia do contexto, então o que passou pelo filtro pode acabar na imagem.\"><defs><marker id=\"l11ctx-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l11ctx-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"240\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">~/shelf, no disco</text><text x=\"30\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">.git</text><path d=\"M28 64 L62 64\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"30\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">.env</text><path d=\"M28 94 L62 94\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"30\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">testdata/  300M</text><path d=\"M28 124 L150 124\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"30\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vendor/</text><text x=\"30\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">go.mod  go.sum</text><text x=\"30\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main.go  postgres.go</text><rect x=\"290\" y=\"95\" width=\"140\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">.dockerignore</text><text x=\"360\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">descarta o que lista</text><path d=\"M252 133 L286 133\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11ctx-ah-wire)\"></path><path d=\"M432 133 L466 133\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11ctx-ah-phosphor)\"></path><rect x=\"470\" y=\"20\" width=\"240\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"486\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">o contexto de build</text><text x=\"490\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vendor/</text><text x=\"490\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">go.mod  go.sum</text><text x=\"490\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main.go  postgres.go</text><text x=\"490\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">*_test.go</text><text x=\"490\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que o COPY . . pode copiar</text><text x=\"490\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">para a imagem</text></svg>", "caption": "O builder nunca lê o seu disco; ele lê o que o cliente mandou. O .dockerignore decide o que é mandado, e o COPY só consegue pegar disso."}
```

## O que é mandado

Um mês depois, o diretório da Ana ganhou duas coisas normais numa cópia de trabalho: uma exportação
de banco de 300 MB que ela usa para testar, e um arquivo `.env` com a string de conexão do banco
local dela:

```
ana@vm:~/shelf$ mkdir -p testdata && head -c 300M /dev/urandom > testdata/catalogue-dump.sql
ana@vm:~/shelf$ du -sh .git vendor testdata
3.9M	.git
8.3M	vendor
301M	testdata
```

```
DATABASE_URL=postgres://shelf:s3cret-from-ana@db:5432/shelf
```

Ela constrói de novo:

```
ana@vm:~/shelf$ docker build -t shelf:dev . 2>&1 | grep -E "transferring context|naming to"
#3 transferring context: 2B done
#5 transferring context: 314.72MB 1.8s done
#9 naming to docker.io/library/shelf:dev done
```

**314.72MB transferidos**, onde o primeiro build mandou 10.03MB. Aqui isso levou 1.8 segundo, numa
máquina só; no Docker Desktop, onde o contexto atravessa para uma VM, ou para um builder do outro lado
de uma rede, os mesmos bytes viajam a cada build que os mudou. E o `COPY . .` copiou tudo isso para a
imagem:

```
ana@vm:~/shelf$ docker run --rm shelf:dev ls -a /src
.
..
.env
.git
Dockerfile
Dockerfile.shell
go.mod
go.sum
main.go
main_test.go
postgres.go
postgres_test.go
testdata
vendor
ana@vm:~/shelf$ docker run --rm shelf:dev cat /src/.env
DATABASE_URL=postgres://shelf:s3cret-from-ana@db:5432/shelf
```

**A senha está na imagem.** Qualquer pessoa que baixar a `shelf:dev` de um registry consegue lê-la,
junto com o histórico inteiro do git em `.git`, e a exportação do banco também. Apagar o arquivo numa
instrução seguinte não adianta, porque a aula 14 mostra que uma camada anterior guarda tudo o que
tinha.

## Deixando coisas de fora

O `.dockerignore` fica ao lado do Dockerfile e lista o que o cliente não deve mandar, numa sintaxe
parecida com a do `.gitignore`:

```
.git
.env
testdata/
Dockerfile*
.dockerignore
```

```
ana@vm:~/shelf$ docker build -t shelf:dev . 2>&1 | grep -E "transferring context|naming to"
#3 transferring context: 86B done
#5 transferring context: 22.75kB 0.2s done
#9 naming to docker.io/library/shelf:dev done
ana@vm:~/shelf$ docker run --rm shelf:dev ls -a /src
.
..
go.mod
go.sum
main.go
main_test.go
postgres.go
postgres_test.go
vendor
```

O `/src` da imagem agora guarda o código e a dependência vendorizada, e mais nada. A linha do
contexto diz 22.75kB desta vez, menos que o `vendor/` sozinho: o BuildKit guarda os arquivos de builds
anteriores e só manda o que mudou desde então, então o número conta a transferência, e não o tamanho
do contexto. O primeiro build de um builder novo paga o contexto inteiro.

Três hábitos decorrem disso:

- **Comece o `.dockerignore` de todo projeto com `.git` e com cada arquivo que guarde um segredo**,
  antes do primeiro build, porque o primeiro build é o que vaza.
- **Liste o próprio Dockerfile e o `.dockerignore`**, como a Ana fez: a imagem não precisa deles, e
  deixá-los de fora faz com que editá-los não mude o que o `COPY . .` copia.
- **Prefira copiar o que a imagem precisa a copiar tudo e excluir.** `COPY go.mod go.sum ./` e
  `COPY *.go ./` dizem exatamente o que entra; a aula 12 reescreve este Dockerfile assim, por um
  motivo próprio.
