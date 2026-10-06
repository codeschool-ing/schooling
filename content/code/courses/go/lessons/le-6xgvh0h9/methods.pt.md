---
title: Uma função com receptor
version: 1
---

Em Java ou Python um método é escrito dentro de uma classe, e a classe é o único lugar onde ele pode
morar. Go não tem classes, como a lição 1 disse, e a lição 15 observou que a declaração de uma struct
lista campos e mais nada. **Um método em Go é uma função declarada no nível do pacote com um
parâmetro a mais, o receptor, escrito na frente do nome.** Ele pode pertencer a qualquer tipo que o
seu pacote define, e struct é só um tipo entre outros. As temperaturas da lição 10, em `~/methods`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\ntype Celsius float64\ntype Fahrenheit float64\n",
      "note": "Os dois tipos definidos da lição 10, cada um construído sobre um `float64`."
    },
    {
      "code": "\nfunc CToF(c Celsius) Fahrenheit {\n\treturn Fahrenheit(c*9/5 + 32)\n}\n",
      "note": "A conversão da lição 10 como função comum. A temperatura chega como o parâmetro `c`."
    },
    {
      "code": "\nfunc (c Celsius) ToFahrenheit() Fahrenheit {\n\treturn Fahrenheit(c*9/5 + 32)\n}\n",
      "note": "**O mesmo corpo como método.** `(c Celsius)` antes do nome é o receptor: um parâmetro com nome e tipo, escrito num lugar só dele. O método pertence a `Celsius`, que é um número, sem struct nenhuma por perto."
    },
    {
      "code": "\ntype Rect struct {\n\tW, H float64\n}\n\nfunc (r Rect) Area() float64 {\n\treturn r.W * r.H\n}\n",
      "note": "Uma struct ganha método do mesmo jeito. A declaração de `Rect` nomeia só os campos, e o método fica ao lado; poderia muito bem ficar em outro arquivo do mesmo pacote."
    },
    {
      "code": "\nfunc main() {\n\tboil := Celsius(100)\n\tfmt.Println(CToF(boil), boil.ToFahrenheit())\n\n\tr := Rect{W: 3, H: 4}\n\tfmt.Println(r.Area())\n}\n",
      "note": "Um método é chamado sobre um valor, com um ponto. `boil.ToFahrenheit()` entrega `boil` ao método como `c`, então a função e o método calculam os mesmos 212."
    }
  ]
}
```

```
ana@vm:~/methods$ go run .
212 212
12
```

O receptor costuma ter uma ou duas letras, a primeira do nome do tipo, e a mesma letra em todos os
métodos daquele tipo. Ele não se chama `this` nem `self`. Dentro do método é uma variável comum que
guarda o valor sobre o qual o método foi chamado.

## Só num tipo que o seu pacote define

Métodos podem ser declarados num tipo definido no mesmo pacote, e em nada mais. Três tentativas que
quebram a regra, em `~/methods-nonlocal`:

```go
type Number = int

func (n int) Double() int {
	return n * 2
}

func (d time.Duration) Days() float64 {
	return d.Hours() / 24
}

func (n Number) Triple() int {
	return n * 3
}
```

```
ana@vm:~/methods-nonlocal$ go build
# example.com/nonlocal
./main.go:10:9: cannot define new methods on non-local type int
./main.go:14:9: cannot define new methods on non-local type time.Duration
./main.go:18:9: cannot define new methods on non-local type Number
```

`int` é predeclarado e não pertence a nenhum pacote seu; `time.Duration` pertence a `time`. O
terceiro é o que surpreende: `type Number = int`, com o `=`, é o alias da lição 10, um segundo nome
para `int` e não um tipo novo, então o compilador o recusa pelo mesmo motivo
que `int`. **A consequência vale mais
que a regra: todo método que um tipo tem é declarado no pacote que define o tipo**, então ler esse
pacote mostra todos eles, e importar outro pacote nunca acrescenta um.

A saída é a mesma que a lição 10 usou para as temperaturas. Defina um tipo seu por cima, e dê os
métodos a esse tipo:

```go
type Number int

func (n Number) Double() Number {
	return n * 2
}

type Span time.Duration

func (s Span) Days() float64 {
	return time.Duration(s).Hours() / 24
}
```

```
ana@vm:~/methods-local$ go run .
42
1.5
```

`Days` converte `s` de volta para `time.Duration` antes de pedir `Hours`, e a conversão não é
enfeite. Um tipo definido herda os valores e os operadores do tipo de base, e nenhum dos métodos
dele:

```
ana@vm:~/methods-span$ go build
# example.com/span
./main.go:12:16: s.Hours undefined (type Span has no field or method Hours)
```

## String, e o que o fmt imprime

A seção 03 da lição 6 declarou um `Weekday` com `iota`, imprimiu `Sunday, Monday, Saturday` e
recebeu `0 1 6`, enquanto o `time.Saturday` da biblioteca padrão imprimiu `Saturday`. A diferença
era um método. Aqui está o mesmo `Weekday` com ele, em `~/methods-days`:

```go
var names = [...]string{"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}

func (d Weekday) String() string {
	return names[d]
}

func main() {
	fmt.Println(Sunday, Monday, Saturday)
	fmt.Printf("%v %s %d\n", Saturday, Saturday, Saturday)
	fmt.Println(Saturday.String() + "!")
	fmt.Println(time.Saturday)
}
```

```
ana@vm:~/methods-days$ go run .
Sunday Monday Saturday
Saturday Saturday 6
Saturday!
Saturday
ana@vm:~/methods-days$ go doc time.Weekday.String
package time // import "time"

func (d Weekday) String() string
    String returns the English name of the day ("Sunday", "Monday", ...).

```

**Quando o tipo de um valor tem um método `String() string`, o `fmt` imprime o que esse método
devolve**, no `Println`, no `%v` e no `%s`. O `%d` continua pedindo o número e recebe 6, porque a
constante continua sendo o número; o método só muda o jeito de mostrá-la. O `time.Weekday` faz
exatamente isso, e o `go doc` mostra o método dele na mesma forma que o seu. O `fmt` não conhece o
seu tipo de antemão. Ele procura em cada valor que imprime esse método, por nome e assinatura, e
essa procura tem nome próprio, `fmt.Stringer`, que a lição 26 lê e a lição 27 explica.
