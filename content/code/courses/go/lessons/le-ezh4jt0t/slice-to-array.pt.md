---
title: De slice para array
version: 1
---

O outro sentido vem com uma ideia errada que já foi verdade: a de que uma slice não vira array de
jeito nenhum, só pode ser copiada para um, à mão. Existem duas
conversões, e elas se comportam de forma diferente no único ponto que importa. **`[4]int(s)` copia
os quatro primeiros elementos para um array novo; `(*[4]int)(s)` não copia nada e aponta para os
quatro que a slice já tem.**

```go
package main

import "fmt"

func main() {
	s := []int{1, 2, 3, 4, 5, 6}

	c := [4]int(s)
	c[0] = 100
	fmt.Println(s, c)

	p := (*[4]int)(s)
	p[0] = 100
	fmt.Println(s, *p)
}
```

```
ana@vm:~/slicearray-conv$ go run .
[1 2 3 4 5 6] [100 2 3 4]
[100 2 3 4 5 6] [100 2 3 4]
```

`s` tem seis elementos e as duas conversões pediram quatro, o que é permitido: elas pegam os quatro
primeiros e ignoram o resto. Depois de `c[0] = 100`, `s` ainda começa com 1, porque `c` é um array
só dele, e array é valor. Depois de `p[0] = 100`, `s` começa com 100, porque `p` é um ponteiro para
os quatro primeiros elementos do array que `s` enxerga. `*p` é o array para onde ele aponta, e
`p[0]` é abreviação de `(*p)[0]`; ponteiros são assunto da lição 23.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A slice s enxerga um array com os valores de 1 a 6. p := (*[4]int)(s) é um ponteiro para os quatro primeiros elementos desse mesmo array, então escrever por p muda s. c := [4]int(s) é um array novo com uma cópia de 1, 2, 3 e 4, então escrever em c deixa s em paz.\"><defs><marker id=\"sac-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"sac-phosphor-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><text x=\"260\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">s := []int{1, 2, 3, 4, 5, 6}</text><path d=\"M262 52 L262 46\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M262 46 L458 46\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M458 46 L458 52\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">*p</text><rect x=\"260\" y=\"58\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"310\" y=\"58\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"360\" y=\"58\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><rect x=\"410\" y=\"58\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><rect x=\"460\" y=\"58\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><rect x=\"510\" y=\"58\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"572\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o array por trás de s</text><text x=\"30\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">p := (*[4]int)(s)</text><rect x=\"60\" y=\"58\" width=\"70\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">p</text><path d=\"M130 73 L256 73\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sac-phosphor)\"></path><text x=\"30\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o mesmo array:</text><text x=\"30\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">escrever por p muda s</text><path d=\"M285 92 L285 162\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sac-phosphor-dim)\"></path><path d=\"M335 92 L335 162\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sac-phosphor-dim)\"></path><path d=\"M385 92 L385 162\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sac-phosphor-dim)\"></path><path d=\"M435 92 L435 162\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sac-phosphor-dim)\"></path><text x=\"472\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">copiado</text><rect x=\"260\" y=\"168\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"310\" y=\"168\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"360\" y=\"168\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><rect x=\"410\" y=\"168\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><text x=\"30\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">c := [4]int(s)</text><text x=\"472\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um array novo, só dele:</text><text x=\"472\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">escrever em c deixa s em paz</text></svg>", "caption": "Duas conversões da mesma slice. A conversão para ponteiro divide o array da slice; a conversão para array copia dele."}
```

Então a escolha é a pergunta que a lição 12 fazia o tempo todo: quem mais enxerga esta memória? Use
a conversão para array quando quiser um valor que ninguém mais consegue mudar. Use o ponteiro só
quando a intenção é trabalhar nos próprios elementos da slice por meio de um tipo de tamanho fixo.

## Go mais antigo recusava as duas

As duas conversões chegaram em momentos diferentes, e a linha `go` do `go.mod` decide quais um
módulo pode usar, como a lição 2 mostrou. Recuar essa linha é o jeito mais rápido de ver quando:

```
ana@vm:~/slicearray-conv$ go mod edit -go=1.19 && go build
# example.com/conv
./main.go:8:14: cannot convert s (variable of type []int) to type [4]int: conversion of slice to array requires go1.20 or later (-lang was set to go1.19; check go.mod)
ana@vm:~/slicearray-conv$ go mod edit -go=1.16 && go build
# example.com/conv
./main.go:8:14: cannot convert s (variable of type []int) to type [4]int: conversion of slice to array requires go1.20 or later (-lang was set to go1.16; check go.mod)
./main.go:12:17: cannot convert s (variable of type []int) to type *[4]int: conversion of slice to array pointer requires go1.17 or later (-lang was set to go1.16; check go.mod)
ana@vm:~/slicearray-conv$ go mod edit -go=1.27.1 && go build && echo built
built
```

A conversão para ponteiro precisa de Go 1.17 e a conversão para array, de Go 1.20. Código mais
antigo que isso copia à mão ou com `copy`, e você ainda vai ler bastante código assim; nada na forma
nova torna a antiga errada.

## Curta demais é pânico

Pedir mais elementos do que a slice tem não pode ser conferido pelo compilador, pelo mesmo motivo
que o `mid[3]` da lição 12 não pôde: o comprimento de uma slice só é conhecido quando o programa
roda.

```go
package main

import "fmt"

func main() {
	s := []int{1, 2}
	fmt.Println([4]int(s))
}
```

```
ana@vm:~/slicearray-short$ go run .
panic: runtime error: cannot convert slice with length 2 to array or pointer to array with length 4

goroutine 1 [running]:
main.main()
	/home/ana/slicearray-short/main.go:7 +0x9
exit status 2
```

A mensagem dá os dois comprimentos e vale para as duas conversões. **Mais longa tudo bem, mais curta
entra em pânico**, então uma conversão de dados que não foi você que produziu fica depois de uma
conferência de `len`.

## Onde isso é usado

A conversão vale a pena onde uma API pede um array porque o tamanho faz parte do significado. Um
endereço IPv4 tem exatamente quatro bytes, e o `net/netip` diz isso nos seus tipos:

```
ana@vm:~/slicearray-ip$ go doc net/netip.AddrFrom4
package netip // import "net/netip"

func AddrFrom4(addr [4]byte) Addr
    AddrFrom4 returns the address of the IPv4 address given by the bytes in
    addr.

```

Bytes que chegam de um arquivo ou da rede vêm como slice. Aqui são seis, dos quais os quatro
primeiros são um endereço:

```go
package main

import (
	"fmt"
	"net/netip"
)

func main() {
	raw := []byte{192, 168, 0, 10, 0, 80}
	addr := netip.AddrFrom4([4]byte(raw))
	fmt.Println(addr)
}
```

```
ana@vm:~/slicearray-ip$ go run .
192.168.0.10
```

`[4]byte(raw)` pegou os quatro primeiros bytes e deixou em paz os dois seguintes. `addr` agora
guarda a sua própria cópia desses quatro, aconteça o que acontecer com `raw` depois.

Dá vontade de escrever `[4]byte(raw[:4])`, porque diz "quatro" duas vezes e parece mais cuidadoso.
**É menos cuidadoso: `raw[:4]` é medido contra a capacidade, então pode passar do comprimento e
entregar à conversão bytes que não fazem parte da slice.** Um buffer reaproveitado de um registro
para o seguinte é exatamente essa situação:

```go
package main

import "fmt"

func main() {
	buf := []byte{192, 168, 0, 10, 0, 80}
	short := buf[:3]

	fmt.Println([4]byte(short[:4]))
	fmt.Println([4]byte(short))
}
```

```
ana@vm:~/slicearray-stale$ go run .
[192 168 0 10]
panic: runtime error: cannot convert slice with length 3 to array or pointer to array with length 4

goroutine 1 [running]:
main.main()
	/home/ana/slicearray-stale/main.go:10 +0x8a
exit status 2
```

`short` guarda três bytes. A primeira linha imprimiu quatro mesmo assim, porque `short[:4]` entrou
na capacidade e pegou o `10` que tinha sobrado no buffer, e nada reclamou. A segunda linha converteu
o próprio `short`, e a conversão conferiu o comprimento e recusou. Converta a slice que você tem, e
deixe a conversão fazer a conferência para a qual foi feita.
