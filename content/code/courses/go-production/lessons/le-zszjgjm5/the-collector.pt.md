---
title: Como o coletor marca enquanto o programa roda
version: 1
---

A lição 24 do curso `go` mostrou que o coletor do Go faz a marcação enquanto o programa continua
rodando, e só o para por instantes. Isso levanta uma pergunta que ela deixou de lado. Marcar é seguir
cada ponteiro a partir das raízes, e o programa muda esses ponteiros o tempo todo. **O que impede o
programa de esconder um valor vivo de um marcador que está no meio do heap?** A resposta é uma cor
para cada valor e algumas instruções que o compilador acrescenta a cada escrita de ponteiro, e as
duas aparecem como números numa linha de `gctrace`.

## Três cores

O runtime descreve a marcação com três cores, e as palavras são dele (o `mgc.go` fala em "grey
objects" e em "scanning each grey object to black"):

- **branco**: ainda não alcançado. No fim da marcação, branco quer dizer lixo.
- **cinza**: alcançado, mas os ponteiros que ele contém ainda não foram seguidos. Os valores cinza
  são a lista de tarefas do marcador.
- **preto**: alcançado, e cada ponteiro dentro dele já foi seguido.

Um ciclo começa com tudo branco. As raízes, as variáveis de pacote e a pilha de cada goroutine,
pintam de cinza o que apontam. Um marcador então pega um valor cinza, pinta de cinza tudo para o que
ele aponta e o deixa preto, de novo e de novo, até não sobrar nada cinza. O que continua branco nunca
foi alcançado a partir de uma raiz, e a varredura reaproveita sua memória. Valores alocados enquanto
a marcação roda já nascem pretos, já que o programa claramente ainda tem um ponteiro para eles.

**A regra que torna isso correto é que um valor preto nunca aponta para um branco.** Um valor preto
já foi tratado, e o marcador não vai olhar dentro dele de novo. Se o programa guarda num valor preto
um ponteiro para um branco, e apaga todos os outros caminhos até ele, o valor branco nunca será
alcançado, e será liberado com o programa ainda usando-o:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Marcação em três cores e a barreira de escrita. Antes: uma pilha aponta para A, que é preto, e para B, que é cinza; B aponta para C, que é branco. O programa faz A.next receber C e B.next receber nil. Depois: A aponta para C, nada cinza aponta para C, e sem ajuda C ficaria branco e seria liberado enquanto A ainda o usa. A barreira de escrita sombreou C de cinza quando B.next foi sobrescrito, então C será escaneado.\"><defs><marker id=\"tri-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"tri-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"175\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1. A marcação está em andamento</text><rect x=\"20\" y=\"50\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma pilha</text><rect x=\"140\" y=\"48\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\"></rect><text x=\"160\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">A</text><text x=\"200\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">preto</text><rect x=\"140\" y=\"128\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">B</text><text x=\"200\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cinza</text><rect x=\"140\" y=\"208\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"160\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">C</text><text x=\"200\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">branco</text><path d=\"M101 65 L137 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tri-ph)\"></path><path d=\"M101 72 C 120 110, 120 140, 137 145\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tri-ph)\"></path><path d=\"M188 163 L188 205\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tri-ph)\"></path><text x=\"250\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">B.next = nil</text><text x=\"250\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">A.next = C</text><text x=\"545\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2. Depois das duas escritas</text><rect x=\"390\" y=\"50\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma pilha</text><rect x=\"510\" y=\"48\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\"></rect><text x=\"530\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">A</text><text x=\"570\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">preto</text><rect x=\"510\" y=\"128\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">B</text><text x=\"570\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cinza</text><rect x=\"510\" y=\"208\" width=\"96\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">C</text><text x=\"570\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cinza</text><path d=\"M471 65 L507 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tri-ph)\"></path><path d=\"M471 72 C 490 110, 490 140, 507 145\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tri-ph)\"></path><path d=\"M607 70 C 670 110, 670 210, 609 224\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tri-ph)\"></path><text x=\"620\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a barreira sombreou C: ele será escaneado</text><path d=\"M355 40 V280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path></svg>", "caption": "O programa move o único ponteiro para C de um objeto cinza para um preto; a barreira de escrita sombreia C para que a marcação não o perca."}
```

## A barreira de escrita

As duas escritas da figura são Go comum, `a.next = c` e `b.next = nil`, e podem acontecer entre dois
passos quaisquer do marcador. Por isso, enquanto um ciclo está marcando, **toda escrita de ponteiro
no heap passa por uma barreira de escrita**, um trecho curto de código que o compilador põe na frente
do armazenamento. O código do runtime dá a barreira inteira em cinco linhas:

```
ana@vm:~/mem-hits$ sed -n 31,35p /usr/local/go/src/runtime/mbarrier.go
//     writePointer(slot, ptr):
//         shade(*slot)
//         if current stack is grey:
//             shade(ptr)
//         *slot = ptr
```

`slot` é o campo sendo escrito e `ptr` o valor novo. O primeiro `shade` pinta o que o campo apontava
**antes** da escrita: na figura, `b.next = nil` pinta C de cinza na saída, então remover o último
caminho cinza até C não consegue escondê-lo. O segundo pinta o valor novo, mas só enquanto a pilha
da própria goroutine que escreve ainda não foi escaneada, porque até lá essa pilha pode guardar
ponteiros que o marcador não viu. Escritas numa pilha nunca passam pela barreira, e por isso as
pilhas são escaneadas, cada goroutine parada pelo instante que a sua pilha leva.

A barreira fica desligada quando nenhum ciclo está marcando: o código compilado confere uma flag e
pula. Um programa que aloca muito passa boa parte do tempo marcando, então paga pela barreira com
frequência, e foi assim que a lição 13 encontrou barreiras de escrita entre os custos do
`strings.Fields` ao preencher a fatia que devolve.

## Assists, e a fatia que o coletor leva

A marcação roda nos processadores do próprio programa. O runtime planeja dar a ela um quarto deles:

```
ana@vm:~/mem-hits$ grep -n "gcBackgroundUtilization = " /usr/local/go/src/runtime/mgcpacer.go
39:	gcBackgroundUtilization = 0.25
```

Nos quatro processadores do laboratório, isso é um worker de fundo. **Se o programa aloca mais
depressa do que esse worker marca, as goroutines que alocam são obrigadas a ajudar**: antes de
receber memória nova no meio de um ciclo, a goroutine faz ela mesma um pouco de marcação, na
proporção do que pediu. Isso é um assist do mutador, e é o jeito como uma coleta atrasada desacelera
o programa, um pouco de cada vez, em vez de pará-lo.

## Um trace de verdade, campo por campo

O `hits count` sobre dois milhões de linhas do log do `genlog`, cerca de 91 MB, é um programa que
aloca depressa e guarda quase nada: o benchmark da lição 12 contou duas alocações por linha, e as
contagens que ele mantém cabem em poucos mapas. Em `~/mem-hits`, com `main.go`,
`internal/tally/tally.go` e `tools/genlog/main.go` postos como a lição 1 os imprimiu, e um módulo
próprio:

```
ana@vm:~/mem-hits$ go build -o hits . && go build -o genlog ./tools/genlog
ana@vm:~/mem-hits$ ./genlog -n 2000000 > big.log; stat -c "%s bytes  %n" big.log
91465537 bytes  big.log
ana@vm:~/mem-hits$ GODEBUG=gctrace=1 ./hits count big.log 2>&1 >/dev/null | head -4
gc 1 @0.008s 1%: 0.12+1.1+0.008 ms clock, 0.51+0.10/0.14/0+0.034 ms cpu, 3->4->0 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 2 @0.017s 1%: 0.032+1.2+0.004 ms clock, 0.13+0.025/0.001/0.11+0.019 ms cpu, 3->3->0 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 3 @0.024s 1%: 0.14+1.9+0.063 ms clock, 0.56+0/0.082/0.11+0.25 ms cpu, 3->4->0 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 4 @0.030s 0%: 0.019+1.9+0.004 ms clock, 0.078+0/0.015/0.11+0.017 ms cpu, 3->3->0 MB, 4 MB goal, 0 MB stacks, 0 MB globals, 4 P
ana@vm:~/mem-hits$ GODEBUG=gctrace=1 ./hits count big.log 2>&1 >/dev/null | grep -c "^gc "
85
```

`2>&1 >/dev/null` manda o trace, que sai na saída de erro, para o pipe, e joga fora a tabela do
próprio programa. **Oitenta e cinco coletas numa execução de um programa que conta**, e o formato é o
que o `go doc runtime` dá sob `gctrace`. Aqui está o `gc 2`, campo por campo:

| campo | no `gc 2` | o que diz |
|---|---|---|
| `gc #` | `gc 2` | o segundo ciclo desta execução |
| `@#s` | `@0.017s` | começou 17 ms depois do início do programa |
| `#%` | `1%` | a fatia da execução, até ali, gasta coletando |
| clock | `0.032+1.2+0.004 ms` | a parada que abre o ciclo, a marcação concorrente, a parada que o fecha, em tempo de relógio |
| cpu, primeiro | `0.13` | a primeira parada, em tempo de processador |
| cpu, marcação | `0.025/0.001/0.11` | marcação feita por assists, pelo worker de fundo e por processadores que estariam ociosos |
| cpu, último | `0.019` | a segunda parada, em tempo de processador |
| `#->#-># MB` | `3->3->0 MB` | o heap quando a marcação começou, quando terminou, e o que foi achado vivo |
| goal | `4 MB goal` | o tamanho de heap sob o qual este ciclo queria terminar |
| stacks, globals | `0 MB`, `0 MB` | pilhas e variáveis de pacote a escanear, as duas abaixo de um megabyte |
| `# P` | `4 P` | os processadores em que o programa roda |

As duas paradas são as que a documentação do runtime nomeia: o término da varredura, que acaba a
varredura do ciclo anterior e liga a barreira, e o término da marcação, que encerra a marcação e a
desliga. **Dois dos números conferem um ao outro.** As paradas duram 0,032 e 0,004 ms no relógio e
0,13 e 0,019 ms de tempo de processador, perto de quatro vezes mais, porque uma parada prende os
quatro processadores ao mesmo tempo. O código que imprime a linha multiplica exatamente por isso:

```
ana@vm:~/mem-hits$ sed -n 1609,1615p /usr/local/go/src/runtime/mgc.go
		for i, ns := range []int64{
			int64(work.stwprocs) * (work.tMark - work.tSweepTerm),
			gcController.assistTime.Load(),
			gcController.dedicatedMarkTime.Load() + gcController.fractionalMarkTime.Load(),
			gcController.idleMarkTime.Load(),
			int64(work.stwprocs) * (work.tEnd - work.tMarkTerm),
		} {
```

A marcação é o contrário: 1,2 ms de relógio, com o programa rodando, e 0,136 ms de processador
espalhados por três tipos de worker. Neste ciclo os assists marcaram mais do que o worker de fundo.
É o `hits` alocando mais depressa do que um worker dava conta, e o runtime fazendo a goroutine que
aloca pagar por isso no caminho.

## Por que a meta diz 4 MB

`3->3->0` diz que quase nada sobrevive a um ciclo, e a meta do próximo deveria ser o dobro de nada,
pela regra que a lição 24 do curso `go` deu para `GOGC=100`. Ela é 4 MB, porque o pacer tem um piso:

```
ana@vm:~/mem-hits$ sed -n 58,60p /usr/local/go/src/runtime/mgcpacer.go; sed -n 1343p /usr/local/go/src/runtime/mgcpacer.go
	// defaultHeapMinimum is the value of heapMinimum for GOGC==100.
	defaultHeapMinimum = (goexperiment.HeapMinimum512KiBInt)*(512<<10) +
		(1-goexperiment.HeapMinimum512KiBInt)*(4<<20)
	c.heapMinimum = defaultHeapMinimum * uint64(in) / 100
```

**A meta mínima de heap é 4 MB com `GOGC=100`, e acompanha o `GOGC`.** Um `GOEXPERIMENT` poderia
baixá-la para 512 KiB, que é a outra metade da expressão; no 1.27.1 esse experimento está desligado
e vale a metade de 4 MB. Então um programa com heap vivo minúsculo coleta toda vez que aloca uns
4 MB, e o quinto ciclo sob dois outros ajustes mostra o piso andando junto com o ajuste:

```
ana@vm:~/mem-hits$ for g in 50 200; do GOGC=$g GODEBUG=gctrace=1 ./hits count big.log 2>&1 >/dev/null | sed -n 5p; done
gc 5 @0.024s 1%: 0.13+2.3+0.021 ms clock, 0.52+0/0.071/0.71+0.086 ms cpu, 1->1->0 MB, 2 MB goal, 0 MB stacks, 0 MB globals, 4 P
gc 5 @0.077s 0%: 0.043+1.0+0.003 ms clock, 0.17+0/0.031/0.14+0.014 ms cpu, 7->7->0 MB, 8 MB goal, 0 MB stacks, 0 MB globals, 4 P
```

Meta de 2 MB com `GOGC=50` e de 8 MB com `GOGC=200`. Para o `hits count`, então, o `GOGC` não decide
nada além de quantas coletas minúsculas acontecem. O trabalho delas é marcar um heap quase vazio, e
por isso todo ciclo acima terminou a marcação em menos de 2,5 ms e a coluna `#%` dessas linhas nunca
passou de 1%. A seção 04 mede um programa para o qual o ajuste importa.
