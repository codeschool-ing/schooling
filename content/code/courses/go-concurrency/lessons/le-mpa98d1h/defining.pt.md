---
title: Definir flags e lê-las
version: 1
---

Um programa que lê as suas configurações do próprio código-fonte precisa ser recompilado para
mudar uma delas. **O pacote `flag` transforma as palavras depois do nome de um comando em valores
com tipo**, com padrões, um texto de ajuda escrito para você e um erro quando um valor não é o que o
programa pediu. É o que o próprio comando go usa, e basta para a maioria das ferramentas que um
time escreve.

Todo programa desta lição mora num diretório próprio dentro de `~/flags`, um módulo só para todos.
O primeiro diz olá, salvo como `greet/main.go`:

```go
// Command greet says hello, as many times as it is told.
package main

import (
	"flag"
	"fmt"
	"strings"
	"time"
)

func main() {
	name := flag.String("name", "world", "who to greet")
	times := flag.Int("times", 1, "how many greetings")
	shout := flag.Bool("shout", false, "greet in capitals")
	pause := flag.Duration("pause", 0, "wait between greetings")
	flag.Parse()

	msg := "hello, " + *name
	if *shout {
		msg = strings.ToUpper(msg)
	}
	for i := range *times {
		if i > 0 {
			time.Sleep(*pause)
		}
		fmt.Println(msg)
	}
	fmt.Println("left over:", flag.Args())
}
```

**Cada `flag.String`, `flag.Int`, `flag.Bool` e `flag.Duration` declara uma flag e devolve um
ponteiro** para onde o valor dela vai ficar: um nome, um padrão e uma linha de ajuda. Nada é lido
até `flag.Parse`, que percorre a linha de comando, preenche os ponteiros e para na primeira
palavra que não é flag. O que sobra é `flag.Args()`. O programa lê `*name` e `*times` depois
disso, nunca antes.

Um `go build` faz os três programas da lição, em `bin`:

```
ana@vm:~/flags$ go build -o bin/ ./...
ana@vm:~/flags$ ls bin
greet
tags
tool
```

Depois, as flags trabalhando:

```
ana@vm:~/flags$ bin/greet
hello, world
left over: []
ana@vm:~/flags$ bin/greet -name=bia -times 2
hello, bia
hello, bia
left over: []
ana@vm:~/flags$ bin/greet -shout -name caio extra words
HELLO, CAIO
left over: [extra words]
ana@vm:~/flags$ time bin/greet -times 3 -pause 1s
hello, world
hello, world
hello, world
left over: []

real	0m2.003s
user	0m0.000s
sys	0m0.003s
```

`-name=bia` e `-name bia` são a mesma coisa, assim como um traço e dois. A flag de duração lê a
notação da lição 20, então `-pause 1s` pôs um segundo entre as saudações, e as três saudações
levaram dois segundos de tempo real. `extra words` não eram flags, então o `Parse` as deixou em
`flag.Args()`.

## A ajuda, e a recusa

Ninguém escreveu um texto de ajuda, e existe um:

```
ana@vm:~/flags$ bin/greet -h; echo $?
Usage of bin/greet:
  -name string
    	who to greet (default "world")
  -pause duration
    	wait between greetings
  -shout
    	greet in capitals
  -times int
    	how many greetings (default 1)
0
ana@vm:~/flags$ bin/greet -times=two; echo $?
invalid value "two" for flag -times: parse error
Usage of bin/greet:
  -name string
    	who to greet (default "world")
  -pause duration
    	wait between greetings
  -shout
    	greet in capitals
  -times int
    	how many greetings (default 1)
2
```

**`-h` imprime toda flag com o tipo, a ajuda e o padrão, e sai com o status 0**, porque pedir
ajuda não é um erro. Um valor que não cabe no tipo da flag é: `two` não é um `int`, então o `Parse`
imprimiu o que estava errado, o mesmo texto de uso abaixo, e saiu com o status 2, a convenção para
"você me chamou errado". O código do próprio programa nem rodou.

## Duas armadilhas

As duas vêm da regra de que o `Parse` para na primeira palavra que não é flag, e as duas falham em
silêncio:

```
ana@vm:~/flags$ bin/greet bia -times 2
hello, world
left over: [bia -times 2]
ana@vm:~/flags$ bin/greet -shout false
HELLO, WORLD
left over: [false]
```

Na primeira, `bia` veio antes das flags, então o `Parse` parou ali e `-times 2` virou duas palavras
de sobra. **Ponha as flags antes de todo o resto**, como o próprio comando go exige.

Na segunda, `-shout false` não desligou os gritos. Uma flag bool não recebe valor separado, porque
`-shout` sozinho já significa verdadeiro; então `false` foi a primeira palavra de sobra, e a
saudação saiu em maiúsculas. Uma bool recebe falso com `-shout=false`, sinal de igual incluído.
