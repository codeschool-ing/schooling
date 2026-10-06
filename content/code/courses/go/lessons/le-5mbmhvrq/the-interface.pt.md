---
title: A interface `error`
version: 1
---

Em Java, Python e JavaScript uma falha é **lançada**: ela sai da função por uma saída própria,
pula todas as linhas depois dela e sobe pelas chamadas até que algo a capture. Quem chega dessas
linguagens procura o mesmo mecanismo em Go, e ele não está lá. **Em Go um erro é um valor comum,
devolvido ao lado do resultado**, e quem chamou decide na linha seguinte o que fazer com ele. A
lição 20 mostrou o formato, `(T, error)`; esta seção trata da segunda metade.

`error` não é palavra-chave nem um tipo especial de objeto. É um tipo que a linguagem declara por
você, e o `go doc` mostra a declaração inteira:

```
ana@vm:~/errors$ go doc builtin.error
package builtin // import "builtin"

type error interface {
	Error() string
}
    The error built-in interface type is the conventional interface for
    representing an error condition, with the nil value representing no error.

```

**Uma interface com um método, `Error() string`.** Qualquer tipo que tenha esse método é um
`error`, sem dizer isso em lugar nenhum; a lição 27 é sobre interfaces satisfeitas desse jeito. E
as últimas palavras do comentário são a regra em que o resto desta lição se apoia: **um `error`
nil quer dizer que nada deu errado.**

## Dois erros da biblioteca padrão

Duas chamadas que podem falhar, `os.Open` num arquivo que não existe e `strconv.Atoi` num texto
que não é número, em `~/errors`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command errors looks at two errors from the standard library.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"os\"\n\t\"strconv\"\n)\n\nfunc main() {\n\tf, err := os.Open(\"notes.txt\")\n\tfmt.Println(f, err)\n",
      "note": "**`os.Open` devolve dois resultados, o arquivo e um `error`.** Não existe `notes.txt` em `~/errors`, então o arquivo é `nil` e o erro não: impresso, ele é uma frase com a operação, o caminho e o motivo."
    },
    {
      "code": "\tfmt.Printf(\"%T\\n\", err)\n",
      "note": "`%T` imprime o tipo do valor que está dentro da interface, `*fs.PathError`. A variável foi declarada como `error`; o que ela guarda é um ponteiro para uma struct do pacote `io/fs`."
    },
    {
      "code": "\n\tn, err := strconv.Atoi(\"12\")\n\tfmt.Println(n, err, err == nil)\n",
      "note": "**Sucesso é um `err` igual a `nil`.** `\"12\"` é um número, então `n` vale 12 e a comparação dá `true`. O `:=` é permitido aqui porque `n` é novo, e `err` só recebe um valor (lição 5)."
    },
    {
      "code": "\n\tn, err = strconv.Atoi(\"12a\")\n\tfmt.Println(n, err, err == nil)\n\tfmt.Printf(\"%T\\n\", err)\n\tfmt.Println(err.Error())\n}\n",
      "note": "Uma conversão que falhou: `n` vale 0 e `err` guarda um `*strconv.NumError`, um tipo completamente diferente. **Chamar o método `Error` dá o mesmo texto que o `fmt.Println` imprimiu**, porque imprimir um erro é chamar esse método."
    }
  ],
  "output": "<nil> open notes.txt: no such file or directory\n*fs.PathError\n12 <nil> true\n0 strconv.Atoi: parsing \"12a\": invalid syntax false\n*strconv.NumError\nstrconv.Atoi: parsing \"12a\": invalid syntax\n"
}
```

A primeira e a última linha da saída são as duas metades de um mesmo fato. O `fmt.Println`
imprimiu `open notes.txt: no such file or directory` porque o `fmt` verifica se um valor é um
`error` e, se for, chama `Error` e imprime a string. **A mensagem é o que o próprio tipo do erro
decidiu dizer**, e os dois tipos aqui dizem de jeitos diferentes: `*fs.PathError` escreve a
operação, o caminho e o motivo, e `*strconv.NumError` escreve a função, a entrada e o que havia de
errado com ela.

## Uma interface, muitos tipos por trás

A lição 22 mediu um valor de interface: 16 bytes, um tipo e um ponteiro. Um `error` é exatamente
isso. A variável `err` foi declarada uma vez, como `error`, e guardou um `*fs.PathError` numa linha
e um `*strconv.NumError` quatro linhas depois. O `%T` lê a metade do tipo, e é por isso que
imprimiu dois nomes diferentes para uma só variável.

A documentação diz que tipo esperar. O `os.Open` promete isso na última frase:

```
ana@vm:~/errors$ go doc os.Open
package os // import "os"

func Open(name string) (*File, error)
    Open opens the named file for reading. If successful, methods on the
    returned file can be used for reading; the associated file descriptor has
    mode O_RDONLY. If there is an error, it will be of type *PathError.

ana@vm:~/errors$ go doc os.PathError
package os // import "os"

type PathError = fs.PathError
    PathError records an error and the operation and file path that caused it.

```

`os.PathError` é um alias, a forma com `=` da lição 10, para `fs.PathError`, e é por isso que o
`%T` citou o pacote `fs`. **A assinatura continua dizendo `error`, e não `*PathError`.** Quem chama
e só precisa saber se a chamada falhou, e o que dizer a uma pessoa, não precisa de nada além da
interface. Quem quer tirar o caminho de dentro da struct consegue, e a lição 34 mostra como.

## Verificar é comparar com nil

Sucesso é `err == nil`, e nada mais curto que isso. Quem está acostumado com Python ou JavaScript
tenta primeiro a forma curta, em `~/errors-truthy`:

```go
	_, err := strconv.Atoi("12a")
	if err {
		fmt.Println(err)
	}
```

```
ana@vm:~/errors-truthy$ go run .
# example.com/truthy
./main.go:10:5: non-boolean condition in if statement
```

É a recusa da lição 8: Go não tem valor-verdade implícito, e uma interface não é um booleano.
Então o teste é sempre escrito como comparação, `err != nil` quando você quer a falha, e a seção
03 trata da linha em que essa comparação fica.

Mais uma coisa que a saída de `~/errors` mostra: quando o `Atoi` falhou, `n` valia 0. A função
devolveu um número mesmo assim, porque uma função com dois resultados sempre devolve dois. **O
valor ao lado de um erro diferente de nil não é uma resposta**, e o 0 ali não quer dizer nada além
de "não tenho nada para te dar". As poucas funções em que ele quer dizer alguma coisa avisam na
documentação: o `go doc io.Reader` manda quem chama usar os bytes que um `Read` devolveu antes de
olhar o erro.
