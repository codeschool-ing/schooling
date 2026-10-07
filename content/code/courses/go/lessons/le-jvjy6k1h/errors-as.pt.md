---
title: "errors.As: tire o elo da cadeia, com os campos dele"
version: 1
---

`errors.Is` responde sim ou não. Às vezes o código de cima precisa de mais que isso: o nome do
arquivo que faltou, para pôr numa mensagem para uma pessoa, ou para criá-lo. O movimento tentador é
tirá-lo da mensagem, com `strings.Contains(err.Error(), ...)` ou coisa pior, e **uma mensagem é
escrita para pessoas e muda quando alguém acrescenta uma camada de contexto**. Os dados continuam
na cadeia, num valor com campos. Este é o elo que `os.ReadFile` pôs lá, o tipo que a lição 32
encontrou pelo apelido `os.PathError`:

```
ana@vm:~/is-as-as$ go doc fs.PathError
package fs // import "io/fs"

type PathError struct {
	Op   string
	Path string
	Err  error
}
    PathError records an error and the operation and file path that caused it.

func (e *PathError) Error() string
func (e *PathError) Timeout() bool
func (e *PathError) Unwrap() error
```

Três campos, e os métodos estão no ponteiro, `*PathError`, então o erro na cadeia é um
`*fs.PathError`, como o laço da seção 02 imprimiu. `errors.As` encontra um elo pelo tipo e o
entrega, e `errors.AsType` faz o mesmo com outra assinatura. Aqui estão as duas, depois da única
verificação que não funciona, num `main` novo para o mesmo programa:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "func main() {\n\terr := start()\n\n",
      "note": "A mesma `start` da seção 02 roda primeiro; `err` é a cadeia de quatro elos."
    },
    {
      "code": "\t_, ok := err.(*fs.PathError)\n\tfmt.Println(\"assertion:\", ok)\n\n",
      "note": "**Uma asserção de tipo pergunta só pelo valor de fora**, do jeito que o `==` fez na seção 03. O de fora é um `*fmt.wrapError`, então `ok` é falso. A lição 29 trata de asserções."
    },
    {
      "code": "\tvar pe *fs.PathError\n\tif errors.As(err, &pe) {\n\t\tfmt.Println(\"Op:  \", pe.Op)\n\t\tfmt.Println(\"Path:\", pe.Path)\n\t\tfmt.Println(\"Err: \", pe.Err)\n\t}\n\n",
      "note": "**`errors.As` percorre a cadeia procurando um elo cujo tipo seja o tipo de `pe`**, e o copia para `pe` quando encontra. É por isso que recebe `&pe`: precisa do endereço da variável que vai preencher."
    },
    {
      "code": "\tif pe, ok := errors.AsType[*fs.PathError](err); ok {\n\t\tfmt.Println(\"AsType found\", pe.Path)\n\t}\n}\n",
      "note": "**`errors.AsType` faz o mesmo e devolve o elo em vez de preencher uma variável.** O tipo vai entre colchetes, como argumento de tipo (lição 31), e o resultado volta com um booleano comma-ok."
    }
  ],
  "output": "assertion: false\nOp:   open\nPath: settings.json\nErr:  no such file or directory\nAsType found settings.json\n"
}
```

**`errors.Is` procura um valor; `errors.As` e `errors.AsType` procuram um tipo**, e todas percorrem
a cadeia inteira do jeito que a figura da seção 02 desenha. Uma vez fora, o elo é um
`*fs.PathError` comum: `pe.Path` é a string `settings.json`, sem análise de texto nenhuma, e `pe.Err`
é o `syscall.Errno` um elo mais abaixo.

O mesmo vale para qualquer tipo de erro, inclusive os que você escreve. O `LineError` da lição 32
guardava um número de linha num campo; depois que alguém embrulha um, `errors.As` com uma variável
`*LineError`, ou `errors.AsType[*LineError]`, é como o código de cima recupera o número.

## O alvo precisa ser um ponteiro para uma variável

`errors.As` recebe o alvo como `any`, então o compilador aceita qualquer coisa ali. Esqueça o `&` e
passe a própria variável:

```go
	var pe *fs.PathError
	if errors.As(err, pe) {
		fmt.Println(pe.Path)
	}
```

`pe` é um `*fs.PathError` que não aponta para lugar nenhum. `errors.As` não tem variável onde
escrever, e não tem como avisar isso na compilação, então entra em pânico quando roda. O `go vet`
lê a chamada antes e diz o que está errado:

```
ana@vm:~/is-as-panic$ go vet; echo $?
main.go:13:5: second argument to errors.As must be a non-nil pointer to either a type that implements error, or to any interface type
1
ana@vm:~/is-as-panic$ go build && ./panic 2>&1 | head -3
panic: errors: target must be a non-nil pointer

goroutine 1 [running]:
ana@vm:~/is-as-panic$ ./panic 2>/dev/null; echo $?
2
```

O programa para na chamada com status de saída 2, que a lição 36 explica, e imprime um stack trace
que o `head` cortou aqui e que a lição 37 lê inteiro. **Esse é um erro que o `go vet` pega toda
vez**, mais um motivo para rodá-lo antes de qualquer outra pessoa ler o código, como disse a lição
4.

## `AsType` confere o tipo na compilação

`errors.AsType` recebe o tipo entre colchetes em vez de uma variável, então não há `&` para
esquecer. Ela também recusa um tipo que não tem como estar numa cadeia. `fs.PathError` sem o
asterisco é um tipo assim, porque o método `Error` dele está no ponteiro:

```go
	if pe, ok := errors.AsType[fs.PathError](err); ok {
		fmt.Println(pe.Path)
	}
```

```
ana@vm:~/is-as-value$ go run .; echo $?
# example.com/value
./main.go:12:29: fs.PathError does not satisfy error (method Error has pointer receiver)
1
```

São os conjuntos de métodos da lição 26 vistos do outro lado: só `*fs.PathError` é um `error`, então
só ele pode ser pedido. O mesmo erro escrito com `errors.As`, um `var pe fs.PathError` e `&pe`,
compila, e é pego pelas mesmas duas coisas que pegaram o `&` esquecido:

```
ana@vm:~/is-as-value2$ go vet; echo $?
main.go:13:5: second argument to errors.As must be a non-nil pointer to either a type that implements error, or to any interface type
1
ana@vm:~/is-as-value2$ go build && ./value 2>&1 | head -1
panic: errors: *target must be interface or implement error
```

A documentação agora aponta para a função mais nova:

```
ana@vm:~/is-as-old$ go doc errors.As | head -10
package errors // import "errors"

func As(err error, target any) bool
    As finds the first error in err's tree that matches target, and if one
    is found, sets target to that error value and returns true. Otherwise,
    it returns false.

    For most uses, prefer AsType. As is equivalent to AsType but sets its target
    argument rather than returning the matching error and doesn't require its
    target argument to implement error.
```

`AsType` é a mais nova das duas. A versão anterior à 1.26 nem a tem:

```
ana@vm:~/is-as-old$ GOTOOLCHAIN=go1.25.0 go doc errors.AsType
doc: no symbol AsType in package errors
ana@vm:~/is-as-old$ GOTOOLCHAIN=go1.26.0 go doc errors.AsType | head -3
package errors // import "errors"

func AsType[E error](err error) (E, bool)
```

Então escreva `AsType` em código novo, e leia `As` com fluência, porque é a forma de todo módulo
que precisou compilar com um Go mais antigo. A regra para escolher entre elas e `errors.Is` é mais
curta que qualquer das assinaturas: **pergunte com `Is` quando a resposta for sim ou não, e com
`As` ou `AsType` quando você precisar do valor**. Quais erros merecem uma variável própria para o
`Is` procurar é o assunto da lição 35.
