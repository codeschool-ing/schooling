---
title: Método ou função
version: 1
---

Quem foi treinado com objetos busca um método por hábito, e lê um pacote cheio de funções comuns
como um projeto que ninguém terminou. A biblioteca padrão de Go diz o contrário. **Um método é a
escolha certa quando o comportamento pertence a um valor de um tipo seu, ou quando alguma coisa
precisa encontrá-lo no tipo pelo nome; fora isso, uma função é a escolha simples e normal.** A
seção 02 encontrou os dois motivos sem dar nome a eles.

## Os dados do próprio tipo

`r.Area()` lê os campos de `r` e nada mais. `d.String()` transforma `d` no nome dele. Um
comportamento assim é sobre um valor, e colocá-lo no tipo o mantém perto dos dados de que depende e
lhe dá um nome que soa como uma pergunta ao valor.

Isso também dá um escopo ao nome. **O nome de um método pertence ao tipo, então dois tipos podem ter
cada um a sua `Area`.** Duas funções do pacote não podem ter o mesmo nome, e a lição 20 mostrou que
Go não tem sobrecarga para distingui-las pelo tipo do parâmetro. Escritas como funções, em
`~/methods-funcs`:

```go
func Area(r Rect) float64 {
	return r.W * r.H
}

func Area(c Circle) float64 {
	return math.Pi * c.R * c.R
}
```

```
ana@vm:~/methods-funcs$ go build
# example.com/funcs
./main.go:20:6: Area redeclared in this block
	./main.go:16:6: other declaration of Area
```

Como funções elas teriam de ser `RectArea` e `CircleArea`. Como métodos, em `~/methods-shapes`,
cada tipo tem a sua e a chamada diz qual pelo valor na frente dela:

```go
func (r Rect) Area() float64 {
	return r.W * r.H
}

func (c Circle) Area() float64 {
	return math.Pi * c.R * c.R
}

func main() {
	fmt.Println(Rect{W: 3, H: 4}.Area())
	fmt.Printf("%.2f\n", Circle{R: 1}.Area())
}
```

```
ana@vm:~/methods-shapes$ go run .
12
3.14
```

## Alguma coisa precisa achá-lo pelo nome

O `String` do `Weekday` na seção 02 não poderia ter sido uma função. Uma `func WeekdayName(d Weekday)
string` funcionaria quando você a chamasse, e `fmt.Println(Saturday)` continuaria imprimindo `6`,
porque o `fmt` procura um método chamado `String` no tipo do valor e nunca uma função em algum lugar
do seu pacote. **Um código que não conhece o seu tipo de antemão só consegue chegar a ele pelos
métodos.** Esse é o segundo motivo, e é o que cresce: a lição 27 mostra a regra do `fmt`
generalizada como interface, que é uma lista de métodos, e um tipo só satisfaz uma com métodos.

## Quando uma função é o certo

Todo o resto. O pacote `strings` é o exemplo de sempre. `string` é um tipo predeclarado, então pela
regra da seção 02 nenhum pacote pode acrescentar métodos a ele. O pacote é, em vez disso, uma coleção
de funções que recebem uma string como primeiro argumento:

```
ana@vm:~/methods-shapes$ go doc strings | grep -c "^func"
56
ana@vm:~/methods-shapes$ go doc strings | grep "^type"
type Builder struct{ ... }
type Reader struct{ ... }
type Replacer struct{ ... }
```

56 funções, e três tipos que têm métodos, sim. Vale reparar nesses três: um `Builder` guarda o texto
que já montou, que a lição 9 usou, então as operações dele são sobre os dados daquele valor, e
`b.WriteString(s)` é um método. A regra que pôs as funções no pacote pôs os métodos nos tipos.

Uma função também é o certo quando nenhum valor sozinho está no comando. Comparar dois retângulos
trata os dois igualmente, e `Overlap(a, b)` diz isso, enquanto `a.Overlap(b)` sugere que `a` importa
mais. E a biblioteca padrão às vezes oferece os dois, o que mostra que a escolha é sobre a chamada
que se lê melhor:

```
ana@vm:~/methods-shapes$ go doc time.Since
package time // import "time"

func Since(t Time) Duration
    Since returns the time elapsed since t. It is shorthand for
    time.Now().Sub(t).

```

`t.Sub(u)` é um método de `time.Time`, e `time.Since(t)` é uma função porque "há quanto tempo" é uma
pergunta tanto sobre o agora quanto sobre `t`. Nenhum dos dois é mais correto. Por baixo, uma chamada
de método é uma chamada de função com o receptor passado como parâmetro, e a seção 04 mostra isso
diretamente.
