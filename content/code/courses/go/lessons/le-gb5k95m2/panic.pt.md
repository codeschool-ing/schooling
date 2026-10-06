---
title: O que é um panic, e para que serve
version: 1
---

Quem chega de Java ou de Python procura o `throw` de Go, encontra `panic` e começa a usá-lo para
avisar que um arquivo não existe. **Um panic não é a exceção de Go.** Ele desfaz as chamadas como
uma exceção desfaria, mas a lição 32 já deu às falhas o mecanismo delas, o valor `error`. Um panic
diz outra coisa: o próprio programa está errado, e seguir em frente só o deixaria errado em mais
lugares.

## O que acontece quando um programa entra em panic

Este programa em `~/panic` lê um elemento depois do fim de uma slice de dois elementos:

```go
// Command panic reads one element past the end of a slice.
package main

import "fmt"

func main() {
	scores := []int{7, 9}
	fmt.Println("scores:", len(scores))
	i := len(scores)
	fmt.Println(scores[i])
	fmt.Println("never printed")
}
```

```
ana@vm:~/panic$ go vet && go run .; echo $?
scores: 2
panic: runtime error: index out of range [2] with length 2

goroutine 1 [running]:
main.main()
	/home/ana/panic/main.go:10 +0x73
exit status 2
1
```

O `go vet` não teve nada a dizer e o compilador gerou o binário, porque o valor de `i` só é
conhecido quando o programa roda. O primeiro `Println` funcionou. A linha 10 pediu o elemento 2 de
uma slice de comprimento 2, e naquele momento o programa parou: `never printed` não saiu. O que saiu
no lugar tem três partes.

- A linha que começa com `panic:` é **o que deu errado**. `runtime error` quer dizer que o próprio
  runtime de Go percebeu, e o resto é a mensagem que a lição 12 viu ao ler além do comprimento de
  uma slice.
- De `goroutine 1 [running]:` para baixo está **onde deu errado**, um stack trace: a função que
  estava rodando, `main.main`, e o arquivo e a linha dela, `main.go:10`. A lição 37 lê traces como
  este quadro a quadro.
- O **código de saída é 2**. A linha `exit status 2` e o `1` abaixo dela são do próprio comando go:
  o `go run` informa como o programa terminou e depois falha ele mesmo com 1. O programa sozinho
  diz 2 diretamente:

```
ana@vm:~/panic$ go build && ./panic; echo $?
scores: 2
panic: runtime error: index out of range [2] with length 2

goroutine 1 [running]:
main.main()
	/home/ana/panic/main.go:10 +0x73
2
```

**Um panic para o programa na linha que deu errado, diz onde, e sai com código 2.** Um programa que
informa um erro e para por conta própria costuma sair com 1, como o próximo programa faz, então o
2 merece atenção num script que roda programas Go.

Este curso já encontrou o resto da família, cada vez como uma linha de uma lição sobre outro
assunto: um inteiro dividido por zero na lição 7, uma escrita num map nil na lição 14, uma função
nil chamada na lição 21, um ponteiro nil seguido na lição 23, uma type assertion que não se
confirmou na lição 28. Em todos o runtime descobre que o programa pediu algo que não pode ser feito.
E todos são bugs: não existe entrada para a qual ler `scores[2]` seja a coisa certa a fazer.

## `panic`, chamado à mão

`panic` também é uma função embutida, e um programa pode chamá-la com qualquer valor. A biblioteca
padrão a chama num tipo de lugar só, e o `regexp` mostra qual. `~/panic-must` confere uma palavra
contra um padrão escrito no código-fonte e contra um segundo padrão digitado na linha de comando,
que chega em `os.Args` depois do nome do próprio programa:

```go
// Command must checks a word against a pattern written in the source
// and against one typed on the command line.
package main

import (
	"fmt"
	"os"
	"regexp"
)

var word = regexp.MustCompile(`^[a-z]+$`)

func main() {
	fmt.Println("word:", word.MatchString(os.Args[1]))
	re, err := regexp.Compile(os.Args[2])
	if err != nil {
		fmt.Println("bad pattern:", err)
		os.Exit(1)
	}
	fmt.Println("pattern:", re.MatchString(os.Args[1]))
}
```

```
ana@vm:~/panic-must$ go build && ./must gopher 'go+'
word: true
pattern: true
ana@vm:~/panic-must$ ./must gopher 'go('; echo $?
word: true
bad pattern: error parsing regexp: missing closing ): `go(`
1
```

`regexp.Compile` devolve um `error`, e um padrão com um parêntese sem fechar recebeu um, impresso
como mensagem com código de saída 1. Agora o mesmo programa em `~/panic-mustbug`, com um caractere
perdido do padrão no código-fonte, `^[a-z+$`:

```
ana@vm:~/panic-mustbug$ go build && ./must gopher 'go+'; echo $?
panic: regexp: Compile(`^[a-z+$`): error parsing regexp: missing closing ]: `[a-z+$`

goroutine 1 [running]:
regexp.MustCompile({0x4ba5a0, 0x7})
	/usr/local/go/src/regexp/regexp.go:312 +0xb4
main.init()
	/home/ana/panic-mustbug/main.go:11 +0x1f
2
```

O programa nunca chegou a `main`. Uma variável de pacote recebe o valor antes de `main` começar, no
passo que o trace chama de `main.init`, ao qual a lição 39 volta; o `MustCompile` entrou em panic
ali, na linha 11. O código-fonte dele são sete linhas de Go comum:

```
ana@vm:~/panic-mustbug$ sed -n 309,315p $(go env GOROOT)/src/regexp/regexp.go
func MustCompile(str string) *Regexp {
	regexp, err := Compile(str)
	if err != nil {
		panic(`regexp: Compile(` + quote(str) + `): ` + err.Error())
	}
	return regexp
}
```

Ele chama `Compile` e transforma o erro em panic. **A diferença entre as duas funções é quem
escreveu o padrão.** Um padrão que um usuário digitou pode estar errado em qualquer execução, e o
programa precisa dizer isso e seguir em frente, então ele recebe um `error`. Um padrão escrito no
código-fonte só está errado se quem programou cometeu um engano. Aí ele falha na primeira execução,
na mesa de quem programou e antes de `main`, que é o melhor lugar para um bug ser encontrado.

## Bugs entram em panic, falhas voltam como valor

Daí sai a regra, e a biblioteca padrão a segue:

| o que deu errado | quem causou | o que Go usa |
|---|---|---|
| um arquivo não existe, um número foi digitado errado, um servidor não respondeu | o mundo em que o programa roda | um `error`, lições 32 a 35 |
| um índice depois do fim, uma escrita num map nil, um padrão no código-fonte que não compila | o próprio código do programa | um panic |

**Se quem chama pode causar o problema com uma entrada, devolva um erro. Entre em panic só pelo
que não pode acontecer num programa correto.** Uma biblioteca que entra em panic com entrada ruim
transforma toda entrada de quem a chama num jeito de derrubar quem a chama. Uma função `Must` é a
exceção deliberada, e o nome dela avisa.
