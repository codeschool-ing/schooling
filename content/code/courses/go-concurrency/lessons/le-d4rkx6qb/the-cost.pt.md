---
title: Quanto custa uma expressão regular
version: 1
---

O RE2 promete que um casamento não vai explodir. Não promete que um casamento é de graça, e dois
custos valem a medição. **Compilar um padrão é muito mais caro do que rodá-lo**, e uma expressão
regular muitas vezes é mais lenta do que duas chamadas do pacote `strings` que respondem à mesma
pergunta. O programa abaixo faz uma pergunta cem mil vezes, "esta linha de log termina num status
5xx?", de três jeitos, salvo como `cost/main.go`:

```go
// Command cost compares compiling a pattern once, compiling it every time,
// and not using a regular expression at all.
package main

import (
	"fmt"
	"regexp"
	"strings"
	"time"
)

const n = 100_000

var lines = []string{"GET /orders/1042 200", "GET /health 200", "POST /orders 500"}

func timed(name string, f func(string) bool) {
	start := time.Now()
	hits := 0
	for i := range n {
		if f(lines[i%len(lines)]) {
			hits++
		}
	}
	fmt.Printf("%-16s %6d hits %v\n", name, hits, time.Since(start).Round(100*time.Microsecond))
}

func main() {
	once := regexp.MustCompile(` 5\d\d$`)
	timed("compiled once", once.MatchString)
	timed("compiled each", func(s string) bool {
		return regexp.MustCompile(` 5\d\d$`).MatchString(s)
	})
	timed("strings only", func(s string) bool {
		return strings.HasPrefix(s[strings.LastIndexByte(s, ' ')+1:], "5")
	})
}
```

As mesmas três linhas se repetem, então todo jeito acha os mesmos 33.333 erros de servidor.
Compilado uma vez e rodado duas, porque uma execução de uma medição de tempo é uma amostra:

```
ana@vm:~/patterns$ go build -o bin/cost ./cost
ana@vm:~/patterns$ bin/cost
compiled once     33333 hits 4.2ms
compiled each     33333 hits 151.4ms
strings only      33333 hits 400µs
ana@vm:~/patterns$ bin/cost
compiled once     33333 hits 3.9ms
compiled each     33333 hits 136.9ms
strings only      33333 hits 500µs
```

**Compilar dentro do laço custou cerca de trinta e cinco vezes o que custou compilar uma vez**: o
padrão foi lido e transformado numa máquina cem mil vezes, para ser rodado uma vez cada. É o erro
que um `MustCompile` numa variável de pacote evita, e é fácil cometê-lo sem querer numa função
chamada a cada requisição. A versão sem expressão regular nenhuma foi de oito a dez vezes mais
rápida ainda do que a compilada.

## Quando usar uma

Os números não são um argumento contra expressões regulares. Quatro milissegundos para cem mil
linhas é rápido, e um padrão diz numa linha o que a versão com `strings` tem de calcular em
código. **Use `strings` quando a pergunta é simples**, um prefixo, um sufixo, um pedaço fixo de
texto; use um padrão quando a forma é o que importa, como nas linhas de log da seção 02; e compile
uma vez, nos dois casos, onde ele for muito usado.

Uma medição avulsa como esta é um guia grosseiro, e pode enganar. A lição 29 mostra como escrever
uma comparação como esta na forma de benchmark, que é como uma afirmação sobre velocidade se
resolve.
