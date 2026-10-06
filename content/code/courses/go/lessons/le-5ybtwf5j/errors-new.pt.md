---
title: errors.New, e por que dois deles não são iguais
version: 1
---

O `errors.New` recebe uma string e devolve um `error` cuja mensagem é essa string, nada mais. A
lição 32 o usou em `price` para `age cannot be negative`. É a ferramenta certa quando a mensagem é
fixa e não há nada a pôr dentro dela. Ele também esconde uma surpresa em que quem vem de outras
linguagens tropeça: **dois erros feitos com o mesmo texto não são o mesmo erro.**

Aqui está ela em `~/wrap`, com dois erros que se leem igual:

```go
// Command wrap compares two errors made from the same text.
package main

import (
	"errors"
	"fmt"
)

func main() {
	a := errors.New("not found")
	b := errors.New("not found")
	fmt.Println(a)
	fmt.Println(a == b, a.Error() == b.Error())

	c := a
	fmt.Println(a == c)
	fmt.Printf("%T\n", a)
}
```

```
ana@vm:~/wrap$ go run .
not found
false true
true
*errors.errorString
```

`a == b` dá `false` com as mensagens iguais, e `a == c` dá `true`. A documentação diz isso com
todas as letras, e o código-fonte, que está no toolchain que o laboratório instalou, mostra como:

```
ana@vm:~/wrap$ go doc errors.New
package errors // import "errors"

func New(text string) error
    New returns an error that formats as the given text. Each call to New
    returns a distinct error value even if the text is identical.

ana@vm:~/wrap$ sed -n '64,75p' /usr/local/go/src/errors/errors.go
func New(text string) error {
	return &errorString{text}
}

// errorString is a trivial implementation of error.
type errorString struct {
	s string
}

func (e *errorString) Error() string {
	return e.s
}
```

É só isso. **O `errors.New` aloca uma struct nova a cada chamada e devolve um ponteiro para ela**,
então o `error` que ele devolve guarda o tipo `*errors.errorString` e um ponteiro que mais ninguém
tem. Comparar dois valores de interface compara as duas palavras deles, o tipo e o ponteiro que a
lição 32 desenhou. `a` e `b` guardam o mesmo tipo e ponteiros diferentes. `c := a` copiou a
interface, ponteiro incluído, então `c` é o mesmo erro que `a`.

## O que a desigualdade protege

Parece uma armadilha. É o comportamento que você quer, porque a alternativa é comparar erros pelo
texto. Dois pacotes sem relação nenhuma podem falhar com `not found`, e um programa que tratasse os
dois como um erro só confundiria um usuário inexistente com um arquivo inexistente. **A identidade
de um erro é o valor, não a frase**, e a frase é de quem lê um log.

Então quem chama não testa `err.Error() == "not found"`, mesmo que `a.Error() == b.Error()` tenha
dado `true` acima. Esse teste quebra no dia em que alguém reescreve a mensagem, e compila e roda o
tempo todo em que está quebrado. Quando um pacote quer que quem chama reconheça uma falha
específica, ele cria o erro uma vez, guarda numa variável e devolve esse mesmo valor toda vez, para
que o `==` tenha um ponteiro só para comparar. A lição 35 trata de erros declarados assim, e a
lição 34 do `errors.Is`, que encontra um deles mesmo depois de embrulhado.

## Quando o errors.New basta

O `errors.New` não aceita verbos: `errors.New("age %d is negative")` imprimiria o `%d` do jeito que
está. Quando a mensagem precisa de um valor dentro, ou embrulha outro erro, a função é o
`fmt.Errorf`, e a seção 03 trata dele. O que sobra para o `errors.New` é a frase fixa: uma regra
violada, uma entrada vazia, uma operação não permitida, em que toda ocorrência da falha diz a mesma
coisa.
