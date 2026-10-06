---
title: O coletor de lixo, e como ler o rastro dele
version: 1
---

"Coleta de lixo" faz muita gente imaginar um programa que congela de vez em quando enquanto alguma
coisa arruma a casa por trás dele. Essa imagem está errada para Go. **O coletor de Go faz quase
todo o trabalho enquanto o programa continua rodando, e o para duas vezes por coleta, por pouco
tempo.** No rastro desta seção cada parada dura menos de um décimo de milissegundo, e basta uma
variável de ambiente para assistir.

## Marcar, depois varrer

O coletor nunca pergunta de onde um valor veio nem quantos anos ele tem. Ele pergunta **o que o
programa ainda consegue alcançar**. Parte das **raízes**, as variáveis de pacote e as pilhas de
todas as goroutines em execução, segue cada ponteiro que encontra e marca cada valor do heap a que
chega. Essa é a fase de marcação. O que não foi marcado não pode mais ser usado pelo programa,
porque nada leva até lá, então a fase de varredura devolve aquele espaço para valores novos.

O programa em `~/memory-gc` dá trabalho ao coletor. Ele guarda 80 buffers de 100.000 bytes, oito
milhões de bytes ao todo, na variável de pacote `live`, depois cria 50.000 buffers de 10.000 bytes
um depois do outro, preenche cada um e guarda só o mais novo em `last`:

```go
package main

import (
	"fmt"
	"runtime"
)

var live [][]byte
var last []byte

func main() {
	for range 80 {
		live = append(live, make([]byte, 100_000))
	}
	for range 50_000 {
		b := make([]byte, 10_000)
		for i := range b {
			b[i] = byte(i)
		}
		last = b
	}
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	fmt.Printf("%d collections, %d MB allocated, heap at most %d MB\n",
		m.NumGC, m.TotalAlloc>>20, m.HeapSys>>20)
}
```

`runtime.ReadMemStats` preenche um `runtime.MemStats` com a contabilidade do próprio runtime:
`NumGC` é quantas coletas rodaram, `TotalAlloc` é cada byte alocado até ali, e `HeapSys`, pela
documentação, "estima o maior tamanho que o heap já teve". `>>20` divide por 1.048.576, que é
como o runtime conta um megabyte. Cada vez que `last` passa adiante, o buffer anterior fica
inalcançável:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O que o coletor faz com o heap do programa em ~/memory-gc. Ele parte das raízes, as variáveis de pacote live e last e a pilha de cada goroutine, e segue ponteiros. live leva a um array de 80 slices e dele a 80 buffers de 100.000 bytes; last leva ao buffer de 10.000 bytes mais novo. Esses são marcados e mantidos. Os buffers de 10.000 bytes mais antigos não são alcançados por nada, então a varredura libera o espaço deles para valores novos.\"><defs><marker id=\"gcr-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"101\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">raízes</text><rect x=\"16\" y=\"36\" width=\"170\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"101\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">variáveis de pacote</text><rect x=\"30\" y=\"66\" width=\"142\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"101\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">live</text><rect x=\"30\" y=\"106\" width=\"142\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"101\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">last</text><rect x=\"30\" y=\"146\" width=\"142\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"101\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pilhas das goroutines</text><rect x=\"220\" y=\"66\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">80 slices</text><path d=\"M174 81 L217 81\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gcr-phosphor)\"></path><rect x=\"410\" y=\"30\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"416\" y=\"36\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"422\" y=\"42\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"492\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">100.000 bytes</text><text x=\"590\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">× 80</text><path d=\"M342 81 L418 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gcr-phosphor)\"></path><rect x=\"410\" y=\"106\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">10.000 bytes</text><text x=\"560\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o mais novo</text><path d=\"M174 121 L407 121\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gcr-phosphor)\"></path><rect x=\"240\" y=\"200\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"310\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.000 bytes</text><rect x=\"395\" y=\"200\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"465\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.000 bytes</text><rect x=\"550\" y=\"200\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"620\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.000 bytes</text><text x=\"475\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">buffers mais antigos: nada aponta para eles</text><rect x=\"20\" y=\"262\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"50\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">alcançado a partir de uma raiz: marcado, mantido</text><rect x=\"370\" y=\"262\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"400\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">não alcançado: varrido, o espaço reaproveitado</text></svg>", "caption": "Uma coleta do programa em ~/memory-gc. A marcação segue ponteiros a partir das raízes; o que ela nunca alcançou é varrido.", "same": ["80 slices"]}
```

O código-fonte do runtime descreve o próprio coletor em quatro linhas no topo de `mgc.go`:

```
ana@vm:~/memory-gc$ sed -n 7,10p /usr/local/go/src/runtime/mgc.go
// The GC runs concurrently with mutator threads, is type accurate (aka precise), allows multiple
// GC threads to run in parallel. It is a concurrent mark and sweep that uses a write barrier. It is
// non-generational and non-compacting. Allocation is done using size segregated per P allocation
// areas to minimize fragmentation while eliminating locks in the common case.
```

"Mutator" é a palavra do coletor para o seu programa, a coisa que muda o heap por baixo dele.
**Concorrente** quer dizer que a marcação acontece enquanto o seu código roda, e a write barrier é
uma verificação que o compilador acrescenta às escritas de ponteiro, ativa enquanto uma coleta
roda, para que o marcador não perca um ponteiro que o seu programa mudou de lugar. **Não
geracional** quer dizer que ele não separa os valores por idade nem trata os jovens de outro jeito.
**Não compactador** quer dizer que ele nunca move um valor do heap para fechar os buracos entre
eles; em vez disso reaproveita os buracos, e é para isso que servem as classes de tamanho da seção
03 da lição 12.

### Qual coletor o 1.27.1 roda

O jeito como a marcação percorre a memória foi refeito dentro desse projeto. A configuração de build
do 1.27.1 liga por padrão um algoritmo chamado **Green Tea**, e o arquivo dele diz o que faz de
diferente:

```
ana@vm:~/memory-gc$ grep -n "GreenTeaGC" /usr/local/go/src/internal/buildcfg/exp.go
86:		GreenTeaGC:            true,
ana@vm:~/memory-gc$ sed -n 5,10p /usr/local/go/src/runtime/mgcmark_greenteagc.go
// Green Tea mark algorithm
//
// The core idea behind Green Tea is simple: achieve better locality during
// mark/scan by delaying scanning so that we can accumulate objects to scan
// within the same span, then scan the objects that have accumulated on the
// span all together.
```

Um **span** é uma sequência de páginas de memória que guarda valores de uma mesma classe de
tamanho. Examinar juntos os valores marcados de um span, em vez de um por um na ordem em que foram
achados, mantém o processador lendo memória próxima. Isso muda a velocidade da marcação, não o que é
marcado, e nenhum programa precisa mudar por causa disso.

## Uma linha por coleta

`GODEBUG=gctrace=1` faz o runtime imprimir uma linha na saída de erro a cada coleta. O binário é
compilado antes, para que o rastro seja do programa e não do comando `go`, que também coleta lixo:

```
ana@vm:~/memory-gc$ go build -o gc .
ana@vm:~/memory-gc$ GODEBUG=gctrace=1 ./gc 2>&1 | sed -n "1,4p;\$p"
gc 1 @0.000s 12%: 0.073+0.19+0.007 ms clock, 0.29+0.11/0.17/0.20+0.031 ms cpu, 3->4->3 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 2 @0.001s 12%: 0.039+0.23+0.036 ms clock, 0.15+0.043/0.073/0.035+0.14 ms cpu, 7->8->8 MB, 7 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 3 @0.009s 2%: 0.027+0.29+0.058 ms clock, 0.11+0.021/0.048/0.076+0.23 ms cpu, 15->15->8 MB, 16 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 4 @0.016s 2%: 0.029+0.29+0.036 ms clock, 0.11+0.044/0.077/0.017+0.14 ms cpu, 15->15->8 MB, 16 MB goal, 0 MB stacks, 0 MB globals, 4 P
61 collections, 496 MB allocated, heap at most 19 MB
```

O `sed` ficou com as quatro primeiras linhas e a última, que é a do próprio programa. A chave dos
campos está na documentação do runtime:

```
ana@vm:~/memory-gc$ go doc runtime | grep -A 9 "where the fields are" | head -10
    where the fields are as follows:
    	gc #         the GC number, incremented at each GC
    	@#s          time in seconds since program start
    	#%           percentage of time spent in GC since program start
    	#+...+#      wall-clock/CPU times for the phases of the GC
    	#->#-># MB   heap size at GC start, at GC end, and live heap, or /gc/scan/heap:bytes
    	# MB goal    goal heap size, or /gc/heap/goal:bytes
    	# MB stacks  estimated scannable stack size, or /gc/scan/stack:bytes
    	# MB globals scannable global size, or /gc/scan/globals:bytes
    	# P          number of processors used, or /sched/gomaxprocs:threads
```

Leia o `gc 3` com ela, da esquerda para a direita:

| campo | no `gc 3` | o que diz |
|---|---|---|
| `gc #` | `gc 3` | a terceira coleta desta execução |
| `@#s` | `@0.009s` | começou 9 milissegundos depois do programa |
| `#%` | `2%` | a fração da execução até ali gasta coletando |
| clock | `0.027+0.29+0.058 ms` | uma parada, a marcação concorrente, uma segunda parada |
| cpu | `0.11+0.021/0.048/0.076+0.23 ms` | as mesmas fases em tempo de processador, a marcação dividida em três |
| `#->#-># MB` | `15->15->8 MB` | o heap no começo, no fim, e o que ainda era alcançável |
| goal | `16 MB goal` | o tamanho abaixo do qual esta coleta queria terminar |
| stacks, globals | `0 MB`, `0 MB` | raízes a examinar: as deste programa ficam abaixo de um megabyte |
| `# P` | `4 P` | os quatro processadores da máquina do laboratório |

**O campo clock é a resposta à imagem do programa congelado.** A documentação do runtime dá nome às
três fases: um término de varredura com o mundo parado, a marcação concorrente, um término de
marcação com o mundo parado. No `gc 3` as duas paradas levaram 0,027 e 0,058 milissegundo, e os
0,29 milissegundo de marcação correram ao lado do programa. Os três números da marcação no campo
cpu são o tempo que as próprias alocações do programa passaram ajudando, os workers de fundo, e os
workers em processadores que estariam ociosos.

`15->15->8` é a marcação e varredura da figura em números: 15 MB no heap, 8 MB alcançáveis, os 80
buffers de `live` e pouco mais. Sete megabytes de buffers antigos de `last` eram lixo.

## GOGC: quanto lixo antes da próxima coleta

A meta no `gc 4` é de 16 MB, o dobro dos 8 MB que o `gc 3` encontrou vivos. Esse dobro é uma
configuração:

```
ana@vm:~/memory-gc$ go doc runtime | grep -A 5 "The GOGC variable"
The GOGC variable sets the initial garbage collection target percentage.
A collection is triggered when the ratio of freshly allocated data to live
data remaining after the previous collection reaches this percentage. The
default is GOGC=100. Setting GOGC=off disables the garbage collector entirely.
runtime/debug.SetGCPercent allows changing this percentage at run time.
```

**`GOGC=100` deixa o heap crescer 100% do que sobreviveu antes que a próxima coleta comece.** Com
8 MB vivos, a próxima vem aos 16 MB. Mais baixo, e as coletas chegam antes e o heap fica menor;
mais alto, e chegam depois. O mesmo binário com cinco valores:

```
ana@vm:~/memory-gc$ for g in 50 100 200 400 off; do echo "GOGC=$g: $(GOGC=$g ./gc)"; done
GOGC=50: 123 collections, 496 MB allocated, heap at most 15 MB
GOGC=100: 61 collections, 496 MB allocated, heap at most 19 MB
GOGC=200: 30 collections, 496 MB allocated, heap at most 27 MB
GOGC=400: 15 collections, 496 MB allocated, heap at most 59 MB
GOGC=off: 0 collections, 496 MB allocated, heap at most 499 MB
```

Toda execução alocou os mesmos 496 MB. Dobrar o `GOGC` mais ou menos cortou pela metade o número de
coletas e deixou o heap crescer, e `off` não coletou nada e guardou cada byte. **O GOGC troca
memória pelo tempo de processador gasto coletando**, e não existe valor que economize os dois. As
contagens e os megabytes mudam um pouco a cada execução, porque o coletor roda ao lado do programa
e os dois disputam; o formato continua o mesmo.
