---
title: Perguntando ao compilador
version: 1
---

**Nada na sintaxe do Go diz onde um valor mora.** A crença trazida de C e de Java é que `new` e `&`
põem um valor no heap e todo o resto fica na pilha. Em Go nenhuma das duas metades vale: `&Point{}`
pode morar na pilha, e um simples `int` pode acabar no heap. Quem decide é o compilador, valor por
valor, numa etapa chamada análise de escape. Um valor só pode ficar no quadro de pilha da sua função
se nada puder alcançá-lo depois que a função retorna e se o tamanho dele for conhecido quando o
código é compilado. Todo o resto é alocado no heap, e o coletor de lixo da lição 19 precisa achá-lo e
liberá-lo depois.

A decisão é tomada uma vez, na compilação, e é visível: **uma flag faz o compilador imprimi-la**. Ana
trabalha num módulo novo, `~/escape`, que ganha um pacote pequeno por pergunta:

```
ana@vm:~/escape$ go mod init example.com/escape
go: creating new go.mod: module example.com/escape
go: to add module requirements and sums:
	go mod tidy
```

O primeiro pacote é um tipo de valor e quatro funções que lidam com ele por ponteiros. Salve-o como
`point/point.go`:

```go
// Package point is a small value type and the functions that use it.
package point

// Point is a position on a grid.
type Point struct{ X, Y int }

// New returns a pointer to a new Point.
func New(x, y int) *Point {
	return &Point{X: x, Y: y}
}

// At does the same with a named variable.
func At(x, y int) *Point {
	p := Point{x, y}
	return &p
}

// Sum reads through a pointer and keeps nothing.
func Sum(p *Point) int {
	return p.X + p.Y
}

// Farther returns whichever of a and b is farther from the origin.
func Farther(a, b *Point) *Point {
	if Sum(a) >= Sum(b) {
		return a
	}
	return b
}
```

## `-gcflags=-m`

O `-gcflags` entrega uma lista de flags ao compilador, o `go tool compile`, para cada pacote que
compila, e o `-m` do compilador é documentado como "print optimization decisions". O `go build` num
pacote que não é `main` o compila e joga o resultado fora, o que faz dele o jeito barato de perguntar:

```
ana@vm:~/escape$ go build -gcflags=-m ./point
# example.com/escape/point
point/point.go:8:6: can inline New
point/point.go:13:6: can inline At
point/point.go:19:6: can inline Sum
point/point.go:24:6: can inline Farther
point/point.go:25:8: inlining call to Sum
point/point.go:25:18: inlining call to Sum
point/point.go:9:9: &Point{...} escapes to heap
point/point.go:14:2: moved to heap: p
point/point.go:19:10: p does not escape
point/point.go:24:14: leaking param: a to result ~r0 level=0
point/point.go:24:17: leaking param: b to result ~r0 level=0
```

Toda linha começa com um arquivo, uma linha e uma coluna, e **o que vem depois é uma de poucas
frases**:

| mensagem | o que diz | aqui |
|---|---|---|
| `can inline New` | a função é pequena o bastante para ser copiada em quem a chama | as quatro |
| `inlining call to Sum` | ela foi copiada nesta chamada | as duas chamadas em `Farther` |
| `&Point{...} escapes to heap` | o valor que essa expressão cria é alocado no heap | `New`, linha 9 |
| `moved to heap: p` | o mesmo veredito para uma variável com nome | `At`, linha 14 |
| `p does not escape` | a função não guarda nada para o que esse parâmetro aponta | `Sum` |
| `leaking param: a to result ~r0 level=0` | aquilo para o que `a` aponta pode sair como resultado | `Farther` |

`New` e `At` são a mesma função escrita de dois jeitos, e recebem o mesmo veredito em duas grafias:
**um ponteiro devolvido a quem chama sobrevive ao quadro em que foi criado**, então o `Point` não pode
estar nesse quadro. O `Sum` lê através do ponteiro e não guarda nada, e é isso que torna `Sum(&q)` de
graça para qualquer chamador: `q` pode ficar na pilha de quem chama.

O `Farther` é o sutil. **"Leaking param" não é uma alocação.** É um resumo que o compilador escreve
para cada parâmetro. Ele analisa uma função de cada vez, as chamadas primeiro, e quem chama
precisa saber o que a função chamada faz com um ponteiro que recebe. O `to result ~r0` diz para onde
`a` vai: para o primeiro resultado, que não tem nome no código, então o compilador o chama de `~r0`.
O `level=0` diz que é o próprio ponteiro que vai para lá, não algo alcançado através dele. Se o
`Point` de `a` escapa ou não é decidido em cada chamador, pelo que o chamador faz com o que o
`Farther` devolve. Um parâmetro que vaza para o heap, e não para um resultado, aparece como
`leaking param: c` puro, e a seção 03 encontra um.

## `-m=2`: o motivo

Dobrar a flag, `-m=2`, acrescenta o caminho que o compilador seguiu até cada veredito. O
`grep -v inlin` tira as linhas de inlining, que nesse nível vêm com um custo ao lado:

```
ana@vm:~/escape$ go build -gcflags=-m=2 ./point 2>&1 | grep -v inlin
# example.com/escape/point
point/point.go:9:9: &Point{...} escapes to heap in New:
point/point.go:9:9:   flow: ~r0 ← &{storage for &Point{...}}:
point/point.go:9:9:     from &Point{...} (spill) at point/point.go:9:9
point/point.go:9:9:     from return &Point{...} (return) at point/point.go:9:2
point/point.go:9:9: &Point{...} escapes to heap
point/point.go:14:2: p escapes to heap in At:
point/point.go:14:2:   flow: ~r0 ← &p:
point/point.go:14:2:     from &p (address-of) at point/point.go:15:9
point/point.go:14:2:     from return &p (return) at point/point.go:15:2
point/point.go:14:2: moved to heap: p
point/point.go:19:10: p does not escape
point/point.go:24:14: parameter a leaks to ~r0 for Farther with derefs=0:
point/point.go:24:14:   flow: ~r0 ← a:
point/point.go:24:14:     from return a (return) at point/point.go:26:3
point/point.go:24:17: parameter b leaks to ~r0 for Farther with derefs=0:
point/point.go:24:17:   flow: ~r0 ← b:
point/point.go:24:17:     from return b (return) at point/point.go:28:2
point/point.go:24:14: leaking param: a to result ~r0 level=0
point/point.go:24:17: leaking param: b to result ~r0 level=0
```

**Cada linha `flow:` é um passo, escrito como destino ← origem**, e as linhas `from` embaixo dela
apontam o código que deu esse passo. No `At`: o resultado `~r0` recebe `&p`, o endereço de `p`, por
causa do `return` da linha 15. Numa função de duas linhas o motivo é óbvio; a seção 06 segue um por
três funções do `hits`, onde não é. O `derefs=0` é o mesmo fato que o `level=0` da forma curta.

## A decisão, desenhada

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 412\" role=\"img\" aria-label=\"A análise de escape faz duas perguntas a cada valor criado dentro de uma função. Primeiro, o endereço dele ainda pode ser alcançado depois que a função retorna: devolvido como ponteiro, guardado numa global ou num map, capturado por uma closure que sai, dado a um parâmetro que vaza. Se sim, ele vai para o heap. Se não, a segunda: o tamanho é conhecido na compilação e está abaixo do limite? Uma variável declarada pode ter até 128 KiB, new, &amp;T{} ou make até 64 KiB, e make([]T, n) com tamanho só conhecido na execução ganha 32 bytes na pilha, conferidos quando roda. Se sim, o valor vai para a pilha e é liberado quando a função retorna; se não, vai para o heap, alocado em tempo de execução e depois achado e liberado pelo coletor.\"><defs><marker id=\"ea-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ea-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"ea-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"320\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um valor criado dentro de uma função</text><text x=\"180\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p := Point{...}   &amp;T{...}   make(...)   func() {...}</text><rect x=\"20\" y=\"100\" width=\"320\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1. O endereço dele ainda pode ser alcançado</text><text x=\"180\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">depois que a função retorna?</text><rect x=\"20\" y=\"206\" width=\"320\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2. O tamanho é conhecido na compilação</text><text x=\"180\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">e está abaixo do limite?</text><rect x=\"20\" y=\"312\" width=\"320\" height=\"62\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"330\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">na pilha</text><text x=\"180\" y=\"348\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">liberado quando a função retorna</text><text x=\"180\" y=\"364\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">does not escape</text><rect x=\"420\" y=\"100\" width=\"280\" height=\"274\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">no heap</text><text x=\"560\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">alocado em tempo de execução, depois</text><text x=\"560\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">achado e liberado pelo coletor</text><text x=\"560\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">escapes to heap   moved to heap: p</text><text x=\"436\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">alcançado depois do retorno</text><text x=\"436\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">devolvido como ponteiro</text><text x=\"436\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">guardado numa global ou num map</text><text x=\"436\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">capturado por uma closure que sai</text><text x=\"436\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dado a um parâmetro que vaza</text><text x=\"436\" y=\"292\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">grande demais, ou tamanho incerto</text><text x=\"436\" y=\"310\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">variável declarada acima de 128 KiB</text><text x=\"436\" y=\"326\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">new, &amp;T{} ou make acima de 64 KiB</text><text x=\"436\" y=\"342\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">make([]T, n) acima de 32 bytes, na execução</text><path d=\"M180 66 V96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ea-phosphor)\"></path><path d=\"M180 156 V202\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ea-phosphor)\"></path><text x=\"192\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">não</text><path d=\"M180 262 V308\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ea-phosphor)\"></path><text x=\"192\" y=\"285\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sim</text><path d=\"M340 128 H416\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ea-amber)\"></path><text x=\"378\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">sim</text><path d=\"M340 234 H416\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ea-amber)\"></path><text x=\"378\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">não</text><text x=\"20\" y=\"398\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">O compilador faz as duas perguntas a cada valor, uma vez, ao compilar; -gcflags=-m imprime cada resposta.</text></svg>", "caption": "Duas perguntas, feitas uma vez por valor, na compilação. As respostas são o que o -gcflags=-m imprime."}
```

Os limites da segunda pergunta vêm do código do compilador, `cmd/compile/internal/ir/cfg.go` na árvore
do Go: 128 KiB para uma variável declarada com `var` ou `:=`, 64 KiB para as implícitas que `new`,
`&T{}` e `make` criam. A seção 04 esbarra nos dois, e na terceira linha dessa lista, que é o único
lugar em que a resposta só se resolve em execução.

## Perguntando sobre os pacotes certos

**Sem um padrão, o `-gcflags` vale só para os pacotes nomeados na linha de comando.** As execuções
acima nomearam `./point`, e nada mais foi relatado. Isso também quer dizer que compilar um programa,
`go build -gcflags=-m .`, relata o pacote `main` e nenhum dos pacotes que o `main` importa, que num
módulo de verdade é onde está o código interessante. Um padrão na frente das flags escolhe os
pacotes:

| flag | relata |
|---|---|
| `-gcflags=-m` | os pacotes nomeados na linha de comando |
| `-gcflags='example.com/escape/...=-m'` | todo pacote cujo caminho casa, aqui o módulo inteiro |
| `-gcflags=all=-m` | todo pacote do build, a biblioteca padrão inclusive |

O `go help build` descreve a forma com padrão, e a seção 06 mede as três no `hits`. Mais duas flags do
compilador viajam do mesmo jeito: `-l` desliga o inlining, e a seção 04 o usa para ver o que cada
função decide sozinha.
