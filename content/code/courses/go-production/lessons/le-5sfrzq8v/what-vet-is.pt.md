---
title: O que o vet é, e o que ele promete
version: 1
---

O compilador responde a uma pergunta: isto é um programa Go? **O `go vet` responde à seguinte: é um
programa Go que faz o que o autor obviamente quis?** Ele lê o mesmo código que o compilador lê, com a
mesma informação de tipos, e procura código válido e quase certamente errado. Um `Printf` cujos verbos
não batem com os argumentos compila. Um mutex copiado por valor também, e uma tag de struct com um
espaço no lugar errado. Cada um deles vai para produção e aparece lá como uma linha errada, um crash
ou um vazamento silencioso.

Comece por algo que deveria estar limpo. O `hits` da lição 1, colocado num diretório só dele,
`~/vet-hits`, com os quatro arquivos que a lição 1 imprime:

```
ana@vm:~/vet-hits$ go vet ./...; echo $?
0
```

**Silêncio e status de saída 0 são a cara de uma execução limpa.** `./...` quer dizer todos os pacotes
do módulo, então isso cobriu `main`, `internal/tally` e `tools/genlog`, arquivos de teste incluídos.
O vet não imprime nada quando não tem nada a dizer, e é isso que deixa um script ou uma etapa de CI
rodá-lo e ler só o código de saída.

## Um bug, duas respostas

O resto desta lição trabalha num módulo próprio, `~/vetted`, criado com
`go mod init example.com/vetted`, em que cada diretório guarda um programinha com um bug. O primeiro é
uma linha que qualquer relatório imprime. Salve como `report/main.go`:

```go
// Command report prints one line about a log: how many requests were slow.
package main

import "fmt"

func main() {
	total, slow := 20000, 1873
	share := 100 * float64(slow) / float64(total)
	fmt.Printf("%d of %d requests were slow (%d%%)\n", slow, total, share)
}
```

O compilador aceita e o programa roda. O vet não aceita:

```
ana@vm:~/vetted$ go run ./report
1873 of 20000 requests were slow (%!d(float64=9.365)%)
ana@vm:~/vetted$ go vet ./report; echo $?
report/main.go:9:43: fmt.Printf format %d has arg share of wrong type float64
1
```

`%!d(float64=9.365)` é o `fmt` dizendo, em tempo de execução, que recebeu um `float64` para um verbo
que quer inteiro. **O compilador não enxerga isso, porque para ele o formato é só uma string**, e o
`Printf` recebe `...any`, então qualquer argumento de qualquer tipo é válido. O vet sabe o que o `fmt`
faz com essa string: ele lê o formato, conta os verbos e confere o tipo de cada argumento com o seu
verbo. A mensagem dá o arquivo, a linha e a coluna, e o status de saída é 1, então um script que roda
`go vet` para aqui. A correção é `%.1f%%`, e o lugar de achá-la era antes de o relatório chegar a
alguém.

## Um conjunto de analisadores, e a régua que eles passam

O vet não é uma checagem só. **É um condutor que roda uma suíte de analisadores independentes sobre
cada pacote**, cada um procurando um tipo de erro, e o `go tool vet help` lista todos. No Go 1.27.1
são 35:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 318\" role=\"img\" aria-label=\"Os 35 analisadores que o go vet roda no Go 1.27.1, em ordem alfabética. Doze deles o go test também roda antes de qualquer teste: atomic, bools, buildtag, directive, errorsas, ifaceassert, nilfunc, printf, slog, stdversion, stringintconv e tests. Os outros 23, entre eles copylocks, lostcancel, structtag, unusedresult, shift, assign e unreachable, só rodam quando se pede o go vet, ou com go test -vet=all.\"><rect x=\"20\" y=\"16\" width=\"22\" height=\"16\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"50\" y=\"25\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">também rodados pelo go test, antes de qualquer teste: 12</text><rect x=\"370\" y=\"16\" width=\"22\" height=\"16\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"25\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">só rodados pelo go vet, ou por go test -vet=all: 23</text><rect x=\"20\" y=\"56\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">appends</text><rect x=\"20\" y=\"92\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">asmdecl</text><rect x=\"20\" y=\"128\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">assign</text><rect x=\"20\" y=\"164\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"82\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">atomic</text><rect x=\"20\" y=\"200\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"82\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">bools</text><rect x=\"20\" y=\"236\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"82\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">buildtag</text><rect x=\"20\" y=\"272\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">cgocall</text><rect x=\"154\" y=\"56\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"216\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">composites</text><rect x=\"154\" y=\"92\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"216\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">copylocks</text><rect x=\"154\" y=\"128\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"216\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">defers</text><rect x=\"154\" y=\"164\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"216\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">directive</text><rect x=\"154\" y=\"200\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"216\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">errorsas</text><rect x=\"154\" y=\"236\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"216\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">framepointer</text><rect x=\"154\" y=\"272\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"216\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">hostport</text><rect x=\"288\" y=\"56\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">httpresponse</text><rect x=\"288\" y=\"92\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"350\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">ifaceassert</text><rect x=\"288\" y=\"128\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">loopclosure</text><rect x=\"288\" y=\"164\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">lostcancel</text><rect x=\"288\" y=\"200\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"350\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">nilfunc</text><rect x=\"288\" y=\"236\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"350\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">printf</text><rect x=\"288\" y=\"272\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">shift</text><rect x=\"422\" y=\"56\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">sigchanyzer</text><rect x=\"422\" y=\"92\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"484\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">slog</text><rect x=\"422\" y=\"128\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">stdmethods</text><rect x=\"422\" y=\"164\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"484\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">stdversion</text><rect x=\"422\" y=\"200\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"484\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">stringintconv</text><rect x=\"422\" y=\"236\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">structtag</text><rect x=\"422\" y=\"272\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">testinggoroutine</text><rect x=\"556\" y=\"56\" width=\"124\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"618\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">tests</text><rect x=\"556\" y=\"92\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"618\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">timeformat</text><rect x=\"556\" y=\"128\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"618\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">unmarshal</text><rect x=\"556\" y=\"164\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"618\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">unreachable</text><rect x=\"556\" y=\"200\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"618\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">unsafeptr</text><rect x=\"556\" y=\"236\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"618\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">unusedresult</text><rect x=\"556\" y=\"272\" width=\"124\" height=\"28\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"618\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">waitgroup</text></svg>", "caption": "Os 35 analisadores do go vet no Go 1.27.1. Os doze em negrito e com contorno são os que o go test roda antes; sete dos oito bugs da seção 03 só são achados pelos outros 23."}
```

Cada um deles passou pela mesma régua de três partes, que o próprio `cmd/vet/README` do toolchain
registra, e é ela que diferencia o vet dos linters da lição 8:

| critério | o que ele exige de uma checagem |
|---|---|
| **correção** | achar bugs reais ou possíveis, nunca estilo nem outra forma correta de escrever a mesma coisa |
| **frequência** | o erro ser comum o bastante para valer a pena rodar em todo build de todo mundo |
| **precisão** | alarmes falsos e omissões serem ambos raros, para que tudo o que ela relata valha a leitura |

**O terceiro critério é o motivo de você poder transformar o vet numa barreira.** Uma ferramenta que
grita "lobo" acaba desligada; uma ferramenta em que cada linha vale a leitura pode reprovar um build.
O README é explícito sobre o preço: muitas checagens foram propostas e recusadas, inclusive de bugs
reais que eram raros demais para valer o tempo de build de todo mundo. A lição 8 é onde ficam as
ferramentas que fazem a outra troca.

## Um analisador lê a linha `go`

A régua tem uma consequência fácil de não ver: **um analisador sabe para qual versão do Go um arquivo
foi escrito**, pela linha `go` do `go.mod`, e uma checagem cujo bug a linguagem corrigiu fica quieta. O
`loopclosure` é o caso mais claro. Antes do Go 1.22, todas as iterações de um laço `for` dividiam uma
variável só, e uma goroutine iniciada no laço via o valor que ela tivesse quando a goroutine
conseguisse lê-la. Um módulo próprio, `~/oldloop`, criado com `go mod init example.com/oldloop`, com
um arquivo, `main.go`:

```go
// Command oldloop prints three paths from three goroutines.
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	for _, p := range []string{"/", "/login", "/health"} {
		wg.Add(1)
		go func() {
			defer wg.Done()
			fmt.Println(p)
		}()
	}
	wg.Wait()
}
```

O `go mod edit -go=1.21` reescreve a linha `go`, o que diz ao compilador para dar ao arquivo a
semântica antiga do laço, e depois o mesmo arquivo de novo com 1.27.1. A saída passa pelo `sort`
porque três goroutines imprimem na ordem em que rodam:

```
ana@vm:~/oldloop$ go mod edit -go=1.21 && go vet .
main.go:15:16: loop variable p captured by func literal
ana@vm:~/oldloop$ go run . | sort
/health
/health
/health
ana@vm:~/oldloop$ go mod edit -go=1.27.1 && go vet . && go run . | sort
/
/health
/login
```

Com `go 1.21` as três goroutines imprimiram o último caminho, e o vet tinha avisado antes de o
programa rodar. Com `go 1.27.1` cada iteração tem seu próprio `p`, o programa está certo, e **o vet
não diz nada, porque não sobrou nada a dizer**. O `loopclosure` continua na lista, continua rodando e
só relata em arquivos que declaram um Go anterior ao 1.22. A checagem de `%w` da seção 03 vai no
sentido contrário: só vale para arquivos que declaram pelo menos 1.27.
