---
title: Conferindo todas as plataformas numa máquina só
version: 1
---

O `go build` nesta máquina compila os arquivos que um build Linux em `amd64` seleciona, sem tags, e
**nada mais**. Toda outra combinação de sistema, processador e tags é outro programa, feito de outro
conjunto de arquivos, e nenhuma delas é conferida pelo build daqui. O `hits` agora tem três arquivos
por sistema e um com tag, então já é vários programas, e o `go list` da seção 03 sabe dizer quais.

## Um build é uma coluna

O mesmo `go list` para quatro alvos, e mais uma vez com a tag:

```
ana@vm:~/tags$ for t in linux/amd64 darwin/arm64 windows/amd64 freebsd/amd64; do echo "$t: $(GOOS=${t%/*} GOARCH=${t#*/} go list -f '{{.GoFiles}}' .)"; done
linux/amd64: [main.go progress.go progress_unix.go]
darwin/arm64: [main.go progress.go progress_darwin.go]
windows/amd64: [main.go progress.go progress_other.go]
freebsd/amd64: [main.go progress.go progress_unix.go]
ana@vm:~/tags$ GOOS=windows go list -tags debug -f '{{.GoFiles}}' .
[debug.go main.go progress.go progress_other.go]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 346\" role=\"img\" aria-label=\"Uma tabela com seis arquivos do pacote main contra cinco builds. main.go e progress.go são compilados por todos os builds. progress_unix.go é compilado para linux/amd64 e freebsd/amd64, progress_darwin.go só para darwin/arm64, e progress_other.go para windows/amd64, com e sem a tag debug. debug.go só é compilado pelo build windows/amd64 com -tags debug. Cada build sem tags compila três arquivos, e o build com a tag, quatro.\"><text x=\"360\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">quais arquivos cada build compila, segundo o go list</text><text x=\"250.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">linux/amd64</text><text x=\"250.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem tags</text><text x=\"350.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">darwin/arm64</text><text x=\"350.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem tags</text><text x=\"450.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">windows/amd64</text><text x=\"450.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem tags</text><text x=\"550.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">freebsd/amd64</text><text x=\"550.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem tags</text><text x=\"650.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">windows/amd64</text><text x=\"650.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">-tags debug</text><path d=\"M600 36 V282\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\" fill=\"none\"></path><rect x=\"20\" y=\"92\" width=\"576\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><rect x=\"604\" y=\"92\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><text x=\"32\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main.go</text><rect x=\"228.0\" y=\"97.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"328.0\" y=\"97.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"428.0\" y=\"97.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"528.0\" y=\"97.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"628.0\" y=\"97.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"122\" width=\"576\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><rect x=\"604\" y=\"122\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><text x=\"32\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">progress.go</text><rect x=\"228.0\" y=\"127.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"328.0\" y=\"127.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"428.0\" y=\"127.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"528.0\" y=\"127.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"628.0\" y=\"127.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"152\" width=\"576\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><rect x=\"604\" y=\"152\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><text x=\"32\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">progress_unix.go</text><rect x=\"228.0\" y=\"157.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M342.0 165.0 H358.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M442.0 165.0 H458.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"528.0\" y=\"157.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M642.0 165.0 H658.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"182\" width=\"576\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><rect x=\"604\" y=\"182\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><text x=\"32\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">progress_darwin.go</text><path d=\"M242.0 195.0 H258.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"328.0\" y=\"187.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M442.0 195.0 H458.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M542.0 195.0 H558.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M642.0 195.0 H658.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"212\" width=\"576\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><rect x=\"604\" y=\"212\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><text x=\"32\" y=\"225.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">progress_other.go</text><path d=\"M242.0 225.0 H258.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M342.0 225.0 H358.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"428.0\" y=\"217.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M542.0 225.0 H558.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"628.0\" y=\"217.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"242\" width=\"576\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><rect x=\"604\" y=\"242\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"none\"></rect><text x=\"32\" y=\"255.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">debug.go</text><path d=\"M242.0 255.0 H258.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M342.0 255.0 H358.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M442.0 255.0 H458.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M542.0 255.0 H558.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"628.0\" y=\"247.0\" width=\"44\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 arquivos</text><text x=\"350.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 arquivos</text><text x=\"450.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 arquivos</text><text x=\"550.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 arquivos</text><text x=\"650.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 arquivos</text><rect x=\"32\" y=\"318\" width=\"30\" height=\"16\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"326\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">compilado por esse build</text><path d=\"M232 326 H248\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"258\" y=\"326\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">deixado de fora por uma restrição</text></svg>", "caption": "Um build é uma coluna. O programa inteiro são todas as linhas, e nenhum build sozinho compila tudo."}
```

**Nenhum build compila os seis arquivos.** Cada um dos quatro alvos sem tags compilou três deles, e
o build Windows com a tag, quatro. FreeBSD e Linux pegaram os mesmos arquivos, por causa de
`unix && !darwin`. Um erro em `progress_other.go` não pode aparecer na primeira coluna, e um em
`debug.go` só pode aparecer na última, então quem desenvolve no Linux e compila e testa sem tags
conferiu uma coluna de cinco.

`GOOS` e `GOARCH` definidos para um comando fazem `go list`, `go vet` e `go build` trabalharem como
trabalhariam naquela máquina, sem gerar nada que precise rodar aqui. Isso transforma cada coluna num
comando:

```
ana@vm:~/tags$ for t in linux/amd64 linux/arm64 darwin/arm64 windows/amd64 freebsd/amd64; do GOOS=${t%/*} GOARCH=${t#*/} go vet ./... && echo "ok  $t"; done
ok  linux/amd64
ok  linux/arm64
ok  darwin/arm64
ok  windows/amd64
ok  freebsd/amd64
```

Cinco alvos, todos limpos. **O `go vet` serve melhor para isso que o `go build`**: ele checa os tipos
de todo pacote junto com os arquivos de teste, que o `go build` pula, roda as checagens do vet sobre
eles e nunca precisa ligar um binário. A falha de Windows da seção 02 teria sido pega pela linha
`windows/amd64` deste loop.

## O loop que não basta

O build de debug da seção 04 seria mais útil se também dissesse como pedir o progresso, o que depende
do sistema. A dica fica ao lado dos sinais que ela descreve, para os dois não se desencontrarem. Uma
primeira tentativa muda o `progress_unix.go`, o arquivo desta máquina:

```go
//go:build unix && !darwin

package main

import (
	"os"
	"syscall"
)

// On Linux and the other Unix systems, kill -USR1 asks for progress.
var progressSignals = []os.Signal{syscall.SIGUSR1}

const progressHint = "kill -USR1 prints progress"
```

e faz o `debug.go` imprimi-la na partida, com o número do processo de que o `kill` precisa:

```go
//go:build debug

package main

import (
	"fmt"
	"io"
	"os"
)

func init() {
	debugf = func(w io.Writer, format string, a ...any) {
		fmt.Fprintf(w, "hits: debug: "+format+"\n", a...)
	}
	debugf(os.Stderr, "pid %d: %s", os.Getpid(), progressHint)
}
```

Nesta máquina, o build de debug funciona:

```
ana@vm:~/tags$ go build -tags debug -o hits-debug . && ./hits-debug top -n 1 access.log
hits: debug: 20000 lines, 914867 bytes in 5.420602ms
path    requests
/login  2576
```

E o loop sobre os alvos, rodado de novo:

```
ana@vm:~/tags$ for t in linux/amd64 linux/arm64 darwin/arm64 windows/amd64 freebsd/amd64; do GOOS=${t%/*} GOARCH=${t#*/} go vet ./... && echo "ok  $t"; done
ok  linux/amd64
ok  linux/arm64
ok  darwin/arm64
ok  windows/amd64
ok  freebsd/amd64
```

**Cinco alvos, todos limpos, e o código está quebrado em dois deles.** `progressHint` só existe em
`progress_unix.go`, então um build de debug para macOS ou Windows não compila. O loop não viu porque
o único arquivo que usa `progressHint` é o `debug.go`, e o loop rodou sem a tag. Ele conferiu cinco
colunas de uma tabela que tem quinze.

## Todo alvo com toda tag

Um loop sobre os dois, como um script que pode morar num repositório e rodar no CI, `check.sh`:

```schooling-example
{
  "language": "sh",
  "file": "check.sh",
  "parts": [
    {
      "code": "#!/bin/sh\n# check.sh vets every package for each target, with each set of tags.\nset -u",
      "note": "Um script de shell POSIX, rodado com `sh check.sh`. **O `set -u` o interrompe numa variável usada sem valor**; o `set -e` ficou de fora de propósito, porque aqui uma falha é algo a informar e seguir em frente, não motivo para parar."
    },
    {
      "code": "targets=\"linux/amd64 linux/arm64 darwin/arm64 windows/amd64 freebsd/amd64\"\nstatus=0",
      "note": "Os alvos, escritos como o `go tool dist list` os escreve. O FreeBSD está ali embora ninguém distribua o `hits` para ele, porque é o Unix que pega o `progress_unix.go` sem ser Linux."
    },
    {
      "code": "for t in $targets; do\n\tfor tags in \"\" debug integration; do",
      "note": "**Todo alvo com todo conjunto de tags**: nenhuma, `debug` e `integration`, os três jeitos como este módulo é compilado. `${t%/*}` e `${t#*/}` dividem `linux/amd64` nas duas metades."
    },
    {
      "code": "\t\tif out=$(GOOS=${t%/*} GOARCH=${t#*/} go vet -tags \"$tags\" ./... 2>&1); then\n\t\t\techo \"ok    $t -tags '$tags'\"\n\t\telse\n\t\t\techo \"FAIL  $t -tags '$tags'\"\n\t\t\techo \"$out\" | sed 's/^/      /'\n\t\t\tstatus=1\n\t\tfi\n\tdone\ndone",
      "note": "O `go vet` checa os tipos de todo pacote e dos arquivos de teste, que o `go build` pula, e roda as checagens do vet sobre eles; ele nunca liga um binário. A saída fica guardada em `out` e só é impressa em caso de falha, recuada sob a linha que nomeia o alvo."
    },
    {
      "code": "exit $status",
      "note": "O status de saída é 1 se alguma combinação falhou, então um passo de CI que roda `sh check.sh` falha junto."
    }
  ]
}
```

Rodando:

```
ana@vm:~/tags$ sh check.sh; echo $?
ok    linux/amd64 -tags ''
ok    linux/amd64 -tags 'debug'
ok    linux/amd64 -tags 'integration'
ok    linux/arm64 -tags ''
ok    linux/arm64 -tags 'debug'
ok    linux/arm64 -tags 'integration'
ok    darwin/arm64 -tags ''
FAIL  darwin/arm64 -tags 'debug'
      # example.com/hits
      # [example.com/hits]
      vet: ./debug.go:15:47: undefined: progressHint
ok    darwin/arm64 -tags 'integration'
ok    windows/amd64 -tags ''
FAIL  windows/amd64 -tags 'debug'
      # example.com/hits
      # [example.com/hits]
      vet: ./debug.go:15:47: undefined: progressHint
ok    windows/amd64 -tags 'integration'
ok    freebsd/amd64 -tags ''
ok    freebsd/amd64 -tags 'debug'
ok    freebsd/amd64 -tags 'integration'
1
```

**Treze combinações passaram e duas falharam**, com a mensagem do vet embaixo de cada uma: macOS e
Windows, com `-tags debug`. O status de saída é 1. A correção é a linha que falta nos outros dois
arquivos por sistema. `progress_darwin.go`:

```go
package main

import (
	"os"
	"syscall"
)

// On macOS, Ctrl-T in the terminal sends SIGINFO, and kill -USR1 works too.
var progressSignals = []os.Signal{syscall.SIGINFO, syscall.SIGUSR1}

const progressHint = "Ctrl-T prints progress"
```

e `progress_other.go`:

```go
//go:build !unix

package main

import "os"

// Windows and the other systems have no signal for this.
var progressSignals []os.Signal

const progressHint = "no signal prints progress on this system"
```

```
ana@vm:~/tags$ sh check.sh > /dev/null && echo "all 15 passed"
all 15 passed
```

Quinze execuções são cinco alvos vezes três jeitos de compilar. Tags que podem se combinar
multiplicam a conta: duas tags independentes são quatro builds por alvo, três são oito. Na prática
um projeto confere cada tag sozinha e as combinações que de fato distribui, e escreve essa lista num
script como este, porque uma lista num script é conferida a cada mudança e uma lista na cabeça de
alguém não é.

## O que o vet não sabe dizer

O `check.sh` prova que toda combinação **compila** e passa nas checagens do vet. Não prova que alguma
delas funciona. O build de macOS nunca rodou, nem aqui nem em lugar nenhum deste curso, e se o Ctrl-T
chega ao `hits` num Mac é uma afirmação que só um Mac pode conferir. A aula 16 roda o build Linux
`arm64` num emulador e os testes dele com `go test -exec`; macOS e Windows precisam de uma máquina
própria, o que para a maioria dos projetos quer dizer um runner de CI por sistema. O que o loop
compra é que um runner desses nunca falhe na manhã de uma versão por causa de um nome que só existe
num sistema.
