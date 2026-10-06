---
title: A promessa do Go 1, e a linha que a cumpre
version: 1
---

Um hábito comum com linguagens de programação é ficar numa versão antiga o máximo possível, porque
a nova vai quebrar alguma coisa. Go foi projetado contra esse hábito. O documento que veio com o
Go 1, publicado em go.dev/doc/go1compat, diz isso numa frase: **"It is intended that programs
written to the Go 1 specification will continue to compile and run correctly, unchanged, over the
lifetime of that specification."** Programas escritos para a especificação do Go 1 devem continuar
compilando e rodando corretamente, sem mudança, enquanto ela durar. O mesmo documento traça a linha
no código-fonte: um programa é compilado de novo pela versão nova, e os arquivos que uma versão gerou
não têm garantia de funcionar com a seguinte.

Uma promessa assim deixa uma pergunta. Go melhorou durante os catorze anos seguintes, e algumas
melhorias mudam o que o código existente faz. A resposta é uma linha que você já viu na lição 4: a
linha `go` do `go.mod`.

## Um programa, duas respostas

O programa abaixo junta três funções pequenas dentro de um laço e as chama depois que o laço
terminou. Como uma função consegue lembrar uma variável é a lição 21; o que importa aqui é que cada
função devolve o `i` que viu:

```go
// Command loop keeps a function from each turn of a loop and calls them afterwards.
package main

import "fmt"

func main() {
	var funcs []func() int
	for i := 0; i < 3; i++ {
		funcs = append(funcs, func() int { return i })
	}
	var got []int
	for _, f := range funcs {
		got = append(got, f())
	}
	fmt.Println(got)
}
```

Mesmo arquivo, mesmo compilador, go1.27.1 nas duas vezes. Só a linha `go` muda:

```
ana@vm:~/history-loop$ go mod edit -go=1.21 && cat go.mod
module example.com/loop

go 1.21
ana@vm:~/history-loop$ go run .
[3 3 3]
ana@vm:~/history-loop$ go mod edit -go=1.22 && go run .
[0 1 2]
```

O `go mod edit -go=` reescreve essa única linha, o que é mais seguro do que editar o arquivo à mão.
Com `go 1.21` o laço tem um `i` só, compartilhado pelas três funções, e quando elas são chamadas ele
já chegou a 3. Com `go 1.22` cada volta do laço ganha o seu próprio `i`, então as funções devolvem
0, 1 e 2. As notas da versão 1.22 dão o motivo: uma variável compartilhada causava "accidental
sharing bugs", bugs de compartilhamento acidental, e `[0 1 2]` é o que quase todo mundo que escreveu
esse laço queria.

**A linha `go` diz para qual versão da linguagem o módulo foi escrito, e o compilador mantém o
significado daquela versão.** Um módulo que ainda diz `go 1.21` recebe `[3 3 3]` de toda versão,
então atualizar o toolchain não mudou nada para ele. Um módulo muda de comportamento no dia em que
alguém edita a linha `go` dele, uma mudança num arquivo que quem revisa consegue ver.

## A linha também é um mínimo

A linha `go` funciona na outra direção também. Este programa usa generics, do Go 1.18, que as lições
30 e 31 ensinam:

```go
// Command biggest uses a generic function.
package main

import "fmt"

func Biggest[T int | float64](a, b T) T {
	if a > b {
		return a
	}
	return b
}

func main() {
	fmt.Println(Biggest(3, 7), Biggest(2.5, 1.5))
}
```

```
ana@vm:~/history-generic$ go mod edit -go=1.17 && go build; echo $?
# example.com/biggest
./main.go:6:14: type parameter requires go1.18 or later (-lang was set to go1.17; check go.mod)
./main.go:6:16: embedding interface element int | float64 requires go1.18 or later (-lang was set to go1.17; check go.mod)
./main.go:7:5: invalid operation: a > b (type parameter T cannot use operator >)
./main.go:14:14: implicit function instantiation requires go1.18 or later (-lang was set to go1.17; check go.mod)
1
ana@vm:~/history-generic$ go mod edit -go=1.18 && go run .
7 2.5
```

O go1.27.1 conhece generics perfeitamente e mesmo assim os recusou, porque o módulo dizia `go 1.17`.
As mensagens dizem exatamente isso: `-lang was set to go1.17; check go.mod`. **Um recurso mais novo
que a linha `go` é erro de compilação, mesmo quando o compilador o tem**, então um módulo nunca usa
algo que a versão que ele diz precisar não entenderia. A lição 13 usa isso para descobrir quando duas
conversões chegaram.

## GODEBUG: a mesma ideia para a biblioteca

O laço é a linguagem. Mudanças no comportamento da biblioteca padrão são mantidas compatíveis de
outro jeito: cada uma ganha uma configuração com nome em `GODEBUG`, e a linha `go` escolhe o valor
padrão dela. O `go list` mostra os padrões que um módulo recebe:

```
ana@vm:~/history-loop$ go mod edit -go=1.21 && go list -f '{{.DefaultGODEBUG}}' . | tr , '\n' | grep http
httpcookiemaxnum=0
httplaxcontentlength=1
httpmuxgo121=1
httpservecontentkeepheaders=1
ana@vm:~/history-loop$ go mod edit -go=1.27.1 && go list -f '[{{.DefaultGODEBUG}}]' .
[]
ana@vm:~/history-loop$ grep httpmuxgo121 /usr/local/go/src/internal/godebugs/table.go
	{Name: "httpmuxgo121", Package: "net/http", Changed: 22, Old: "1"},
```

Com `go 1.21`, o módulo recebe uma lista de configurações que seguram comportamento antigo; o
`grep http` fica com as quatro que pertencem a `net/http`. `httpmuxgo121=1` mantém o roteador de
requisições do `net/http`, o `ServeMux`, se comportando como no Go 1.21, e a própria tabela do
código-fonte de Go diz por quê: o padrão mudou (`Changed`) no 1.22, e `Old: "1"` restaura o que
vinha antes. O roteador antigo continua na biblioteca, congelado, num arquivo chamado
`servemux121.go`. Com a linha `go` em 1.27.1 a lista fica vazia, porque nada é segurado. Os
colchetes no template estão ali só para que uma resposta vazia ainda imprima alguma coisa.

Normalmente você não define nenhuma dessas. Elas existem para que um módulo escrito em 2023 se
comporte como em 2023 até alguém mexer na linha `go` dele, e para que você ainda possa voltar uma
configuração à mão, pela variável de ambiente `GODEBUG`, enquanto conserta o que dependia do
comportamento antigo.
