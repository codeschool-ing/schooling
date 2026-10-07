---
title: Tipos genéricos, os métodos deles e o que um método não pode fazer
version: 1
---

Um tipo pode receber parâmetros de tipo tanto quanto uma função, e é aqui que a palavra **contêiner**
da lição 30 vira código. Uma pilha guarda valores e devolve o último empilhado; o que os valores são
não importa para ela, então ela é escrita uma vez, para um `T` que quem usa a pilha escolhe. Em
`~/generic2-stack`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\ntype Stack[T any] struct {\n\titems []T\n}\n",
      "note": "**Uma lista de parâmetros de tipo numa declaração de tipo.** `Stack` é uma struct cujo campo é uma slice de `T`, e `T` é o que o código que a usa disser."
    },
    {
      "code": "\nfunc (s *Stack[T]) Push(v T) {\n\ts.items = append(s.items, v)\n}\n",
      "note": "**O receptor repete o nome do parâmetro de tipo, sem a restrição**: `Stack[T]`, não `Stack[T any]`. A restrição pertence ao tipo e não é repetida. O receptor ponteiro está ali porque `Push` muda a pilha, a regra da lição 26."
    },
    {
      "code": "\nfunc (s *Stack[T]) Pop() (T, bool) {\n\tvar zero T\n\tif len(s.items) == 0 {\n\t\treturn zero, false\n\t}\n",
      "note": "**`var zero T` é como código genérico escreve \"o valor zero\"**, porque não existe literal que seja zero para todo tipo: `0`, `\"\"` e `nil` servem a alguns tipos e não a outros. Uma pilha vazia o devolve com `false`, o formato comma-ok da lição 14."
    },
    {
      "code": "\ttop := s.items[len(s.items)-1]\n\ts.items = s.items[:len(s.items)-1]\n\treturn top, true\n}\n",
      "note": "Pega o último elemento e depois refatia para descartá-lo (lição 12). Nada aqui depende do que `T` é."
    },
    {
      "code": "\nfunc main() {\n\tvar words Stack[string]\n\twords.Push(\"first\")\n\twords.Push(\"second\")\n\tfmt.Println(words.Pop())\n\tfmt.Println(words.Pop())\n\tlast, ok := words.Pop()\n\tfmt.Printf(\"%q %v\\n\", last, ok)\n",
      "note": "`Stack[string]` é um tipo, e o valor zero dele é uma pilha vazia pronta para uso, o zero útil da lição 6. O terceiro `Pop` a encontra vazia e devolve `\"\"`, a `string` zero."
    },
    {
      "code": "\n\tnums := &Stack[int]{}\n\tnums.Push(42)\n\tfmt.Printf(\"%T %v\\n\", nums, nums.items)\n}\n",
      "note": "A mesma declaração para `int`. O `%T` imprime o tipo instanciado, `*main.Stack[int]`, com o argumento de tipo fazendo parte do nome."
    }
  ],
  "output": "second true\nfirst true\n\"\" false\n*main.Stack[int] [42]"
}
```

Não há inferência para um tipo. A chamada de uma função tem argumentos de onde ler `T`;
`var words Stack[string]` não tem nenhum, então o argumento de tipo é sempre escrito. E **`Stack`
sozinho não é um tipo**, só uma receita para um, então cada instanciação é um tipo próprio. Em
`~/generic2-stackbad`, três linhas erram nisso:

```go
func main() {
	var s Stack
	words := Stack[string]{}
	words.Push(3)
	var nums Stack[int] = words
	fmt.Println(s, nums)
}
```

```
ana@vm:~/generic2-stackbad$ go run .
# example.com/generic2-stackbad
./main.go:14:8: cannot use generic type Stack[T any] without instantiation
./main.go:16:13: cannot use 3 (untyped int constant) as string value in argument to words.Push
./main.go:17:24: cannot use words (variable of struct type Stack[string]) as Stack[int] value in variable declaration
```

O segundo erro é o motivo de escrever um `Stack[T]`. Uma pilha de strings recusa um `int` em tempo de
compilação, onde uma pilha feita sobre o `[]any` da lição 28 o teria aceitado e devolvido a um código
que esperava uma string. O terceiro mostra que `Stack[string]` e `Stack[int]` não têm mais relação
entre si do que `Celsius` e `Fahrenheit` tinham na lição 10, embora uma declaração só tenha produzido
os dois.

## Um método não pode estreitar a restrição do tipo

Uma pilha que saiba dizer se contém um valor precisa de `==`. Escrito como método, em
`~/generic2-contains`:

```go
func (s *Stack[T]) Contains(v T) bool {
	for _, x := range s.items {
		if x == v {
			return true
		}
	}
	return false
}
```

```
ana@vm:~/generic2-contains$ go run .
# example.com/generic2-contains
./main.go:15:6: invalid operation: x == v (incomparable types in type set)
```

A mensagem é a da seção 03. O `T` de um método é o `T` do tipo, e o tipo disse `any`. **Todo método
de `Stack` tem de funcionar para todo `Stack`**, inclusive um `Stack[[]int]`, cujos elementos não se
comparam, então nenhum método pode pedir mais do que a declaração pediu. O receptor também não pode
acrescentar a exigência, porque a restrição não é repetida ali.

Dois consertos, e eles diferem em quem paga. Declarar `Stack[T comparable]` torna `Contains` válido e
proíbe toda pilha de slices ou de maps. Ou `Contains` vira uma função com uma restrição própria, mais
estrita, que é o que `~/generic2-contains2` faz:

```go
func Contains[T comparable](s *Stack[T], v T) bool {
	for _, x := range s.items {
		if x == v {
			return true
		}
	}
	return false
}

func main() {
	var s Stack[string]
	s.Push("ana")
	fmt.Println(Contains(&s, "ana"), Contains(&s, "bia"))
}
```

```
ana@vm:~/generic2-contains2$ go run .
true false
```

Um `Stack[[]int]` continua podendo existir; ele só não pode ser passado a `Contains`. A biblioteca
padrão faz a mesma escolha em todo lugar: `slices.Index` pede `E comparable` e `slices.Clone` pede
`E any`, porque cada função declara só o que precisa.

## Um método pode ter parâmetros de tipo próprios

Os parâmetros de tipo do receptor são os do tipo. Um método também pode declarar novos, entre
colchetes depois do nome, para tipos que só aquele método usa. O `Map` da seção 02, como um método
que transforma uma pilha de um tipo numa pilha de outro, em `~/generic2-method`:

```go
func (s *Stack[T]) Map[U any](f func(T) U) *Stack[U] {
	out := &Stack[U]{}
	for _, v := range s.items {
		out.Push(f(v))
	}
	return out
}

func main() {
	ages := &Stack[int]{}
	ages.Push(41)
	ages.Push(7)
	labels := ages.Map(strconv.Itoa)
	fmt.Printf("%q %T\n", labels.items, labels)
}
```

```
ana@vm:~/generic2-method$ go run .
["41" "7"] *main.Stack[string]
ana@vm:~/generic2-method$ go mod edit -go=1.26 && go run .
# example.com/generic2-method
./main.go:16:24: generic method requires go1.27 or later (-lang was set to go1.26; check go.mod)
```

`T` veio do receptor, `int`, e `U` foi inferido de `strconv.Itoa`, como na função. O segundo comando
é a linha `go` da lição 2 em ação de novo. Um método com parâmetros de tipo próprios precisa de um
módulo que diga `go 1.27` ou mais recente; código escrito para versões mais antigas faz o mesmo
trabalho com uma função como o `Map` da seção 02. Você vai ler bastante código assim.

**O que um método desses não pode é fazer parte de uma interface.** Uma interface não pode declarar
um método com parâmetros de tipo, e um método que os tem não satisfaz um método de interface sem eles.
`~/generic2-iface` tenta as duas coisas:

```go
type Mapper interface {
	Map[U any](f func(int) U) *Stack[U]
}

type TextMapper interface {
	Map(f func(int) string) *Stack[string]
}

func main() {
	var m TextMapper = &Stack[int]{}
	fmt.Println(m.Map(strconv.Itoa))
}
```

```
ana@vm:~/generic2-iface$ go run .
# example.com/generic2-iface
./main.go:25:5: interface method must have no type parameters
./main.go:25:25: undefined: U
./main.go:33:21: cannot use &Stack[int]{} (value of type *Stack[int]) as TextMapper value in variable declaration: *Stack[int] does not implement TextMapper (wrong type for method Map)
		have Map[U any](func(int) U) *Stack[U]
		want Map(func(int) string) *Stack[string]
```

O primeiro erro é a regra, e o segundo decorre dele: com os colchetes recusados, `U` nunca foi
declarado. O terceiro é a outra metade. `TextMapper` pede exatamente o `Map` que `*Stack[int]` teria
com `U` igual a `string`, e o compilador recusa mesmo assim, imprimindo o método que o tipo tem
(`have`) contra o que a interface quer (`want`). Uma interface descreve métodos que um valor tem
agora, uma assinatura cada. Um método genérico é uma família de métodos, e nenhum deles existe até que
uma chamada escolha `U`.

Então a regra da lição 30 vale dentro de um tipo também: parâmetros de tipo para código que é o mesmo
qualquer que seja o tipo, interfaces para comportamento. Um método genérico serve ao primeiro, e fica
separado do segundo.
