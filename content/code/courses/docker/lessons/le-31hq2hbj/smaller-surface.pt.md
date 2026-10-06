---
title: Uma superfície menor
version: 1
---

**Cada arquivo de uma imagem é algo para baixar, guardar, escanear e manter atualizado, e cada
programa nela é algo que um atacante pode usar.** Uma imagem menor não é sobre economizar disco; é
sobre quanto há para dar errado. A aula 13 levou o `shelf` de 1.44GB para 28MB deixando o compilador
para trás. Esta etapa é sobre a base embaixo dele, e sobre uma armadilha que mantém imagens grandes
sem ninguém perceber.

## Quanto pesam as bases comuns

```
ana@vm:~/shelf$ docker image ls --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep -E "golang|debian|alpine|distroless"
debian:trixie-slim                          119MB
debian:trixie                               187MB
alpine:3.22                                 12.8MB
golang:1.25                                 1.26GB
gcr.io/distroless/static-debian12:nonroot   6.18MB
gcr.io/distroless/static-debian12:latest    6.67MB
```

**De 1.26GB a 6.18MB** entre as bases que este curso usou. As duas imagens Debian são o par
interessante:

```
ana@vm:~/shelf$ docker run --rm debian:trixie sh -c "dpkg -l | grep -c ^ii"
78
ana@vm:~/shelf$ docker run --rm debian:trixie-slim sh -c "dpkg -l | grep -c ^ii"
78
ana@vm:~/shelf$ docker run --rm alpine:3.22 grep -c ^P: /lib/apk/db/installed
16
ana@vm:~/shelf$ docker run --rm debian:trixie-slim sh -c "ls /usr/bin | wc -l"
259
```

A `debian:trixie` e a `debian:trixie-slim` têm **os mesmos 78 pacotes**. A slim é 68MB menor porque
remove documentação, páginas de manual e arquivos de idioma que um container nunca lê, e não porque
tenha menos programas. As duas continuam com 259 programas só em `/usr/bin`, um shell entre eles e o
`apt` para instalar mais. O Alpine conta 16 pacotes. O distroless não tem gerenciador de pacotes a
quem perguntar, e o scanner da aula 20 lista o que há nele.

**O que conta para a segurança não são os megabytes, e sim o que está dentro.** Um shell, um
gerenciador de pacotes, um `curl`: cada um é uma ferramenta que um invasor teria de trazer sozinho, e
cada um é um pacote cujas vulnerabilidades um scanner vai lhe apontar toda semana, use o seu programa
esse pacote ou não.

## Apagar numa camada seguinte não diminui nada

Um Dockerfile que baixa um arquivo, o desempacota e apaga o arquivo parece arrumado. A Ana constrói a
mesma coisa de dois jeitos, com um arquivo de 50 MB fazendo o papel do download:

```dockerfile
FROM alpine:3.22
RUN dd if=/dev/urandom of=/tmp/download.tar bs=1M count=50
RUN rm /tmp/download.tar
```

```dockerfile
FROM alpine:3.22
RUN dd if=/dev/urandom of=/tmp/download.tar bs=1M count=50 && rm /tmp/download.tar
```

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.layers -t layers:two .
sha256:e33a39afdeeb65a8dc7a3e3e21265f42e090b62b9d8fd92c6e3f7781a13cc71e
ana@vm:~/shelf$ docker build -q -f Dockerfile.onelayer -t layers:one .
sha256:c78a9b25f261d561b8369948a4b627faf0ebfe00ab8f7e5e7117b85f852b5404
ana@vm:~/shelf$ docker image ls layers
IMAGE        ID             DISK USAGE   CONTENT SIZE   EXTRA
layers:one   c78a9b25f261       12.8MB          3.8MB        
layers:two   e33a39afdeeb        118MB         56.2MB        
ana@vm:~/shelf$ docker history layers:two --format "{{.Size}}\t{{.CreatedBy}}" | head -3
8.19kB	RUN /bin/sh -c rm /tmp/download.tar # buildk…
52.4MB	RUN /bin/sh -c dd if=/dev/urandom of=/tmp/do…
0B	CMD ["/bin/sh"]
```

**A `layers:two` tem 56.2MB para baixar e a `layers:one`, 3.8MB**, embora as duas terminem com os
mesmos arquivos. As camadas da aula 4 explicam: o segundo `RUN` acrescenta uma camada com um whiteout
para o `/tmp/download.tar`, e a camada de 52.4MB embaixo continua guardando o arquivo, então todo pull
continua levando-o. Só apagar o arquivo no mesmo `RUN` que o criou o mantém fora de todas as camadas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas imagens lado a lado, cada uma uma pilha de camadas. A layers:two tem o alpine embaixo, depois uma camada de 52.4MB que guarda o /tmp/download.tar, depois uma camada de 8.19kB com um whiteout que o esconde; o download é de 56.2MB. A layers:one tem o alpine e uma camada em que o arquivo foi criado e apagado, então ela não guarda nada a mais; o download é de 3.8MB.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">layers:two</text><rect x=\"20\" y=\"136\" width=\"300\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">alpine:3.22</text><rect x=\"20\" y=\"84\" width=\"300\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"107.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">RUN dd …  52.4MB: download.tar</text><rect x=\"20\" y=\"50\" width=\"300\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">RUN rm …  whiteout, 8.19kB</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">para baixar: 56.2MB</text><text x=\"400\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">layers:one</text><rect x=\"400\" y=\"136\" width=\"300\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"412\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">alpine:3.22</text><rect x=\"400\" y=\"102\" width=\"300\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"412\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">RUN dd … &amp;&amp; rm …  nada sobra</text><text x=\"400\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">para baixar: 3.8MB</text></svg>", "caption": "Um whiteout esconde um arquivo da visão mesclada; não o remove da camada de baixo, que todo pull continua baixando.", "same": ["alpine:3.22", "RUN dd … 52.4MB: download.tar", "RUN rm … whiteout, 8.19kB"]}
```

É por isso que Dockerfiles juntam comandos com `&&`:

```dockerfile
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*
```

**Esse bloco não foi construído no laboratório**, cujos containers não alcançam os servidores de
pacotes do Debian; ele é o formato padrão, e o hadolint pediu cada uma das partes dele na aula 10. O
`--no-install-recommends` pula pacotes sugeridos e desnecessários, e o `rm` apaga as listas de pacotes
na mesma camada que as baixou. O mesmo raciocínio vale para segredos: um arquivo apagado numa camada
seguinte continua na anterior, e é por isso que a aula 11 deixou o `.env` fora do contexto de vez, e
que a aula 18 mostra o jeito certo de usar um segredo durante um build.

## Uma lista para o estágio final

1. **Multiestágio**, para não entregar compilador nem código-fonte (aula 13).
2. **A menor base em que o programa roda**: distroless ou `scratch` para binários estáticos, `-slim`
   ou Alpine quando um shell ou pacotes forem de fato necessários.
3. **Um `USER` numérico**, e só os diretórios em que ele escreve entregues a ele.
4. **Instalar, usar e limpar num mesmo `RUN`**, para nada apagado ficar numa camada.
5. **`.dockerignore`** com `.git` e cada segredo (aula 11).
