---
title: O `go install` e as ferramentas que você não escreveu
version: 1
---

O `go install` é um `go build` com destino fixo. **Ele constrói o mesmo executável e o coloca num
diretório só, o que o `GOBIN` indica**, e nada muda no diretório atual. Esse diretório está no seu
`PATH` desde a lição 3 do `go`, então o que cai ali vira um comando que você digita de qualquer
lugar. O mesmo comando baixa e constrói programas que outras pessoas escreveram, e o jeito como faz
isso ignora de propósito o módulo em que você está.

## O seu programa, no `PATH`

```
ana@vm:~/daily$ go env GOBIN GOPATH
/home/ana/go/bin
/home/ana/go
ana@vm:~/daily$ go install . && command -v hits
/home/ana/go/bin/hits
ana@vm:~/daily$ cd /tmp && hits top -n 2 ~/daily/access.log
path         requests
/login       2576
/api/orders  2542
ana@vm:~/daily$ go version -m ~/go/bin/hits | head -3
/home/ana/go/bin/hits: go1.27.1
	path	example.com/hits
	mod	example.com/hits	(devel)	
```

O `GOBIN` nunca foi definido nesta máquina, e o `go env` imprimiu o valor que vale no lugar dele: o
diretório `bin` dentro do `GOPATH`, `/home/ana/go/bin`. **Defina o `GOBIN` e todo `go install`
passa a escrever ali**, que é como uma equipe mantém as ferramentas num diretório do próprio
projeto. O executável recebe o nome do caminho de importação, exatamente como o `go build` sem
argumentos da seção 02 o nomeou, e a partir de `/tmp` respondeu como qualquer outro comando.

O `go version -m` lê o que o comando go gravou num binário ao construí-lo: a versão do Go, o caminho
do pacote e o módulo. **`(devel)` é a versão de um módulo compilado a partir de um diretório, e não
baixado numa versão**; um módulo buscado numa versão carrega essa versão, como o `stringer` faz mais
abaixo. O resto da listagem, cortado pelo `head` aqui, são as configurações do build:
`CGO_ENABLED`, `GOOS`, `GOARCH`. Ela responde "que binário é este, e como foi construído" meses
depois, numa máquina em que ninguém se lembra.

## Uma ferramenta de outro lugar, numa versão

O `stringer` é um gerador de código do módulo `golang.org/x/tools`, o tipo de programa que o
`go generate` da lição 10 roda. Instalá-lo de dentro de `~/daily` mostra a regra:

```
ana@vm:~/daily$ go install golang.org/x/tools/cmd/stringer
no required module provides package golang.org/x/tools/cmd/stringer; to add it:
	go get golang.org/x/tools/cmd/stringer
ana@vm:~/daily$ go install golang.org/x/tools/cmd/stringer@v0.52.0
go: downloading golang.org/x/tools v0.52.0
go: downloading golang.org/x/sync v0.24.0
go: downloading golang.org/x/mod v0.42.0
ana@vm:~/daily$ cat go.mod
module example.com/hits

go 1.27.1
ana@vm:~/daily$ command -v stringer && go version -m $(command -v stringer) | head -5
/home/ana/go/bin/stringer
/home/ana/go/bin/stringer: go1.27.1
	path	golang.org/x/tools/cmd/stringer
	mod	golang.org/x/tools	v0.52.0	h1:ryxg4U63oaUYk7uOLTF37n43f4qgtGvqV4Ioit1BaEs=
	dep	golang.org/x/mod	v0.42.0	h1:ICeL3t2L30ljSPHHxDnR4fqVcBt/zR2zJAb9juavmQg=
	dep	golang.org/x/sync	v0.24.0	h1:iqiDrGoDgyuvAKrhLQthUEzU/R378N78gXbBjxed7oA=
```

Sem versão, o `go install` compila **no contexto do módulo atual**: procura `golang.org/x/tools`
entre as dependências do `go.mod`, não acha nenhuma e se recusa, indicando o `go get` que a
acrescentaria. **Com `@v0.52.0` ele ignora o `go.mod` por completo.** Baixa essa versão do módulo e
as versões que o próprio módulo exige, constrói o `stringer` e o coloca no `GOBIN`. O `go.mod` fica
intocado, como o `cat` mostra, e o `go version -m` nomeia os três módulos que entraram no binário,
com o checksum de cada um.

A separação é proposital. Uma ferramenta que você roda sobre um projeto não é dependência do código
do projeto, e colocá-la no `go.mod` faria o `example.com/hits` exigir `golang.org/x/tools` sem
nenhum motivo vindo dos seus pacotes. O `go help install` lista as condições: todos os argumentos
têm a mesma versão, os pacotes precisam ser pacotes `main` de um único módulo, e as diretivas
`replace` desse módulo não são permitidas. É isso que torna o build o mesmo em toda máquina que pedir
aquela versão. O `@latest` também funciona, e é o que um experimento rápido usa; **uma versão
escrita é o que um `Makefile` ou um passo de CI deve usar**, porque `@latest` quer dizer outro
programa no mês que vem. O `go run golang.org/x/tools/cmd/stringer@v0.52.0` faz o mesmo sem guardar
o executável.

O outro jeito de fixar uma ferramenta é torná-la parte do módulo de propósito. O `go get -tool` a
registra no `go.mod` com uma linha `tool`, e o `go tool stringer` passa a rodá-la exatamente na
versão que o módulo exige. Isso serve para uma ferramenta que a equipe inteira precisa rodar igual,
ao preço de as dependências da ferramenta aparecerem no `go.mod`.

## Tirando de novo

O `go clean -i` remove o que o `go install` colocou no `GOBIN`. O `-n` imprime os comandos sem
executá-los, que é o jeito seguro de ler o que um `clean` vai fazer:

```
ana@vm:~/daily$ go clean -i -n .
rm -f /home/ana/daily/hits
rm -f /home/ana/go/bin/hits
ana@vm:~/daily$ go clean -i . ; command -v hits; echo $?
1
```

Ele remove dois arquivos: o `hits` que um `go build` sem argumentos deixa no diretório do pacote, e
o que está no `GOBIN`. O `command -v` então não acha nada e devolve 1. **O `go clean -i` só funciona
com pacotes do módulo atual**: pedido para `golang.org/x/tools/cmd/stringer`, ele responde com a
mesma recusa "no required module" do `go install` acima, então uma ferramenta instalada numa versão
se remove com `rm`.

Este é o tráfego completo dos quatro comandos de que esta lição trata, com as contagens que esta
seção e a seção 02 mediram. Os resultados de teste, embaixo, são o assunto da seção 04:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O que o comando go lê, guarda e escreve. Ele lê o seu módulo, a biblioteca padrão em /usr/local/go/src e os módulos baixados em ~/go/pkg/mod. Guarda pacotes compilados, executáveis do go run e resultados de teste no cache de build, ~/.cache/go-build: 79 pacotes compilados para o hits, 43 MB a partir de um cache vazio. go build -o hits escreve ./hits, go install escreve no GOBIN, ~/go/bin, go run roda o executável que guardou, e go test imprime ok ou (cached).\"><defs><marker id=\"b5-arrow\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"115\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que ele lê</text><text x=\"360\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que ele guarda</text><text x=\"605\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que ele escreve</text><rect x=\"20\" y=\"50\" width=\"190\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o seu módulo</text><text x=\"115\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/daily</text><text x=\"115\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">arquivos .go e go.mod</text><path d=\"M210 83 H262\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#b5-arrow)\"></path><rect x=\"20\" y=\"136\" width=\"190\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a biblioteca padrão</text><text x=\"115\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/usr/local/go/src</text><path d=\"M210 169 H262\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#b5-arrow)\"></path><rect x=\"20\" y=\"222\" width=\"190\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o cache de módulos</text><text x=\"115\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/go/pkg/mod</text><text x=\"115\" y=\"273\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">módulos baixados</text><path d=\"M210 255 H262\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#b5-arrow)\"></path><rect x=\"265\" y=\"50\" width=\"190\" height=\"238\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">GOCACHE</text><text x=\"360\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/.cache/go-build</text><rect x=\"280\" y=\"100\" width=\"160\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pacotes compilados</text><text x=\"360\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">79 para o hits: 43 MB a frio</text><rect x=\"280\" y=\"164\" width=\"160\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">executáveis do go run</text><text x=\"360\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ligados uma vez, reusados</text><rect x=\"280\" y=\"228\" width=\"160\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">resultados de teste</text><text x=\"360\" y=\"261\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">impressos como (cached)</text><rect x=\"510\" y=\"50\" width=\"190\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">go build -o hits</text><text x=\"605\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">./hits, onde o -o mandar</text><rect x=\"510\" y=\"112\" width=\"190\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">go install</text><text x=\"605\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o diretório que o GOBIN aponta</text><rect x=\"510\" y=\"174\" width=\"190\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">go run</text><text x=\"605\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roda a cópia do cache</text><rect x=\"510\" y=\"236\" width=\"190\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">go test</text><text x=\"605\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ok, ou (cached)</text><path d=\"M440 118 H475 V76 H507\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#b5-arrow)\"></path><path d=\"M440 130 H475 V138 H507\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#b5-arrow)\"></path><path d=\"M440 188 H475 V200 H507\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#b5-arrow)\"></path><path d=\"M440 252 H475 V262 H507\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#b5-arrow)\"></path></svg>", "caption": "Todo build passa pelo cache. Um arquivo só aparece fora dele onde o go build -o ou o go install o colocam."}
```
