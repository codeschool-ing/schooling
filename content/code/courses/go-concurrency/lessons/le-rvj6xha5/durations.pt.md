---
title: Uma duração é um número de nanossegundos
version: 1
---

`time.Sleep(time.Second)` aparece neste curso desde a lição 1, e parece um número com uma unidade
grudada. **Um `time.Duration` é um `int64` que conta nanossegundos, com um tipo só dele**, e quase
tudo o que esta seção mostra decorre dessa frase: como uma duração é impressa, por que ela
multiplica do jeito que multiplica e que intervalo ela consegue guardar.

O primeiro programa desmonta uma duração, salvo como `dur.go`:

```go
// Command dur shows what a time.Duration is and how it prints.
package main

import (
	"fmt"
	"time"
)

func main() {
	d := 90 * time.Minute
	fmt.Println(d, int64(d))
	fmt.Println(d.Hours(), d.Minutes())

	p, err := time.ParseDuration("1h15m30.5s")
	fmt.Println(p, err)
	_, err = time.ParseDuration("3 days")
	fmt.Println(err)

	n := 4
	fmt.Println(time.Duration(n) * time.Second)
	fmt.Println(d.Round(time.Hour), d.Truncate(time.Hour))
}
```

```
ana@vm:~/clock$ go run dur.go
1h30m0s 5400000000000
1.5 90
1h15m30.5s <nil>
time: unknown unit " days" in duration "3 days"
4s
2h0m0s 1h0m0s
```

Noventa minutos foram impressos como `1h30m0s`, porque `Duration` tem um método `String`, e como
5.400.000.000.000 depois de convertidos para um `int64` comum: essa quantidade de nanossegundos.
`Hours` e `Minutes` devolvem um `float64`, daí `1.5` e `90`. **`ParseDuration` lê a mesma notação
que `String` escreve**, o que a torna o formato natural para uma duração numa flag ou num arquivo
de configuração, como faz a lição 21. As unidades dela param na hora. `3 days` é recusado, porque
um dia nem sempre tem 24 horas onde os relógios mudam, e o pacote deixa esse julgamento com você.
`Round` e `Truncate` levam a um múltiplo da unidade, e foi assim que todo tempo deste curso foi
impresso.

Um `int64` de nanossegundos guarda cerca de 292 anos, coisa que nenhum programa que mede um
intervalo alcança.

## O tipo é o que importa

A quinta linha converteu `n` antes de multiplicar, e precisava. Sem a conversão, num diretório
próprio como `main.go`:

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	n := 4
	fmt.Println(n * time.Second)
}
```

```
ana@vm:~/clock/mismatch$ go build .
# example.com/clock/mismatch
./main.go:10:14: invalid operation: n * time.Second (mismatched types int and time.Duration)
```

`4 * time.Second` compila, porque uma constante sem tipo assume o tipo de onde é usada, como a
lição 10 de `go` mostrou. Uma variável já tem tipo, e Go não converte nada por você. **A recusa é o
que faz o `Duration` valer a pena.** Uma função que recebe um `time.Duration` não pode receber um
`4` solto por engano, e ninguém precisa adivinhar se eram segundos ou milissegundos.

## Dois relógios dentro de uma leitura

O relógio de parede de um computador pode pular: uma pessoa o acerta, ou o serviço de hora da rede
o puxa para a frente ou para trás. Um intervalo medido com ele pode sair errado, até negativo.
**Por isso `time.Now` faz duas leituras, o relógio de parede e um relógio monotônico que só anda
para a frente**, e a segunda vai junto no valor. Salvo como `mono.go`:

```go
// Command mono measures an interval with the clock that cannot go backwards.
package main

import (
	"fmt"
	"strings"
	"time"
)

func main() {
	start := time.Now()
	s := start.String()
	fmt.Println("reading carries:", s[strings.Index(s, "m="):])
	time.Sleep(250 * time.Millisecond)
	fmt.Println("elapsed:", time.Since(start).Round(time.Millisecond))
	fmt.Println("stripped:", strings.Contains(start.Round(0).String(), "m="))
}
```

```
ana@vm:~/clock$ go run mono.go
reading carries: m=+0.000103412
elapsed: 251ms
stripped: false
```

O `m=+0.000103412` no fim de um `time.Time` impresso é a leitura monotônica, em segundos desde que
o processo começou. `time.Since` e `Sub` a usam sempre que os dois valores têm uma, então os 251
milissegundos acima estariam certos mesmo que alguém tivesse mexido no relógio de parede durante a
espera. `Round(0)` a descarta, que é o que deve acontecer com um valor gravado num arquivo ou
comparado com um de outra máquina: a leitura monotônica não significa nada fora do processo que a
fez.
