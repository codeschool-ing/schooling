---
title: O que foi instalado, e onde fica
version: 1
---

Descompactar o arquivo põe um programa no disco. Não transforma `go` num comando. **O seu shell só
executa um comando quando ele está num dos diretórios listados no `PATH`**, e `/usr/local/go/bin`
não está em nenhum deles até você acrescentá-lo. O lugar de costume é o `~/.profile`, que o shell
lê toda vez que você faz login. A Ana acrescentou duas linhas:

```
ana@vm:~/setup$ echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
ana@vm:~/setup$ echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.profile
ana@vm:~/setup$ tail -2 ~/.profile
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin
```

As aspas simples mantêm `$PATH` e `$HOME` como foram escritos, então o arquivo guarda a receita e
não o valor de hoje. A primeira linha serve para `go` e `gofmt`. A segunda serve para os programas
que **você** gera com `go install`, que vão parar em `~/go/bin`; foi essa linha que fez o `hello`
rodar pelo nome a partir de `~` na lição 4.

O arquivo vale a partir do próximo login. Para ver o que um login novo recebe, sem sair da sessão,
comece de um `PATH` que não sabe nada de Go e leia o arquivo com `.`:

```
ana@vm:~/setup$ PATH=/usr/bin:/bin; . ~/.profile; echo $PATH; command -v go gofmt
/usr/bin:/bin:/usr/local/go/bin:/home/ana/go/bin
/usr/local/go/bin/go
/usr/local/go/bin/gofmt
```

Os dois diretórios chegaram ao fim do `PATH`, e o `command -v` diz qual arquivo o shell
executaria para cada palavra. **Se `command -v go` não imprimir nada, nada mais neste curso vai
funcionar**, e a seção 05 começa justamente aí.

## Onde o comando go guarda as coisas

O `go env` imprime as configurações do comando go, e, recebendo nomes, imprime só essas. Cinco
delas dizem onde tudo fica:

```
ana@vm:~/setup$ go env GOROOT GOPATH GOBIN GOMODCACHE GOCACHE
/usr/local/go
/home/ana/go
/home/ana/go/bin
/home/ana/go/pkg/mod
/home/ana/.cache/go-build
```

Ninguém definiu nenhuma delas. Cada uma é um padrão que o comando go deduziu de onde foi instalado
e do diretório pessoal da Ana. Desenhadas, são três diretórios com três funções diferentes:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Onde uma instalação de Go guarda as coisas. GOROOT, /usr/local/go, guarda o toolchain: go, gofmt e o código-fonte da biblioteca padrão, trocado inteiro numa atualização. GOPATH, ~/go, guarda bin, onde o go install põe programas, e pkg/mod, os módulos baixados, só leitura. GOCACHE, ~/.cache/go-build, guarda pacotes compilados e pode ser esvaziado. O PATH aponta para /usr/local/go/bin e ~/go/bin. O seu próprio código fica em qualquer outro lugar.\"><defs><marker id=\"gr-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">PATH</text><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o shell só encontra comandos nestes dois</text><rect x=\"20\" y=\"70\" width=\"210\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">GOROOT</text><text x=\"125\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/usr/local/go</text><rect x=\"40\" y=\"124\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bin/  go  gofmt</text><text x=\"125\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o toolchain</text><text x=\"125\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">go, gofmt e o código-fonte</text><text x=\"125\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">da biblioteca padrão</text><text x=\"125\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">trocado inteiro numa atualização</text><rect x=\"255\" y=\"70\" width=\"210\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">GOPATH</text><text x=\"360\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/go</text><rect x=\"275\" y=\"124\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bin/   (GOBIN)</text><text x=\"360\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">programas que o go install gerou</text><rect x=\"275\" y=\"180\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pkg/mod/   (GOMODCACHE)</text><text x=\"360\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">módulos baixados, só leitura</text><rect x=\"490\" y=\"70\" width=\"210\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">GOCACHE</text><text x=\"595\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~/.cache/go-build</text><text x=\"595\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pacotes compilados</text><text x=\"595\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pode esvaziar: go clean -cache</text><path d=\"M360 48 V56 M200 56 H420\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M200 56 V122\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gr-phosphor)\"></path><path d=\"M420 56 V122\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gr-phosphor)\"></path><rect x=\"20\" y=\"256\" width=\"680\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o seu código: em qualquer lugar, como ~/hello, ~/setup-work</text></svg>", "caption": "Três diretórios que pertencem ao comando go, e os dois diretórios bin que o PATH precisa citar. O seu código não está em nenhum deles."}
```

`GOROOT` é o toolchain da seção 02, e você nunca escreve nele. `GOPATH` é `~/go`, e dois outros
valores ficam dentro dele: `GOBIN`, onde o `go install` põe programas, e `GOMODCACHE`, onde os
módulos baixados ficam guardados, descompactados e só para leitura, da lição 38 em diante. `GOCACHE`
é o cache de build que fez o segundo `go run` da lição 4 levar 44 milissegundos. **Tudo o que está
em `GOPATH` e em `GOCACHE` pode ser apagado e volta quando for preciso**, ao preço de um download
ou de uma recompilação: `go clean -cache` esvazia um e `go clean -modcache` o outro.

## Um programa, muitos comandos

`go` é um programa só, e a palavra depois dele escolhe o que ele faz. O `go help` lista as
palavras:

```
ana@vm:~/setup$ go help | head -27
Go is a tool for managing Go source code.

Usage:

	go <command> [arguments]

The commands are:

	bug         start a bug report
	build       compile packages and dependencies
	clean       remove object files and cached files
	doc         show documentation for package or symbol
	env         print Go environment information
	fix         apply fixes suggested by static checkers
	fmt         gofmt (reformat) package sources
	generate    generate Go files by processing source
	get         add dependencies to current module and install them
	install     compile and install packages and dependencies
	list        list packages or modules
	mod         module maintenance
	run         compile and run Go program
	telemetry   manage telemetry data and settings
	test        test packages
	tool        run specified go tool
	version     print Go version
	vet         report likely mistakes in packages
	work        workspace maintenance
```

Você já viu seis delas na lição 4: `run`, `build`, `install`, `doc`, `fmt` e `vet`. `work` é a
seção 04 desta lição, `mod` é a lição 38 e `get` a lição 40; `test` é do curso `go-concurrency`.
`go help` seguido de qualquer uma dessas palavras imprime o manual completo dela, e o resto da
lista, que o `head` cortou, são tópicos como `go help gopath`.

## Configurações, e quem vence

Uma configuração pode vir de três lugares, e **o comando go os lê numa ordem fixa, e o último
vence**. Primeiro o arquivo `go.env` dentro do `GOROOT`, que vem com a versão. Depois um arquivo
seu, escrito pelo `go env -w`. Depois o ambiente do shell, que ganha dos dois. O `go env -changed`
lista o que difere dos padrões:

```
ana@vm:~/setup$ go env -changed
GOTOOLCHAIN='local'
ana@vm:~/setup$ grep -v "^#" /usr/local/go/go.env

GOPROXY=https://proxy.golang.org,direct
GOSUMDB=sum.golang.org

GOTOOLCHAIN=auto
ana@vm:~/setup$ go env -w GOTOOLCHAIN=auto
warning: go env -w GOTOOLCHAIN=... does not override conflicting OS environment variable
ana@vm:~/setup$ cat ~/.config/go/env
GOTOOLCHAIN=auto
ana@vm:~/setup$ go env GOTOOLCHAIN
local
ana@vm:~/setup$ go env -u GOTOOLCHAIN
```

A versão diz `GOTOOLCHAIN=auto`: quando um módulo pede um Go mais novo, baixe-o, que é o assunto
da lição 2. O ambiente do laboratório diz `local`, para que toda transcrição deste curso venha da
1.27.1 e de nada mais. O `go env -w` escreveu `auto` no arquivo da própria Ana e avisou, no mesmo
fôlego, que isso não faria diferença; o `go env GOTOOLCHAIN` confirma que o ambiente venceu. O
`go env -u` tirou a linha de novo.

Dois outros padrões do `go.env` importam na seção 05. `GOPROXY` é de onde os módulos são baixados,
primeiro o proxy e depois o próprio repositório do módulo, e `GOSUMDB` é o banco de checksums que
confirma que um download é o mesmo que todo mundo recebeu.
