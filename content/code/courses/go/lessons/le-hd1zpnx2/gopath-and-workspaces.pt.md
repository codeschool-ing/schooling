---
title: O GOPATH de antes e os workspaces de agora
version: 1
---

Tutoriais antigos, e muitas respostas na web, dizem que **código Go precisa morar em `~/go/src`**,
num diretório com o nome do seu caminho de importação. Isso já foi verdade e hoje está errado.
Antes de os módulos chegarem, o comando go achava cada pacote procurando dentro do `GOPATH`, e
código em qualquer outro lugar não compilava. O próprio comando go ainda diz isso:

```
ana@vm:~/setup$ go help gopath | sed -n '21,24p'
The GOPATH environment variable is also used by a legacy behavior of the
toolchain called GOPATH mode that allows some older projects, created before
modules were introduced in Go 1.11 and never updated to use modules,
to continue to build.
```

Esse modo antigo ainda pode ser ligado com `GO111MODULE=off`, e ele mostra a regra melhor do que
uma descrição. Aqui está um programa em `~/setup-work/hello` que importa um pacote chamado
`example.com/greet`, executado no modo GOPATH:

```
ana@vm:~/setup-work/hello$ GO111MODULE=off go run .
main.go:6:2: cannot find package "example.com/greet" in any of:
	/usr/local/go/src/example.com/greet (from $GOROOT)
	/home/ana/go/src/example.com/greet (from $GOPATH)
```

**No modo GOPATH, um caminho de importação era um diretório debaixo de uma de duas raízes**, a da
biblioteca padrão e a sua, e essas duas linhas são a busca inteira. Um módulo muda a pergunta: um
diretório com um `go.mod` na raiz diz como o seu código se chama, esteja onde estiver no disco, e é
por isso que a lição 4 consegue compilar `~/hello`.

O que o `~/go` guarda hoje é o que o comando go baixa e instala para você:

```
ana@vm:~/setup$ ls ~/go ~/go/pkg
/home/ana/go:
bin
pkg

/home/ana/go/pkg:
mod
sumdb
```

`bin` é o `GOBIN` da seção 03. `pkg/mod` é o cache de módulos, e `pkg/sumdb` são as anotações do
próprio comando go sobre o banco de checksums. Não há `src`, e nada seu pertence a esse lugar.

## Dois módulos seus, antes de qualquer um ser publicado

O programa acima é metade de um par. `~/setup-work` guarda dois módulos lado a lado, cada um com o
seu `go.mod`:

```
ana@vm:~/setup-work$ find . -type f | sort
./greet/go.mod
./greet/greet.go
./hello/go.mod
./hello/main.go
```

`greet` é uma biblioteca com uma função:

```go
// Package greet builds greetings.
package greet

// Hello returns a greeting for name.
func Hello(name string) string {
	return "Hello, " + name
}
```

e `hello` é um programa que a chama:

```go
package main

import (
	"fmt"

	"example.com/greet"
)

func main() {
	fmt.Println(greet.Hello("Ana"))
}
```

Como um caminho de importação corresponde a um módulo, e por que `Hello` começa com maiúscula, são
as lições 38 e 39. O que importa aqui é que, no modo módulo, o `hello` não enxerga o vizinho:

```
ana@vm:~/setup-work/hello$ go run .
main.go:6:2: no required module provides package example.com/greet; to add it:
	go get example.com/greet
```

A correção sugerida é a errada para este caso. O `go get` procuraria `example.com/greet` na rede,
pelo proxy de módulos, e o código está a um diretório de distância neste disco. **Um workspace é o
jeito de dizer "use a minha cópia daquele módulo"**: um arquivo chamado `go.work` que lista
diretórios de módulos, que o comando go trata como um build só. O `go work init` o cria e o
`go work use` acrescenta a ele:

```
ana@vm:~/setup-work$ go work init ./hello
ana@vm:~/setup-work$ go work use ./greet
ana@vm:~/setup-work$ cat go.work
go 1.27.1

use (
	./greet
	./hello
)
ana@vm:~/setup-work$ go run ./hello
Hello, Ana
ana@vm:~/setup-work/hello$ go run .
Hello, Ana
ana@vm:~/setup-work$ cat hello/go.mod
module example.com/hello

go 1.27.1
```

O segundo `go run` foi digitado dentro de `hello` e ainda assim achou o workspace, porque o comando
go procura um `go.work` no diretório atual e em cada diretório acima dele. E o `hello/go.mod` não
mudou: continua sem citar dependência nenhuma. **O workspace fica ao lado dos módulos, não dentro
deles**, então ele descreve como o seu disco está organizado e não promete nada a quem baixar o
`hello` sozinho.

É para isso que servem os workspaces: mexer numa biblioteca e no programa que a usa na mesma tarde,
sem nenhum dos dois publicado ainda. Um módulo único, que é o caso de todo exercício deste curso
até a lição 39, não precisa de `go.work` nenhum.
