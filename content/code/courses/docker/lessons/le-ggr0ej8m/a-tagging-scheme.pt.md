---
title: Um esquema de tags
version: 1
---

**Um bom conjunto de tags responde a duas perguntas: que versão é esta, e de que commit ela foi
construída.** Um build pode levar várias tags, então pode responder às duas de uma vez. A convenção
da Ana é a mais comum:

| tag | nomeia | muda quando |
| --- | --- | --- |
| `1.2.3` | uma versão | nunca, por acordo |
| `1.2` | a `1.2.x` mais nova | sai uma correção |
| `1` | a `1.x.y` mais nova | sai uma versão menor ou uma correção |
| `sha-12d9616` | o commit de onde veio | nunca |

A primeira e a última nomeiam um build. As duas do meio são tags móveis de propósito, como a
`alpine:3.22` da aula 15: quem escreve `shelf:1.2` pede correções sem funcionalidades novas.

## Labels: o que a imagem diz de si mesma

**As tags moram no registry; os labels moram na imagem.** Uma tag pode ser removida ou movida, e uma
imagem copiada para outro registry não leva nenhuma das tags antigas, mas os labels viajam com ela. A
Open Container Initiative define um conjunto padrão, `org.opencontainers.image.*`, e o estágio final
da Ana agora leva cinco deles, preenchidos a partir de argumentos de build:

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
ARG VERSION=dev
ARG REVISION=unknown
ARG CREATED
LABEL org.opencontainers.image.title="shelf" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.created="${CREATED}" \
      org.opencontainers.image.source="https://git.example.com/ana/shelf"
COPY --from=build /out/shelf /shelf
USER 65532:65532
CMD ["/shelf"]
```

**Os labels ficam no estágio final**, depois do `FROM` dele, porque labels escritos no estágio de
build ficam no estágio de build. As linhas `ARG` se repetem ali pelo mesmo motivo: um argumento só é
visível no estágio que o declara.

## Um build, quatro tags

A revisão e a data vêm do git, então descrevem o commit e não o momento do build:

```
ana@vm:~/shelf$ git log -1 --format="%h %cI %s"
12d9616 2026-09-01T10:00:00-03:00 shelf: the catalogue over HTTP
ana@vm:~/shelf$ REV=$(git rev-parse --short HEAD); CREATED=$(git log -1 --format=%cI)
ana@vm:~/shelf$ docker build -q --build-arg VERSION=1.2.3 --build-arg REVISION=$REV --build-arg CREATED=$CREATED -t localhost:5000/shelf:1.2.3 -t localhost:5000/shelf:1.2 -t localhost:5000/shelf:1 -t localhost:5000/shelf:sha-$REV .
sha256:7c24c08ea6d316d91b9349afaeba3ba36fc6ac1873f06bba05ba947cd3f8fabf
ana@vm:~/shelf$ docker image inspect localhost:5000/shelf:1.2.3 --format "{{json .Config.Labels}}" | jq .
{
  "org.opencontainers.image.created": "2026-09-01T10:00:00-03:00",
  "org.opencontainers.image.revision": "12d9616",
  "org.opencontainers.image.source": "https://git.example.com/ana/shelf",
  "org.opencontainers.image.title": "shelf",
  "org.opencontainers.image.version": "1.2.3"
}
```

Quatro `-t`, um build, um id. O `docker push --all-tags` envia todas as tags do repositório, e o
registry as lista:

```
ana@vm:~/shelf$ docker push -q --all-tags localhost:5000/shelf
localhost:5000/shelf
ana@vm:~/shelf$ curl -s localhost:5000/v2/shelf/tags/list
{"name":"shelf","tags":["1","1.2","1.2.3","latest","sha-12d9616"]}
```

A `latest` continua lá desde a etapa anterior, apontando para a 1.1.0, porque nada depois a nomeou. É
o estado honesto de uma `latest` de que ninguém cuida.

## Uma correção move as tags certas

Uma correção sai como 1.2.4. A Ana marca o novo build com `1.2.4`, `1.2` e `1`, e não com `1.2.3`:

```
ana@vm:~/shelf$ docker build -q --build-arg VERSION=1.2.4 --build-arg REVISION=$REV --build-arg CREATED=$CREATED -t localhost:5000/shelf:1.2.4 -t localhost:5000/shelf:1.2 -t localhost:5000/shelf:1 .
sha256:9b514dcad08cf5896925b29f3f2fa0f9fcb25bedf6cb9ffeb1b28b9da1f8c2e4
ana@vm:~/shelf$ docker push -q --all-tags localhost:5000/shelf
localhost:5000/shelf
ana@vm:~/shelf$ for t in 1.2.3 1.2.4 1.2 1 sha-$REV latest; do printf "%-12s %s\n" $t $(digest $t); done
1.2.3        sha256:7c24c08ea6d3
1.2.4        sha256:9b514dcad08c
1.2          sha256:9b514dcad08c
1            sha256:9b514dcad08c
sha-12d9616  sha256:7c24c08ea6d3
latest       sha256:613066b36b4c
```

A função `digest` pergunta ao registry para onde cada tag aponta, como a aula 15 fez com o `curl`, e
imprime os primeiros caracteres. **`1.2.3` e `sha-12d9616` continuam nomeando o build antigo; `1.2` e
`1` foram para o novo.** Tudo o que pedia `1.2` recebe a correção no próximo pull, e tudo o que fixou
`1.2.3` continua exatamente com o que testou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"Seis tags no registry da Ana e as três imagens para onde apontam. 1.2.3 e sha-12d9616 apontam para sha256:7c24c08ea6d3, shelf 1.2.3. 1.2.4, 1.2 e 1 apontam para sha256:9b514dcad08c, shelf 1.2.4; antes da versão de correção, 1.2 e 1 apontavam para a imagem 1.2.3. latest aponta para sha256:613066b36b4c, shelf 1.1.0, porque nada enviado depois a nomeou. 1.2.3, 1.2.4 e sha-12d9616 estão desenhadas como tags fixas; 1.2, 1 e latest, como móveis.\"><defs><marker id=\"l16tags-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l16tags-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"30\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">1.2.3</text><path d=\"M180 45 L420 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16tags-ah-phosphor)\"></path><rect x=\"40\" y=\"70\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sha-12d9616</text><path d=\"M180 85 L420 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16tags-ah-phosphor)\"></path><rect x=\"40\" y=\"130\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">1.2.4</text><path d=\"M180 145 L420 185\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16tags-ah-phosphor)\"></path><rect x=\"40\" y=\"170\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"110\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">1.2</text><path d=\"M180 185 L420 185\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16tags-ah-amber)\"></path><rect x=\"40\" y=\"210\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"110\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">1</text><path d=\"M180 225 L420 185\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16tags-ah-amber)\"></path><rect x=\"40\" y=\"260\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"110\" y=\"279\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">latest</text><path d=\"M180 275 L420 275\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16tags-ah-amber)\"></path><path d=\"M180 185 L420 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M180 225 L420 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><rect x=\"420\" y=\"43\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sha256:7c24c08ea6d3</text><text x=\"440\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelf 1.2.3</text><rect x=\"420\" y=\"163\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sha256:9b514dcad08c</text><text x=\"440\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelf 1.2.4</text><rect x=\"420\" y=\"253\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"271\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sha256:613066b36b4c</text><text x=\"440\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelf 1.1.0</text><rect x=\"40\" y=\"312\" width=\"24\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"72\" y=\"323\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fixa: nomeia um build</text><rect x=\"260\" y=\"312\" width=\"24\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"292\" y=\"323\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">móvel: segue o mais novo</text><path d=\"M480 319 L510 319\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"518\" y=\"323\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">antes do push da 1.2.4</text></svg>", "caption": "Depois do push da 1.2.4. Uma tag fixa é fixa por hábito: o registry deixou a Ana sobrescrever a 1.2.3 também.", "same": ["shelf 1.2.3", "shelf 1.2.4", "shelf 1.1.0"]}
```

## Uma tag fixa é fixa por convenção

Nada acima impediu ninguém. A Ana constrói outra coisa e envia como `1.2.3`:

```
ana@vm:~/shelf$ docker build -q --build-arg VERSION=9.9.9 -t localhost:5000/shelf:1.2.3 .
sha256:f8c6d16d0587c47ffb43bcb07c1c119bc983bdd81a51b0bdc4a2ff229fbfac14
ana@vm:~/shelf$ docker push -q localhost:5000/shelf:1.2.3
localhost:5000/shelf:1.2.3
ana@vm:~/shelf$ printf "%-12s %s\n" 1.2.3 $(digest 1.2.3)
1.2.3        sha256:f8c6d16d0587
```

**O registry aceitou.** A `1.2.3` agora nomeia um build que se diz 9.9.9, e toda máquina que baixar
`shelf:1.2.3` a partir de hoje recebe esse. Registries hospedados podem recusar isso: o Amazon ECR e o
Google Artifact Registry têm, os dois, um ajuste que torna as tags imutáveis, e vale ligá-lo para tags
de versão. Mesmo assim, **uma tag é uma promessa que o registry cumpre; um digest é um fato sobre os
bytes**. Esse é o assunto da próxima etapa.

Mais um fato das capturas: a 1.0.0 construída no início desta aula tem o id `acc588659f39`, e a 1.0.0
construída do mesmo código na aula 15 tinha `f13bb63f689b`. **Construir o mesmo commit de novo não dá
a mesma imagem**, já que a configuração da imagem registra, entre outras coisas, quando ela foi
construída. Uma versão é a imagem que foi enviada, e não uma receita para fazê-la de novo, e é por
isso que a tag nunca é reenviada a partir de um novo build.
