---
title: Montagens de cache, e quando o cache atrapalha
version: 1
---

**Uma montagem de cache dá a um passo `RUN` um diretório que sobrevive entre builds sem virar parte da
imagem.** O cache de camadas é tudo ou nada: um passo é reaproveitado inteiro ou roda do zero. Uma
montagem de cache deixa um passo que precisa rodar de novo manter o cache da própria ferramenta, e
assim rodar rápido mesmo assim.

## Mantendo o cache de build do Go

A Ana volta ao Dockerfile simples, de um `COPY` só, e acrescenta uma opção ao `RUN`:

```dockerfile
FROM golang:1.25
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/root/.cache/go-build \
    go build -o /usr/local/bin/shelf .
CMD ["shelf"]
```

O `--mount=type=cache,target=/root/.cache/go-build` monta um diretório que o builder guarda, no lugar
onde o Go grava o cache de build. O primeiro build o enche:

```
ana@vm:~/shelf$ time docker build -q -t shelf:mount .
sha256:be7eb671693861f5d232d2d855e8b3ae23a02d3c72f2e23c6f8d576ac3c3c4a5

real	0m15.786s
user	0m0.121s
sys	0m0.112s
```

Depois, a mesma edição de uma linha no `main.go`, a que custou 20 segundos duas etapas atrás:

```
ana@vm:~/shelf$ sed -i "s/listening on/serving on/" main.go
ana@vm:~/shelf$ time docker build --progress=plain -t shelf:mount . 2>&1 | awk '/^#[0-9]+ \[(stage-0 )?[0-9]/ {n[$1]=1; print; next} ($1 in n) && /DONE|CACHED/'
#4 [stage-0 1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 DONE 0.0s
#6 [stage-0 2/4] WORKDIR /src
#6 CACHED
#7 [stage-0 3/4] COPY . .
#7 DONE 0.1s
#8 [stage-0 4/4] RUN --mount=type=cache,target=/root/.cache/go-build     go build -o /usr/local/bin/shelf .
#8 DONE 0.9s

real	0m2.147s
user	0m0.127s
sys	0m0.088s
```

**2.1 segundos.** O `COPY . .` rodou de novo, como antes, e o `go build` também; mas o Go encontrou a
biblioteca padrão e o pgx já compilados no cache montado e só reconstruiu o `shelf`. O diretório
montado pertence ao builder, não a uma camada, então o cache de build fica fora da imagem.

As duas técnicas se combinam. O Dockerfile ordenado poupa o trabalho quando as dependências não
mudaram; uma montagem de cache poupa a maior parte dele quando mudaram, porque o cache do gerenciador
de pacotes ainda guarda as versões que não se mexeram. Todo gerenciador de pacotes tem um diretório
assim: `/root/.cache/pip` para o pip, `/root/.npm` para o npm, `/root/.m2` para o Maven.

## Onde o cache mora, e quanto custa

O cache do builder não faz parte de imagem nenhuma, e cresce. O `docker buildx du` o informa:

```
ana@vm:~/shelf$ docker buildx du | tail -4
Shared:		1.28GB
Private:	967MB
Reclaimable:	2.247GB
Total:		2.247GB
```

2.247GB na máquina da Ana depois dos poucos builds desta aula, tudo recuperável, porque nenhuma imagem
precisa dele para rodar. O `docker builder prune` o esvazia, e a aula 22 o põe numa rotina de limpeza
com o resto.

## Quando o cache atrapalha

O cache confia nas chaves dele, e uma chave só conhece o texto da instrução e os arquivos copiados.
**Um `RUN` que busca alguma coisa na rede tem a mesma chave seja o que for que a rede devolva.** Um
`RUN apt-get update && apt-get install -y curl` escrito há um ano fica em cache como uma lista de
pacotes de um ano atrás, e todo build naquela máquina a reaproveita, com atualizações de segurança ou
sem. Três saídas:

- **`docker build --no-cache`** ignora toda camada em cache neste build. É o comando certo para um
  build agendado cujo propósito é pegar atualizações.
- **`docker build --pull`** busca antes a imagem base mais nova, então uma base que recebeu
  atualizações muda todas as chaves depois do `FROM`.
- **Um runner de CI costuma começar sem cache nenhum**, o que é correto e lento. A aula 26 mostra como
  um pipeline guarda o cache num registry para o segundo build do dia também ser rápido.
