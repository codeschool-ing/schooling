---
title: Quanto custa o heap
version: 1
---

O relatório é uma previsão, feita na compilação sobre código que ainda não rodou. **O que um programa
faz de fato é contado em execução, e os dois podem discordar nos dois sentidos.** O `Sized` da seção 04
não escapa e mesmo assim aloca com cinco elementos; o `Box` da seção 03 escapa e, como esta seção
mostra, às vezes não aloca. Então o relatório diz onde olhar, e duas ferramentas do pacote `testing`
dizem o que aconteceu: o `testing.AllocsPerRun`, que conta, e um benchmark rodado com `-benchmem`, que
conta e cronometra.

## Contando alocações

O `testing.AllocsPerRun(runs, f)` chama `f` uma vez para aquecer, depois `runs` vezes, e devolve a
média de alocações no heap por chamada. Os argumentos e os resultados passam por variáveis do pacote,
porque um argumento constante deixaria o compilador calcular a resposta de antemão e um resultado não
usado o deixaria apagar a chamada. `why/allocs_test.go`:

```go
package why

import "testing"

// Package-level variables, so that the compiler can neither work out the
// arguments in advance nor throw the results away.
var (
	small, large = 7, 1000
	four, five   = 4, 5
	sinkAny      any
	sinkInt      int
)

func TestAllocs(t *testing.T) {
	cases := []struct {
		name string
		f    func()
	}{
		{"Box(7)", func() { sinkAny = Box(small) }},
		{"Box(1000)", func() { sinkAny = Box(large) }},
		{"Sized(4)", func() { sinkInt = Sized(four) }},
		{"Sized(5)", func() { sinkInt = Sized(five) }},
		{"Distance(4, 5)", func() { sinkInt = Distance(four, five) }},
	}
	for _, c := range cases {
		t.Logf("%-15s %v allocs", c.name, testing.AllocsPerRun(1000, c.f))
	}
}
```

```
ana@vm:~/escape$ go test -run Allocs -v ./why
=== RUN   TestAllocs
    allocs_test.go:26: Box(7)          0 allocs
    allocs_test.go:26: Box(1000)       1 allocs
    allocs_test.go:26: Sized(4)        0 allocs
    allocs_test.go:26: Sized(5)        1 allocs
    allocs_test.go:26: Distance(4, 5)  0 allocs
--- PASS: TestAllocs (0.00s)
PASS
ok  	example.com/escape/why	(cached)
```

**O `Box(7)` não aloca nada, embora o relatório tenha dito `n escapes to heap`.** O runtime mantém uma
tabela com os valores de 0 a 255, `staticuint64s` em `runtime/iface.go`, e uma interface que guarda um
deles aponta para a tabela em vez de para uma cópia nova. O `Box(1000)` pega os seus oito bytes do
heap. O `Sized` se divide exatamente onde a seção 04 pôs a linha: quatro `int`s cabem nos 32 bytes
reservados no quadro e cinco não. O `Distance`, com o `New` inlined, não aloca nada.

## Cronometrando

Três benchmarks, em `why/cost_test.go`:

```schooling-example
{
  "language": "go",
  "file": "why/cost_test.go",
  "parts": [
    {
      "code": "package why\n\nimport (\n\t\"fmt\"\n\t\"testing\"\n\n\t\"example.com/escape/point\"\n)\n\nfunc BenchmarkDistance(b *testing.B) {\n\tfor b.Loop() {\n\t\tsinkInt = Distance(four, five)\n\t}\n}\n",
      "note": "O `Distance` como a seção 04 o deixou, com o `New` inlined. Os argumentos vêm das variáveis do pacote em `allocs_test.go`, o resultado vai para `sinkInt`, e o `b.Loop` roda o corpo quantas vezes for preciso para ter um tempo estável."
    },
    {
      "code": "// call does Distance's work behind a call that is never inlined, with the\n// Point in call's own frame.\n//\n//go:noinline\nfunc call(x, y int) int {\n\tp := point.Point{X: x, Y: y}\n\treturn point.Sum(&p)\n}\n\nfunc BenchmarkCall(b *testing.B) {\n\tfor b.Loop() {\n\t\tsinkInt = call(four, five)\n\t}\n}\n",
      "note": "**O controle.** O `call` faz o trabalho do `Distance`, mas o `//go:noinline` o mantém como chamada de verdade e o `Point` é uma variável local que nunca sai do quadro dele. Então ele paga por uma chamada e por mais nada, e a diferença entre ele e um `Distance` que aloca é a alocação."
    },
    {
      "code": "func BenchmarkSized(b *testing.B) {\n\tfor _, n := range []int{4, 5, 64, 1024} {\n\t\tb.Run(fmt.Sprint(n), func(b *testing.B) {\n\t\t\tfor b.Loop() {\n\t\t\t\tsinkInt = Sized(n)\n\t\t\t}\n\t\t})\n\t}\n}",
      "note": "Um sub-benchmark por tamanho, que o `b.Run` batiza com o número, dos dois lados dos 32 bytes e bem além deles."
    }
  ]
}
```

```
ana@vm:~/escape$ go test -run '^$' -bench . -benchmem ./why
goos: linux
goarch: amd64
pkg: example.com/escape/why
cpu: Intel(R) Xeon(R) Processor
BenchmarkDistance-4   	1000000000	         0.5395 ns/op	       0 B/op	       0 allocs/op
BenchmarkCall-4       	1000000000	         0.8222 ns/op	       0 B/op	       0 allocs/op
BenchmarkSized/4-4    	1000000000	         0.5401 ns/op	       0 B/op	       0 allocs/op
BenchmarkSized/5-4    	32446816	        38.92 ns/op	      48 B/op	       1 allocs/op
BenchmarkSized/64-4   	 5453491	       208.4 ns/op	     512 B/op	       1 allocs/op
BenchmarkSized/1024-4 	 1000000	      1901 ns/op	    8192 B/op	       1 allocs/op
PASS
ok  	example.com/escape/why	6.246s
```

**0.5395 ns é o que custa uma volta do laço quando não sobra nada para fazer**: o `Distance` virou uma
soma depois do inlining, e o `Sized/4` virou nada, já que ninguém lê a fatia. O `call` acrescenta uma
chamada de verdade e chega a 0.8222 ns. De cinco elementos em diante, toda linha tem `1 allocs/op`, e
o preço sobe com o tamanho: 48 bytes e 38.92 ns, 512 bytes e 208.4 ns, 8192 bytes e 1901 ns. Cinco
`int`s são 40 bytes e voltam como 48, porque o alocador entrega memória num conjunto fixo de tamanhos
e arredonda para cima. O tempo cresce com os bytes porque o alocador precisa achá-los e zerá-los, e
porque mais bytes alocados fazem o coletor rodar mais vezes.

Depois, a mesma função com e sem o escape: a diretiva da seção 04 volta para o `New`, e os dois
benchmarks rodam de novo.

```
ana@vm:~/escape$ sed -i "s|^func New(|//go:noinline\nfunc New(|" point/point.go
ana@vm:~/escape$ go test -run Allocs -v ./why | grep Distance
    allocs_test.go:26: Distance(4, 5)  1 allocs
ana@vm:~/escape$ go test -run '^$' -bench 'Distance|Call' -benchmem ./why
goos: linux
goarch: amd64
pkg: example.com/escape/why
cpu: Intel(R) Xeon(R) Processor
BenchmarkDistance-4   	67297569	        17.03 ns/op	      16 B/op	       1 allocs/op
BenchmarkCall-4       	1000000000	         0.7961 ns/op	       0 B/op	       0 allocs/op
PASS
ok  	example.com/escape/why	1.954s
ana@vm:~/escape$ sed -i "/^\/\/go:noinline$/d" point/point.go
```

**Uma alocação de 16 bytes levou o `Distance` de 0.5395 ns para 17.03 ns**, enquanto o `call`, que paga
uma chamada e nenhuma alocação, ficou em 0.7961 ns. A chamada é uma fração de nanossegundo; o heap é o
resto, uns dezesseis. São números de uma execução numa máquina compartilhada, então confie na ordem de grandeza e não
nos dígitos: dezenas de nanossegundos contra menos de um.

## Para onde vai o resto do preço

**O ns/op não é a conta inteira.** O benchmark cronometra a alocação em si e a parte do trabalho do
coletor que caiu na goroutine que o roda. O resto vem depois e em outro lugar: todo objeto no heap
precisa ser achado e liberado pelo coletor, que a lição 19 desmonta, e parte desse trabalho roda em
outros processadores, fora desse número. Um valor na pilha não custa nem uma coisa nem outra, porque
um quadro é liberado quando a função retorna.

Dezessete nanossegundos não são nada uma vez. **Importam no ritmo em que um caminho quente roda**: uma
vez por linha de log, por requisição, por elemento de uma fatia grande. É aí que a análise de escape
se paga, e a seção 06 a leva ao caminho quente do `hits`, onde acontece uma alocação por linha.
