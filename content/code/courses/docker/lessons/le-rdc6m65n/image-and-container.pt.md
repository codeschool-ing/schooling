---
title: Imagem e container
version: 1
---

**Uma imagem é aquilo de onde um container parte; um container é o que está rodando.** A imagem é
um pacote somente leitura: um sistema de arquivos com tudo de que o programa precisa, mais alguns
metadados, como o comando que roda por padrão. Um container é uma instância feita a partir dela: os
arquivos da imagem, uma camada fina só dele por cima, onde ele pode escrever, uma configuração e o
processo em execução.

As duas palavras são trocadas o tempo todo, e a confusão esconde perguntas reais. "Apagar o
container" e "apagar a imagem" fazem coisas diferentes, e "o container está com a versão nova"
quase sempre quer dizer "um container novo foi iniciado a partir da imagem nova".

## O que a máquina guarda

O `docker image ls` lista as imagens da máquina da Ana:

```
ana@vm:~$ docker image ls
IMAGE         ID             DISK USAGE   CONTENT SIZE   EXTRA
alpine:3.22   5291449c3df7       12.8MB         3.88MB        
golang:1.25   699337d62055       1.26GB          316MB        
postgres:16   65b16a8b326e        642MB          166MB        
postgres:17   ae69c452f483        646MB          167MB   U    
```

Duas colunas de tamanho, e elas respondem perguntas diferentes. **`CONTENT SIZE`** é quanto a
imagem pesa comprimida, como ela viaja a partir de um registry: 3.88MB para `alpine:3.22`. **`DISK
USAGE`** é quanto ela ocupa descompactada neste disco: 12.8MB para a mesma imagem. A `golang:1.25`
é a pesada, 1.26GB em disco, porque um compilador completo e a biblioteca padrão dele estão lá
dentro. O `U` ao lado de `postgres:17` quer dizer "em uso": um container feito a partir dela, o banco
da etapa anterior, está rodando.

## Dois containers, uma imagem

A Ana inicia dois containers a partir da mesma imagem, `one` e `two`, cada um rodando `sleep 600`
para ficar de pé por dez minutos. Depois escreve um arquivo no `one` e o procura nos dois:

```
ana@vm:~$ docker run -d --name one alpine:3.22 sleep 600
168d6c71af1bbf22a78b6993738ab93620a0fd5afaebbe3fe1f8ba0329cbc75f
ana@vm:~$ docker run -d --name two alpine:3.22 sleep 600
4d91949c1548c8c4488de0226a1ad1ba441df613ea281eec912208bb916c4c19
ana@vm:~$ docker exec one sh -c "echo from one > /note"
ana@vm:~$ docker exec one cat /note
from one
ana@vm:~$ docker exec two cat /note
cat: can't open '/note': No such file or directory
```

O arquivo existe no `one` e em nenhum outro lugar. **Cada container ganha a própria camada de escrita
por cima da imagem compartilhada**, e as escritas caem nela. A imagem embaixo nunca é alterada por
um container, e é por isso que cem containers podem partir da mesma imagem sem um atrapalhar o
outro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Embaixo, a imagem alpine:3.22, somente leitura e compartilhada. Acima dela, dois containers, one e two, cada um com sua camada fina de escrita. O arquivo /note existe na camada de escrita do one e não no two.\"><defs><marker id=\"l1layers-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"60\" y=\"190\" width=\"600\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">alpine:3.22</text><text x=\"360\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">imagem: somente leitura, compartilhada pelas duas</text><rect x=\"60\" y=\"30\" width=\"280\" height=\"130\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"74\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">container one</text><rect x=\"80\" y=\"70\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a camada de escrita dele</text><text x=\"200\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">/note</text><path d=\"M200 116 L200 186\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1layers-ah-wire)\"></path><text x=\"210\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lê através</text><rect x=\"380\" y=\"30\" width=\"280\" height=\"130\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"394\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">container two</text><rect x=\"400\" y=\"70\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a camada de escrita dele</text><text x=\"520\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">(vazia)</text><path d=\"M520 116 L520 186\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1layers-ah-wire)\"></path><text x=\"530\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lê através</text></svg>", "caption": "Os dois containers leem a mesma imagem; cada um escreve só na própria camada. A imagem embaixo nunca muda, e é por isso que qualquer número de containers pode partir dela.", "same": ["container one", "container two"]}
```

O `docker ps` mostra os três containers que estão rodando agora, e de que imagem cada um veio:

```
ana@vm:~$ docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
NAMES     IMAGE         STATUS
two       alpine:3.22   Up Less than a second
one       alpine:3.22   Up Less than a second
db        postgres:17   Up 5 seconds
```

## Remover um container deixa a imagem

O `docker rm` remove containers; o `-f` os para antes, se estiverem rodando. A imagem de onde eles
vieram fica:

```
ana@vm:~$ docker rm -f one two db
one
two
db
ana@vm:~$ docker image ls alpine
IMAGE         ID             DISK USAGE   CONTENT SIZE   EXTRA
alpine:3.22   5291449c3df7       12.8MB         3.88MB        
```

Três containers se foram, junto com o arquivo que o `one` escreveu e as tabelas do banco, e a imagem
continua ali para iniciar o próximo. É disso que trata a aula 7 inteira: qualquer coisa que um
container escreve na própria camada vive exatamente o tempo que esse container viver.

## As palavras que o resto do curso usa

| palavra | o que é | onde se ensina |
| --- | --- | --- |
| imagem | um sistema de arquivos somente leitura mais metadados, aquilo de onde containers partem | aqui, e a aula 11 constrói uma |
| container | os arquivos de uma imagem, uma camada de escrita, uma configuração e um processo rodando | aqui |
| Dockerfile | a receita a partir da qual uma imagem é construída | aula 11 |
| registry | um servidor que guarda imagens e as distribui, como o Docker Hub | aula 15 |
| volume | armazenamento que sobrevive aos containers que o usam | aula 8 |
