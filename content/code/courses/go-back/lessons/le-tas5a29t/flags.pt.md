---
title: O pacote flag
version: 1
---

A biblioteca padrão analisa linhas de comando com o `flag`. Um programa pequeno mostra tudo; ele não faz
parte do boxoffice e fica em `~/knobs`:

```go
// knobs/main.go
package main

import (
	"flag"
	"fmt"
	"os"
	"time"
)

func main() {
	addr := flag.String("addr", "localhost:8080", "`address` to listen on")
	conns := flag.Int("max-conns", 10, "most database connections open at once")
	wait := flag.Duration("wait", 0, "how long to keep running before exiting")
	verbose := flag.Bool("v", false, "say more")
	flag.Parse()

	fmt.Println("addr:", *addr, "max-conns:", *conns, "verbose:", *verbose)
	fmt.Println("arguments left:", flag.Args())

	region, set := os.LookupEnv("BOXOFFICE_REGION")
	fmt.Printf("BOXOFFICE_REGION: %q, set: %v\n", region, set)
	time.Sleep(*wait)
}
```

Cada `flag.String`, `flag.Int`, `flag.Duration` e `flag.Bool` declara uma flag com um nome, um padrão e uma
linha de ajuda, e devolve um ponteiro que o `flag.Parse` preenche. A palavra entre crases na ajuda,
`` `address` ``, é o que a ajuda mostra como o tipo de valor que a flag recebe.

```
ana@vm:~/knobs$ go build -o knobs . && ./knobs
addr: localhost:8080 max-conns: 10 verbose: false
arguments left: []
BOXOFFICE_REGION: "", set: false
ana@vm:~/knobs$ ./knobs -addr :9000 -max-conns=20 -v
addr: :9000 max-conns: 20 verbose: true
arguments left: []
BOXOFFICE_REGION: "", set: false
```

Rodado sem nada, todo valor é o padrão. `-addr :9000` e `-max-conns=20` são os dois jeitos de passar um
valor, e uma flag bool sozinha significa true.

## Quando a linha de comando está errada

```
ana@vm:~/knobs$ ./knobs -max-conns ten; echo "exit $?"
invalid value "ten" for flag -max-conns: parse error
Usage of ./knobs:
  -addr address
    	address to listen on (default "localhost:8080")
  -max-conns int
    	most database connections open at once (default 10)
  -v	say more
  -wait duration
    	how long to keep running before exiting
exit 2
ana@vm:~/knobs$ ./knobs -h; echo "exit $?"
Usage of ./knobs:
  -addr address
    	address to listen on (default "localhost:8080")
  -max-conns int
    	most database connections open at once (default 10)
  -v	say more
  -wait duration
    	how long to keep running before exiting
exit 0
```

Um valor que não se analisa para o programa com o motivo, a ajuda inteira e o **status de saída 2**, o
status convencional para "você usou isto errado". `-h`, ou `-help`, imprime a mesma ajuda e sai com 0,
porque pedir ajuda não é erro. O programa não escreveu nada disso; quem escreveu foi o `flag.Parse`, a
partir das declarações, padrões incluídos.

## Três coisas que surpreendem

```
ana@vm:~/knobs$ ./knobs report.csv -v
addr: localhost:8080 max-conns: 10 verbose: false
arguments left: [report.csv -v]
BOXOFFICE_REGION: "", set: false
```

**A análise para no primeiro argumento que não é flag.** `report.csv` não é flag, então o `-v` depois dele
também não é lido como uma; os dois vão parar em `flag.Args()`. Ponha as flags primeiro.

```
ana@vm:~/knobs$ ./knobs -v false -addr :9000
addr: localhost:8080 max-conns: 10 verbose: true
arguments left: [false -addr :9000]
BOXOFFICE_REGION: "", set: false
```

**Uma flag bool só recebe valor com `=`.** `-v false` põe `-v` em true e deixa `false` como argumento, e,
como `false` não é flag, a análise para ali e o `-addr` nunca é lido. O endereço continua o padrão, e
nada reclamou.

```
ana@vm:~/knobs$ ./knobs --addr=:9000 -v=false
addr: :9000 max-conns: 10 verbose: false
arguments left: []
BOXOFFICE_REGION: "", set: false
```

**Dois traços funcionam como um.** `--addr=:9000` e `-addr=:9000` são a mesma flag. O que o pacote não faz
é combinar flags curtas como as ferramentas GNU, `-xvf` significando três flags; ele lê isso como uma flag
chamada `xvf`. Programas que querem esse estilo usam uma biblioteca: o `spf13/pflag` mantém a API do
`flag` com as regras GNU, e o `spf13/cobra`, construído sobre ele, acrescenta subcomandos, como em
`kubectl get pods`. Para um servidor com um punhado de configurações, o `flag` basta.

## Não o conjunto global

`flag.String` e `flag.Parse` usam um conjunto de flags compartilhado pelo programa inteiro, que lê
`os.Args`. Isso serve para o `knobs` e atrapalha num servidor: um teste não consegue lhe passar
argumentos sem mudar `os.Args`, e qualquer pacote que declare uma flag no `init` a acrescenta à ajuda do
seu programa. **`flag.NewFlagSet` cria um conjunto só seu**, analisado a partir de uma fatia que você passa.
A seção 07 usa um para o boxoffice.
