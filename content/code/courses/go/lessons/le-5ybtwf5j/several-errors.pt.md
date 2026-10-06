---
title: Vários erros num só, e o que embrulhar promete
version: 1
---

Às vezes uma falha não é a história inteira. Um formulário com o nome vazio e a idade negativa tem
dois problemas, e informar só o primeiro manda a pessoa de volta para corrigi-lo e só então
encontrar o segundo. Um arquivo cuja escrita falhou pode também falhar ao fechar. **Go tem dois
jeitos de pôr vários erros num valor só**: o `errors.Join`, para uma lista, e o `fmt.Errorf` com
mais de um `%w`, para uma frase.

## errors.Join: uma lista de falhas

`~/wrap-join` verifica um formulário de cadastro e junta todos os problemas antes de devolver:

```go
// Command signup checks a form and reports every problem at once.
package main

import (
	"errors"
	"fmt"
)

func validate(name string, age int) error {
	var errs []error
	if name == "" {
		errs = append(errs, errors.New("name is empty"))
	}
	if age < 0 {
		errs = append(errs, fmt.Errorf("age %d is negative", age))
	}
	return errors.Join(errs...)
}

func main() {
	fmt.Println(validate("Ana", 30))
	err := validate("", -4)
	fmt.Println(err)
	fmt.Printf("%T %q\n", err, err.Error())
}
```

```
ana@vm:~/wrap-join$ go run .
<nil>
name is empty
age -4 is negative
*errors.joinError "name is empty\nage -4 is negative"
```

A primeira chamada não encontrou nada, e `validate` devolveu `nil` sem um caso especial para isso:
`errs` era uma slice vazia, e **o `errors.Join` de nada é `nil`**. A segunda chamada encontrou dois
problemas e devolveu um erro, um `*errors.joinError`, cuja mensagem são as duas mensagens com uma
quebra de linha entre elas; o `%q` mostra o `\n`. `errs...` espalha a slice sobre um parâmetro
variádico, como a lição 21 mostrou. A documentação diz cada uma dessas regras:

```
ana@vm:~/wrap-join$ go doc errors.Join
package errors // import "errors"

func Join(errs ...error) error
    Join returns an error that wraps the given errors. Any nil error values are
    discarded. Join returns nil if every value in errs is nil. The error formats
    as the concatenation of the strings obtained by calling the Error method of
    each element of errs, with a newline between each string.

    A non-nil error returned by Join implements the Unwrap() []error method.
    The errors may be inspected with Is and As.

```

O `Join` não acrescenta palavras próprias, então serve para uma lista de problemas independentes,
cada um já dizendo o que é. Uma mensagem espalhada em várias linhas fica boa num terminal e ruim
dentro de uma entrada de log de uma linha, o que vale saber antes de imprimir uma ali.

## Vários %w: uma frase, várias causas

Quando as falhas pertencem a uma operação e merecem uma frase, o `fmt.Errorf` aceita mais de um
`%w`. `~/wrap-two` relata um salvamento que falhou duas vezes:

```go
	writeErr := errors.New("disk full")
	closeErr := errors.New("file already closed")
	err := fmt.Errorf("save notes.txt: %w (and closing it: %w)", writeErr, closeErr)
	fmt.Println(err)
	fmt.Printf("%T\n", err)
```

```
ana@vm:~/wrap-two$ go run .
save notes.txt: disk full (and closing it: file already closed)
*fmt.wrapErrors
```

Uma linha, com as palavras que você escolheu, e o tipo é `*fmt.wrapErrors`, no plural. Algumas
linhas abaixo das que a seção 03 imprimiu, o código-fonte do `fmt.Errorf` monta esse tipo sempre
que um formato tem mais de um `%w`, e guarda todos os operandos numa lista em vez de um num campo.
**Os dois erros são guardados inteiros, como com um `%w` só**, e os dois podem ser encontrados
depois; a lição 34 mostra como quem chama vasculha um erro que guarda uma lista.

## Embrulhar é uma promessa

O `%v` e o `%w` imprimem o mesmo texto, então a escolha entre eles parece questão de gosto. É uma
decisão sobre o que a sua função promete. Com `%w`, o erro de baixo continua alcançável: da lição
34 em diante, quem chama pode perguntar se um erro de `readConfig` tem um `*fs.PathError` dentro e
agir conforme a resposta. **Quando quem chama faz isso, o erro interno passa a fazer parte do
comportamento da sua função**, tanto quanto os parâmetros dela.

Suponha que `readConfig` deixe de ler um arquivo e passe a buscar as configurações pela rede. Com
`%w`, todo código que chama e verificava se faltava um arquivo agora verifica algo que nunca vai
acontecer, e nada avisa: o código compila e roda, e o ramo do arquivo inexistente está morto. Com
`%v`, ninguém poderia ter dependido do erro de arquivo, e a mudança não quebra nada.

Então a pergunta a fazer em cada `fmt.Errorf` é se quem chama deve conseguir ver o erro de baixo.
**Embrulhe com `%w` quando o erro interno faz parte do que a sua função significa; acrescente
contexto com `%v` quando ele é um detalhe de como a função calha de funcionar hoje.** A própria
documentação do pacote `errors` aponta para um post do blog do Go sobre exatamente essa escolha,
`https://go.dev/blog/go1.13-errors`; o laboratório não alcança o go.dev, então esta lição não o cita.
