---
title: Tamanho, e o inliner
version: 1
---

Os valores da seção 03 escaparam porque algo podia alcançá-los depois. **Duas outras coisas decidem
onde um valor mora, e nenhuma tem a ver com quem aponta para ele.** Uma é o tamanho: um quadro de
pilha tem um tamanho fixado quando a função é compilada, então um valor de tamanho desconhecido nesse
momento, ou grande demais, não cabe nele. A outra é o inlining, que muda o que é "a função": quando
uma função chamada é copiada em quem a chama, os valores dela passam a pertencer ao quadro de quem
chama e são julgados lá.

## Grande demais, ou desconhecido

`why/makes.go`:

```go
package why

// Fixed makes a slice whose length is a constant.
func Fixed() int {
	s := make([]int, 64)
	return len(s)
}

// Sized makes a slice whose length arrives at run time.
func Sized(n int) int {
	s := make([]int, n)
	return len(s)
}

// Huge makes a slice of 10,000 ints, 80,000 bytes.
func Huge() int {
	s := make([]int, 10000)
	return len(s)
}

// Grid declares an array of 1 MiB.
func Grid() int {
	var g [1 << 20]byte
	return len(g)
}
```

```
ana@vm:~/escape$ go build -gcflags=-m ./why 2>&1 | grep makes.go
why/makes.go:4:6: can inline Fixed
why/makes.go:10:6: can inline Sized
why/makes.go:16:6: can inline Huge
why/makes.go:22:6: can inline Grid
why/makes.go:5:11: make([]int, 64) does not escape
why/makes.go:11:11: make([]int, n) does not escape
why/makes.go:17:11: make([]int, 10000) escapes to heap
why/makes.go:23:6: moved to heap: g
ana@vm:~/escape$ go build -gcflags=-m=2 ./why 2>&1 | grep "too large"
why/makes.go:17:11:     from make([]int, 10000) (too large for stack) at why/makes.go:17:11
why/makes.go:23:6:     from g (too large for stack) at why/makes.go:23:6
```

O `Fixed` cria 64 ints, 512 bytes, e eles ficam na pilha. O `Huge` cria 10.000 deles, 80.000 bytes, o que
passa do limite de 64 KiB para um valor que o `make` cria. O `Grid` declara 1 MiB, acima do limite
de 128 KiB para uma variável declarada, e o `-m=2` dá aos dois o mesmo motivo, **`too large for stack`**.
Nada aponta para nenhum dos dois de fora, e nada mais nas funções difere do `Fixed`.

**O `Sized` é o caso em que "does not escape" não quer dizer "nunca aloca".** O tamanho chega como
argumento, então o compilador não consegue reservar a quantidade certa no quadro. Um comentário no
código do compilador, `cmd/compile/internal/walk/builtin.go`, descreve o que ele faz em vez disso.
Ele reserva 32 bytes fixos no quadro e compila uma verificação: uma fatia que caiba neles os usa, e
uma que não caiba é alocada no heap, em execução. 32 bytes são quatro `int`s. `make([]int, 4)` não
custa nada e `make([]int, 5)` custa uma alocação, da mesma linha, e a seção 05 conta as duas. O
relatório diz `does not escape` para as duas, porque escapar é sobre tempo de vida, e a fatia não
sobrevive ao `Sized`.

## O inliner muda a resposta

`why/inline.go` chama o `New` da seção 02, cujo relatório dizia `&Point{...} escapes to heap`:

```go
package why

import "example.com/escape/point"

// Distance builds a Point with point.New and reads it straight back.
func Distance(x, y int) int {
	return point.Sum(point.New(x, y))
}
```

```
ana@vm:~/escape$ go build -gcflags=-m ./why 2>&1 | grep inline.go
why/inline.go:6:6: can inline Distance
why/inline.go:7:28: inlining call to point.New
why/inline.go:7:18: inlining call to point.Sum
why/inline.go:7:28: &point.Point{...} does not escape
```

**A mesma expressão, `&point.Point{...}`, agora não escapa.** O `New` é pequeno, o `can inline New`
disse isso, e o corpo dele foi copiado no `Distance`. A cópia de `&Point{...}` é um valor criado no
`Distance`, lido pelo `Sum`, também inlined, e nunca devolvido: fica no quadro do `Distance`. Os dois
relatórios estão certos. O `New` chamado de qualquer lugar em que não seja inlined aloca; inlined, não.

O Go faz inlining de uma função cujo custo, uma estimativa do tamanho dela, fica abaixo de um
orçamento, 80 nesta versão (`inlineMaxBudget` em `cmd/compile/internal/inline`), e o `-m=2` imprime o
custo de cada função:

```
ana@vm:~/escape$ go build -gcflags=-m=2 ./point 2>&1 | grep "can inline New"
point/point.go:8:6: can inline New with cost 7 as: func(int, int) *Point { return &Point{...} }
```

Esse orçamento, um profile dado ao compilador ou uma mudança na função chamada podem, cada um, passar
uma chamada de um lado da linha para o outro. Para ver isso acontecer, Ana proíbe o inlining do `New`
com uma **diretiva**, um comentário sem espaço depois das barras, logo acima da função:

```
ana@vm:~/escape$ sed -i "s|^func New(|//go:noinline\nfunc New(|" point/point.go
ana@vm:~/escape$ grep -B1 "^func New" point/point.go
//go:noinline
func New(x, y int) *Point {
ana@vm:~/escape$ go build -gcflags=-m ./point ./why 2>&1 | grep "point.go:10\|inline.go"
point/point.go:10:9: &Point{...} escapes to heap
why/inline.go:6:6: can inline Distance
why/inline.go:7:18: inlining call to point.Sum
```

O veredito do próprio `New` não mudou, uma linha mais abaixo por causa do comentário. O `Distance`
perdeu duas linhas: `inlining call to point.New` e `&point.Point{...} does not escape` sumiram, porque
o `Distance` agora chama o `New`, e o `Point` é do `New`, criado no heap e devolvido. Nada no `Distance`
mudou. Depois a diretiva sai de novo:

```
ana@vm:~/escape$ sed -i "/^\/\/go:noinline$/d" point/point.go
```

**O `-l` é o mesmo experimento para um build inteiro**: a seção 03 o usou no `Total`. É o jeito de ver
o que cada função decide sozinha, e o jeito errado de julgar um programa, porque o binário que vai
para produção é compilado com inlining. Leia o relatório do build que você publica, e espere que ele
mude quando uma função chamada passar do orçamento.
