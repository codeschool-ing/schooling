---
title: Não enganar a si mesmo
version: 1
---

Um benchmark é fácil de escrever e fácil de fazer mentir. Os três jeitos abaixo produzem um número
limpo e confiante que não é o número que você queria. **O primeiro é o compilador, o segundo é a
preparação, o terceiro é a máquina.**

## O compilador removeu o trabalho

O compilador apaga código cujo resultado ninguém usa. Num programa comum isso é um presente; num
benchmark pode apagar justamente o que está sendo medido. Um arquivo descartável mostra isso com uma
função que soma mil quadrados, cronometrada no estilo antigo, com `b.N`, e com `b.Loop`, salvo como
`sum_test.go`:

```go
package wordcount

import "testing"

func sumTo(n int) int {
	s := 0
	for i := range n {
		s += i * i
	}
	return s
}

func BenchmarkSumN(b *testing.B) {
	for i := 0; i < b.N; i++ {
		sumTo(1000)
	}
}

func BenchmarkSumLoop(b *testing.B) {
	for b.Loop() {
		sumTo(1000)
	}
}
```

```
ana@vm:~/wordcount$ go test -run '^$' -bench Sum -count 3
goos: linux
goarch: amd64
pkg: example.com/wordcount
cpu: Intel(R) Xeon(R) Processor
BenchmarkSumN-4      	 7396468	       148.5 ns/op
BenchmarkSumN-4      	 7991452	       152.2 ns/op
BenchmarkSumN-4      	 8008995	       152.2 ns/op
BenchmarkSumLoop-4   	 4154817	       279.4 ns/op
BenchmarkSumLoop-4   	 4203289	       284.9 ns/op
BenchmarkSumLoop-4   	 4162086	       287.5 ns/op
PASS
ok  	example.com/wordcount	7.606s
```

**A mesma função, o mesmo argumento, e a versão com `b.N` é muito mais rápida.** Ela não é mais
rápida em somar quadrados; ela não os soma. O compilador fez o inline de `sumTo` no laço, viu que o
resultado era jogado fora e removeu a aritmética. O `go test -c` compila o binário de teste sem
rodá-lo, e o `go tool objdump` mostra o código de máquina de uma função:

```
ana@vm:~/wordcount$ go test -c -o wc.test && go tool objdump -s 'BenchmarkSumN$' wc.test
TEXT example.com/wordcount.BenchmarkSumN(SB) /home/ana/wordcount/sum_test.go
  sum_test.go:14	0x772420		31c9			XORL CX, CX		
  sum_test.go:14	0x772422		eb03			JMP 0x772427		
  sum_test.go:14	0x772424		48ffc1			INCQ CX			
  sum_test.go:14	0x772427		48398810020000		CMPQ 0x210(AX), CX	
  sum_test.go:14	0x77242e		7e1b			JLE 0x77244b		
  sum_test.go:15	0x772430		90			NOPL			
  sum_test.go:7		0x772431		31d2			XORL DX, DX		
  sum_test.go:7		0x772433		eb0b			JMP 0x772440		
  sum_test.go:7		0x772435		48ffc2			INCQ DX			
  sum_test.go:7		0x772438		0f1f840000000000	NOPL 0(AX)(AX*1)	
  sum_test.go:7		0x772440		4881fae8030000		CMPQ DX, $0x3e8		
  sum_test.go:7		0x772447		7cec			JL 0x772435		
  sum_test.go:7		0x772449		ebd9			JMP 0x772424		
  sum_test.go:17	0x77244b		c3			RET			
ana@vm:~/wordcount$ rm sum_test.go wc.test
```

Leia as linhas marcadas `sum_test.go:7`, o corpo do laço de `sumTo`: um incremento, uma comparação
com 1000 (`$0x3e8`) e um salto de volta. Não há multiplicação nem soma em `s` em lugar nenhum. O que
o benchmark cronometrou foi um laço contando até mil. **O `b.Loop` mantém vivas as chamadas dentro
dele e os resultados delas**, que é o principal motivo de ele ter substituído o laço com `b.N`. Com
código mais antigo, o remédio é guardar o resultado em algum lugar que o compilador não consiga
provar que não é usado, como uma variável de pacote.

## A preparação foi cronometrada

Tudo dentro do laço cronometrado é medido, inclusive trabalho que não é o assunto. Montar o `sample`
dentro do laço do `BenchmarkCount` teria medido o `strings.Repeat` além do `Count`. Com o `b.Loop`,
a preparação antes do laço fica de fora sozinha. No estilo com `b.N` não fica: o cronômetro corre
desde o começo da função, e a preparação precisa ser seguida de `b.ResetTimer()`. A preparação que
tem de acontecer a cada rodada, como uma cópia nova de algo que o código modifica, pertence ao laço e
então faz parte do número, o que é honesto desde que você saiba que ela está lá.

## A máquina estava ocupada

A máquina do laboratório roda outros trabalhos, e o seu notebook também: uma aba do navegador, um
indexador, uma atualização. As cinco execuções da seção 03 de um programa sem mudança se espalharam
por quase três por cento, e uma execução única antes delas foi mais lenta em mais de dez, o que é
comum. Três hábitos impedem que isso decida alguma coisa:

1. **Compare execuções feitas uma depois da outra, na mesma máquina**, nunca um número de hoje
   contra um número anotado no mês passado.
2. **Rode cada lado várias vezes com `-count`** e olhe o espalhamento antes das médias.
3. **Prefira as colunas de alocação quando elas contam a história**, porque não se mexem com a carga.

Para comparar muitas execuções estatisticamente, o projeto Go publica o `benchstat`, no módulo
`golang.org/x/perf`. Ele é um download à parte, e não faz parte do toolchain, então este curso lê as
execuções a olho; é a primeira coisa a instalar quando as diferenças que importam são menores que o
espalhamento.

Um benchmark diz quanto tempo; não diz onde. Quando o número é ruim, o `go test -bench` também
recebe `-cpuprofile` e `-memprofile`, que registram para onde foram o tempo e as alocações.
