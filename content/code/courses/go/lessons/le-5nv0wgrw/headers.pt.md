---
title: Valores que carregam um ponteiro
version: 1
---

A seção 02 não teve exceções, e um pouco de Go parece contradizê-la logo de cara. O `setFirst` da
lição 11 mudou a slice de quem chamou. Uma função que acrescenta uma chave a um map muda o map de
quem chamou. Desses dois casos, muita gente conclui que **Go passa slices e maps por referência**,
e você vai ler essa frase em posts e respostas por aí. É a imagem errada, e ela falha num ponto
específico que esta seção mostra. O que acontece, em vez disso, é que o valor de uma slice ou de um map é
pequeno e guarda um ponteiro, e copiar o valor copia o ponteiro.

## O tamanho de cada valor

O `unsafe.Sizeof` mediu um array e uma slice na lição 11. Aqui ele mede um valor de cada tipo cujo
valor guarda um ponteiro:

```go
package main

import (
	"fmt"
	"unsafe"
)

type Player struct {
	Name  string
	Score int
}

func main() {
	var (
		s   []int
		m   map[string]int
		str string
		f   func()
		v   any
		c   chan int
	)
	fmt.Println("slice    ", unsafe.Sizeof(s))
	fmt.Println("map      ", unsafe.Sizeof(m))
	fmt.Println("string   ", unsafe.Sizeof(str))
	fmt.Println("func     ", unsafe.Sizeof(f))
	fmt.Println("interface", unsafe.Sizeof(v))
	fmt.Println("chan     ", unsafe.Sizeof(c))

	ana := Player{Name: "Ana", Score: 10}
	v = ana
	ana.Score = 99
	fmt.Println(v, ana)
}
```

```
ana@vm:~/byvalue-sizes$ go run .
slice     24
map       8
string    16
func      8
interface 16
chan      8
{Ana 10} {Ana 99}
```

**Nenhum desses tamanhos depende do que o valor guarda.** Um map com um milhão de chaves tem 8
bytes como valor, porque esses 8 bytes são um ponteiro para a tabela onde as chaves moram. O próprio
código do runtime diz isso: `makemap`, em `/usr/local/go/src/runtime/map.go`, devolve um
`*maps.Map`, e esse ponteiro é o que uma variável de tipo map guarda. Uma slice são as três palavras
da lição 11, e uma string, o ponteiro e o comprimento da lição 9. Um valor de função também é um
ponteiro, e `any`, o tipo de `v` acima, são duas palavras: uma diz que tipo está guardado e a outra
aponta para o valor guardado.

A última linha da saída é sobre essa segunda palavra. `v = ana` guardou um `Player` em `v`, e o
`ana.Score = 99` depois não chegou a ele: **colocar uma struct numa interface copia a struct**, do
mesmo jeito que passá-la. Interfaces são as lições 27 e 28; este é o único fato sobre elas que cabe
aqui.

## O teste que separa as duas imagens

Na passagem por referência, um parâmetro seria outro nome para a variável de quem chamou, e
atribuir a ele mudaria a variável de quem chamou. Um map passado por valor se comporta diferente
exatamente nesse caso, e em nenhum outro:

```go
package main

import "fmt"

func addKey(m map[string]int) {
	m["bia"] = 2
}

func replace(m map[string]int) {
	m = map[string]int{"carla": 3}
	fmt.Println("inside: ", m)
}

func main() {
	ages := map[string]int{"ana": 1}

	addKey(ages)
	fmt.Println("addKey: ", ages)

	replace(ages)
	fmt.Println("replace:", ages)
}
```

```
ana@vm:~/byvalue-map$ go run .
addKey:  map[ana:1 bia:2]
inside:  map[carla:3]
replace: map[ana:1 bia:2]
```

`addKey` escreveu através da sua cópia do ponteiro, na única tabela para a qual as duas variáveis
apontam, então `main` vê `bia`. `replace` atribuiu um map novo a `m`, o que mudou `m` e só `m`: lá
dentro ele guarda `carla`, e de volta em `main`, `ages` é o map que era antes da chamada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 345\" role=\"img\" aria-label=\"Duas chamadas, cada uma passando o map ages de main. Em addKey(ages), a variável ages de main e o parâmetro m de addKey são duas cópias de um ponteiro, e as duas setas chegam à mesma tabela, que agora guarda ana: 1 e bia: 2. Em replace(ages), a atribuição m = map[string]int{...} aponta m para uma tabela nova com carla: 3, enquanto ages continua apontando para a tabela que tinha.\"><defs><marker id=\"pv-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"pv-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">addKey(ages)</text><rect x=\"40\" y=\"44\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ages</text><text x=\"144\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">•</text><text x=\"100\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">variável de main</text><rect x=\"40\" y=\"104\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">m</text><text x=\"144\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">•</text><text x=\"100\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o parâmetro</text><rect x=\"330\" y=\"66\" width=\"150\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ana: 1</text><text x=\"405\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bia: 2</text><text x=\"405\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a tabela do map</text><path d=\"M152 60 L250 60 L250 82 L326 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#pv-phosphor)\"></path><path d=\"M152 120 L250 120 L250 104 L326 104\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#pv-phosphor)\"></path><text x=\"520\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">duas cópias de um ponteiro,</text><text x=\"520\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">e as duas chegam à mesma</text><text x=\"520\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tabela: a chave nova aparece</text><path d=\"M20 168 L700 168\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">replace(ages)</text><rect x=\"40\" y=\"212\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ages</text><text x=\"144\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">•</text><text x=\"100\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">variável de main</text><rect x=\"40\" y=\"272\" width=\"120\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">m</text><text x=\"144\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">•</text><text x=\"100\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o parâmetro</text><rect x=\"330\" y=\"222\" width=\"150\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ana: 1</text><text x=\"405\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bia: 2</text><text x=\"405\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a tabela do map</text><rect x=\"330\" y=\"304\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"322\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">carla: 3</text><text x=\"405\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma tabela nova</text><path d=\"M152 228 L326 228\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#pv-phosphor)\"></path><path d=\"M152 288 L250 288 L250 319 L326 319\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#pv-amber)\"></path><text x=\"520\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a atribuição mudou m,</text><text x=\"520\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a cópia; ages continua</text><text x=\"520\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">apontando para a sua tabela</text></svg>", "caption": "Passar um map copia um ponteiro. O que a função chamada faz através dele chega à tabela de quem chamou; o que ela atribui ao seu parâmetro, não."}
```

## Onde a imagem errada custa caro

Ninguém escreve `replace` de propósito. O que as pessoas escrevem é uma função que cria um map
quando não recebeu nenhum, acreditando que quem chamou vai recebê-lo:

```go
package main

import "fmt"

func load(m map[string]int) {
	if m == nil {
		m = make(map[string]int)
	}
	m["ana"] = 1
}

func main() {
	var ages map[string]int
	load(ages)
	fmt.Println(ages, len(ages), ages == nil)
	ages["bia"] = 2
}
```

```
ana@vm:~/byvalue-nil$ go run .
map[] 0 true
panic: assignment to entry in nil map

goroutine 1 [running]:
main.main()
	/home/ana/byvalue-nil/main.go:16 +0x136
exit status 2
```

`load` criou um map, pôs `ana` nele e retornou, e o map foi embora com a sua variável. `ages` em
`main` continua nil, e a linha 16 escreve nele, que é o panic que a lição 14 mostrou para um map
nil. **Uma função pode mudar aquilo a que um ponteiro leva, e não pode mudar qual ponteiro quem
chamou guarda.** A correção é a da seção 02: devolver o map e deixar quem chamou guardá-lo.

```go
package main

import "fmt"

func load(m map[string]int) map[string]int {
	if m == nil {
		m = make(map[string]int)
	}
	m["ana"] = 1
	return m
}

func main() {
	var ages map[string]int
	ages = load(ages)
	ages["bia"] = 2
	fmt.Println(ages, len(ages), ages == nil)
}
```

```
ana@vm:~/byvalue-fix$ go run .
map[ana:1 bia:2] 2 false
```

## O que uma cópia compartilha, tipo a tipo

Cada um desses valores é copiado inteiro em toda chamada e atribuição, como uma struct. O que muda
é o que a cópia ainda alcança:

| tipo | o valor que é copiado | o que a cópia compartilha com o original |
|---|---|---|
| slice | 24 bytes: ponteiro, comprimento, capacidade | o array: elementos sim, comprimento não (lição 11) |
| map | 8 bytes: um ponteiro | a tabela inteira: chaves acrescentadas ou apagadas por qualquer das cópias |
| string | 16 bytes: ponteiro e comprimento | os bytes, que ninguém pode mudar (lição 9) |
| func | 8 bytes: um ponteiro | as variáveis que uma closure capturou (lição 21) |
| interface | 16 bytes: um tipo e um ponteiro | o valor guardado nela, que foi copiado quando foi guardado |
| chan | 8 bytes: um ponteiro | o próprio canal, que é assunto do curso `go-concurrency` |

Então "por valor ou por referência" é a pergunta errada para fazer a um tipo Go. **Tudo é passado
por valor, e a pergunta útil é para onde o valor aponta.** Para uma struct ou um array a resposta é
para lugar nenhum, a menos que contenha um valor desta tabela ou um ponteiro, que é o assunto da
lição 23.
