---
title: O que o reflect enxerga num valor
version: 1
---

Tudo o que o curso `go` ensinou sobre tipos fica resolvido antes de o programa rodar. O compilador
sabe que `x` é um `int`, recusa `x.Path` e não deixa nada para conferir depois. **A reflexão é o
único caminho de volta: um programa perguntando, enquanto roda, qual é o tipo de um valor, e então
lendo ou alterando o valor por meio da resposta.** O `encoding/json` é o exemplo que todo mundo já
usou. Ele foi compilado muito antes de a sua struct existir, e mesmo assim imprime os seus campos
pelos nomes.

Muita gente acredita que a reflexão é o jeito de o Go escrever código para muitos tipos de uma vez.
Isso era meio verdade antes dos generics. Desde o Go 1.18, uma função que serve para muitos tipos é
escrita com parâmetros de tipo e conferida pelo compilador, como mostraram as lições 30 e 31 do
curso `go`. **A reflexão é para o outro caso: código que não tem como saber o tipo nem quando é
compilado**, porque o tipo pertence a alguém que vai escrevê-lo depois. As lições 21 a 24 são as
portas de escape do curso, e esta trata a reflexão do mesmo jeito que as outras três: o que ela
consegue fazer, quanto custa e quando deixá-la de lado.

## Duas perguntas: o tipo e o valor

O pacote tem duas portas de entrada. `reflect.TypeOf` responde "que tipo é este" com um
`reflect.Type`, e `reflect.ValueOf` devolve um `reflect.Value`, que guarda o próprio valor e aceita
perguntas sobre ele. Um programa que passa oito valores diferentes pelas duas, em `~/reflect`,
`typeof/main.go`:

```go
// Command typeof prints what reflect.TypeOf and reflect.ValueOf find in a
// few values of different types.
package main

import (
	"errors"
	"fmt"
	"reflect"
)

// Celsius is a float64 with a name of its own.
type Celsius float64

// PathCount has the shape of one row of tally.Top.
type PathCount struct {
	Path string
	Hits int
}

func main() {
	var err error
	values := []any{
		42,
		"hits",
		Celsius(21.5),
		PathCount{"/login", 2576},
		&PathCount{"/login", 2576},
		[]int{7, 8},
		errors.New("disk full"),
		err,
	}
	for _, x := range values {
		t := reflect.TypeOf(x)
		v := reflect.ValueOf(x)
		fmt.Printf("type %-20v kind %-8v value %v\n", t, v.Kind(), v)
	}

	p := reflect.ValueOf(&PathCount{"/login", 2576})
	s := p.Elem()
	fmt.Println(p.Kind(), "->", s.Kind(), s.Type(), "with", s.NumField(), "fields")
	for f, fv := range s.Fields() {
		fmt.Printf("  %s %v = %v\n", f.Name, f.Type, fv)
	}
}
```

O `PathCount` aqui tem o formato da linha que o `tally.Top` devolve na lição 1, sem as tags; a seção
03 volta a elas. Rodado uma vez:

```
ana@vm:~/reflect$ go run ./typeof
type int                  kind int      value 42
type string               kind string   value hits
type main.Celsius         kind float64  value 21.5
type main.PathCount       kind struct   value {/login 2576}
type *main.PathCount      kind ptr      value &{/login 2576}
type []int                kind slice    value [7 8]
type *errors.errorString  kind ptr      value disk full
type <nil>                kind invalid  value <invalid reflect.Value>
ptr -> struct main.PathCount with 2 fields
  Path string = /login
  Hits int = 2576
```

**`Type` é o tipo exato, e `Kind` é a família a que ele pertence.** `Celsius` é um tipo próprio,
`main.Celsius`, e o kind dele é `float64`, porque por baixo é isso que ele é. Existem 26 kinds e um
`Invalid`, de `Bool` a `UnsafePointer`, e é nessa lista curta que o código reflexivo faz o switch: um
codificador de JSON tem um único jeito de escrever qualquer kind `float64`, seja qual for o nome do
tipo. O kind de um ponteiro aparece como `ptr`, e uma slice é uma slice, seja do que for.

Duas linhas merecem um olhar mais atento. O `errors.New` devolveu um `error`, mas o tipo impresso é
`*errors.errorString`. **O `TypeOf` nunca vê o tipo estático, só o dinâmico**, porque quando ele
roda o valor já foi posto dentro de um `any` e o tipo de interface já sumiu. A última linha é um
`error` nil, e não há nada nele para ver: o `TypeOf` devolve `nil`, e o `ValueOf` devolve o `Value`
zero, cujo kind é `Invalid`. Qualquer método que precise de um valor de verdade entra em pânico com
ele.

## Seguindo um ponteiro

O último bloco da saída vai um passo além. `reflect.ValueOf(&PathCount{...})` é um ponteiro, e **o
`Elem` o segue até a struct para a qual ele aponta**, como o `*p` faz no código comum. Só então as
perguntas de struct fazem sentido: o `NumField` diz 2, e o `Fields` devolve um iterador sobre a
descrição e o valor de cada campo, então um `for range` simples os percorre por nome e tipo. Pular o
`Elem` é um erro que o compilador não enxerga: o `go doc reflect.Value.NumField` diz que ele entra em
pânico se o kind não for `Struct`, e o kind de um ponteiro é `Pointer`.

## O que há por baixo: um `any`

`TypeOf` e `ValueOf` recebem um parâmetro do tipo `any`, e o truque todo está aí. O comando go mostra
a assinatura, e o próprio código-fonte do toolchain mostra o que as funções fazem com ele:

```
ana@vm:~/reflect$ go doc reflect.TypeOf
package reflect // import "reflect"

func TypeOf(i any) Type
    TypeOf returns the reflection Type that represents the dynamic type of i.
    If i is a nil interface value, TypeOf returns nil.

ana@vm:~/reflect$ sed -n 1367,1369p /usr/local/go/src/reflect/type.go
func TypeOf(i any) Type {
	return toType(abi.TypeOf(i))
}
ana@vm:~/reflect$ sed -n 158,169p /usr/local/go/src/reflect/value.go
func unpackEface(i any) Value {
	e := (*abi.EmptyInterface)(unsafe.Pointer(&i))
	t := e.Type
	if t == nil {
		return Value{}
	}
	f := flag(t.Kind())
	if !t.IsDirectIface() {
		f |= flagIndir
	}
	return Value{t, e.Data, f}
}
```

A lição 28 do curso `go` descreveu um `any` como um valor que esqueceu o tipo estático e guardou o
dinâmico. Na memória, **um `any` são duas palavras**: uma aponta para um descritor de tipo que o
compilador escreveu para o tipo do valor, e a outra aponta para os dados. O `unpackEface` lê essas
duas palavras direto da interface, `e.Type` e `e.Data`, e devolve `Value{t, e.Data, f}`: as mesmas
duas palavras, mais uma `flag` que registra o kind e se o valor pode ser alterado. O `TypeOf` fica só
com a primeira palavra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"Um any guarda duas palavras. A palavra do tipo aponta para um descritor de tipo escrito pelo compilador, que diz main.PathCount, kind struct, e os campos Path string e Hits int. A palavra dos dados aponta para uma cópia de x. reflect.TypeOf devolve a palavra do tipo como reflect.Type. reflect.ValueOf devolve um reflect.Value com três campos: typ_, a palavra do tipo; ptr, a palavra dos dados; e flag, o kind e os bits de acesso.\"><defs><marker id=\"rf-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"rf-phos\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"rf-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"40\" y=\"30\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">reflect.Type</text><path d=\"M130 118 L130 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rf-phos)\"></path><text x=\"142\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">TypeOf fica com a palavra do tipo</text><text x=\"40\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o argumento, convertido em any</text><rect x=\"40\" y=\"120\" width=\"180\" height=\"76\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M40 158 H220\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"52\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">palavra do tipo</text><text x=\"52\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">palavra dos dados</text><path d=\"M220 139 L466 104\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rf-wire)\"></path><path d=\"M220 177 L466 229\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rf-wire)\"></path><text x=\"470\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">descritor de tipo, escrito pelo compilador</text><rect x=\"470\" y=\"40\" width=\"220\" height=\"116\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"486\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">main.PathCount</text><text x=\"486\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">kind  struct</text><text x=\"486\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Path  string</text><text x=\"486\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Hits  int</text><text x=\"470\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma cópia de x</text><rect x=\"470\" y=\"204\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">{\"/login\" 2576}</text><path d=\"M130 198 L130 256\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rf-amber)\"></path><text x=\"142\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ValueOf copia as duas palavras e soma uma flag</text><text x=\"40\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">reflect.Value</text><rect x=\"40\" y=\"282\" width=\"380\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><path d=\"M160 282 V318 M280 282 V318\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"100\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">typ_</text><text x=\"220\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ptr</text><text x=\"350\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">flag</text><text x=\"100\" y=\"334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a palavra do tipo</text><text x=\"220\" y=\"334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a palavra dos dados</text><text x=\"350\" y=\"334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kind e bits de acesso</text></svg>", "caption": "reflect.ValueOf(x) para x := PathCount{\"/login\", 2576}: as duas funções partem das duas palavras de um any, e o reflect.Value soma uma palavra própria."}
```

**Então a reflexão não lê nada de novo.** O descritor sempre esteve no binário, porque o runtime
precisa dele para fazer funcionar type switches e type assertions; o `reflect` é um jeito público de
lê-lo. É também por isso que `ValueOf(x)` guarda uma cópia de `x`, e não o próprio `x`: converter
para `any` copia o valor, exatamente como passá-lo para qualquer outra função. A seção 04 transforma
esse único fato na regra do que a reflexão pode alterar.
