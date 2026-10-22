---
title: RE2, e o tempo que ele promete
version: 1
---

As expressões regulares da maioria das linguagens são motores com retrocesso (*backtracking*): eles
tentam um jeito de casar e, quando falha, voltam e tentam o próximo. Isso compra recursos, e tem um
preço que só aparece na entrada errada. **O `regexp` de Go é o RE2: roda em tempo proporcional ao
tamanho do texto, seja qual for o padrão, e recusa os recursos que quebrariam essa promessa.**

Dois desses recursos são referências a um grupo anterior e *lookahead*. Salvo como `nope/main.go`:

```go
// Command nope asks for two things RE2 does not do.
package main

import (
	"fmt"
	"regexp"
)

func main() {
	for _, expr := range []string{`(\w+) \1`, `\d+(?= ms)`} {
		_, err := regexp.Compile(expr)
		fmt.Println(err)
	}
}
```

```
ana@vm:~/patterns$ go run ./nope
error parsing regexp: invalid escape sequence: `\1`
error parsing regexp: invalid or unsupported Perl syntax: `(?=`
```

`\1`, "o mesmo texto que o primeiro grupo casou", e `(?=`, "seguido de, sem consumir", são os dois
recusados quando o padrão é compilado, com uma mensagem dizendo qual. **Um padrão copiado de outra
linguagem pode falhar aqui exatamente por isso**, e o conserto é fazer essa parte em Go: achar os
candidatos com a expressão e comparar as duas palavras com `==`.

## A entrada que faz um motor com retrocesso travar

`^(a+)+$` numa sequência de letras `a` seguida de um `b` não tem como casar, e um motor com
retrocesso prova isso tentando todo jeito de dividir os `a`s entre o `+` de dentro e o de fora.
Existem cerca de dois elevado a n desses jeitos. O mesmo padrão e as mesmas entradas, cronometrados
em Go, salvo como `evil/main.go`:

```go
// Command evil times a pattern that makes backtracking engines give up.
package main

import (
	"fmt"
	"regexp"
	"strings"
	"time"
)

func main() {
	re := regexp.MustCompile(`^(a+)+$`)
	for _, n := range []int{20, 22, 24, 26, 1000} {
		s := strings.Repeat("a", n) + "b"
		start := time.Now()
		ok := re.MatchString(s)
		fmt.Printf("n=%d match=%v %v\n", n, ok, time.Since(start).Round(time.Microsecond))
	}
}
```

E em Python, cujo módulo `re` é um motor com retrocesso, como `evil.py`:

```python
# evil.py: the same pattern and the same inputs, through Python's re module.
import re, time

pattern = re.compile(r"^(a+)+$")
for n in (20, 22, 24, 26):
    s = "a" * n + "b"
    start = time.perf_counter()
    ok = pattern.match(s) is not None
    print(f"n={n} match={ok} {time.perf_counter() - start:.2f}s")
```

```
ana@vm:~/patterns$ go run ./evil
n=20 match=false 45µs
n=22 match=false 2µs
n=24 match=false 1µs
n=26 match=false 1µs
n=1000 match=false 39µs
ana@vm:~/patterns$ python3 --version
Python 3.13.16
ana@vm:~/patterns$ python3 evil.py
n=20 match=False 0.03s
n=22 match=False 0.13s
n=24 match=False 0.52s
n=26 match=False 2.07s
```

**O tempo do Python quadruplicou a cada dois `a`s a mais**: 0,03 segundo com 20, mais de dois
segundos com 26, e mais alguns caracteres teriam levado minutos. Go respondeu em microssegundos com
26 e com 1.000; a primeira linha dele inclui o tempo de montar o casador. Esse é o formato de uma
falha real, muitas vezes chamada de ReDoS: um padrão na validação de um formulário web, e uma
requisição com um valor longo, quase casando, toma o processador de um servidor enquanto o motor
continuar tentando. Com o RE2 o pior caso é o tamanho da entrada, então a defesa é o próprio motor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Tempo para não casar ^(a+)+$ contra n letras a e um b. O re do Python leva 0,03, 0,13, 0,52 e 2,07 segundos com n igual a 20, 22, 24 e 26, cada barra quatro vezes a anterior. O regexp de Go leva alguns microssegundos em todo n, pequeno demais para desenhar nesta escala.\"><rect x=\"160\" y=\"227.2\" width=\"56\" height=\"2.8\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"188\" y=\"217.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,03 s</text><path d=\"M222 230 H252\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><text x=\"188\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><rect x=\"290\" y=\"218.1\" width=\"56\" height=\"11.9\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"318\" y=\"208.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,13 s</text><path d=\"M352 230 H382\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><text x=\"318\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">22</text><rect x=\"420\" y=\"182.3\" width=\"56\" height=\"47.7\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"448\" y=\"172.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0,52 s</text><path d=\"M482 230 H512\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><text x=\"448\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><rect x=\"550\" y=\"40.0\" width=\"56\" height=\"190.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"578\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2,07 s</text><path d=\"M612 230 H642\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><text x=\"578\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">26</text><path d=\"M140 230 H690\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"415\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">n, o número de letras a</text><rect x=\"30\" y=\"30\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"50\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">re do Python, com retrocesso</text><path d=\"M30 60 H44\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><text x=\"50\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">regexp de Go, RE2: microssegundos, uma linha no eixo</text></svg>", "caption": "O evil/main.go e o evil.py na mesma máquina: cada dois caracteres a mais multiplicam o tempo do Python por quatro e deixam o de Go onde estava."}
```

Isso não torna todo padrão barato. Uma entrada longa ainda custa o seu tamanho, e um programa que
lê texto não confiável ainda deve limitar quanto lê, com `io.LimitReader` por exemplo.
