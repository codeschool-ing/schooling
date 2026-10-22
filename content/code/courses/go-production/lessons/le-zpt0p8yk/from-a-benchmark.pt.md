---
title: Um profile a partir de um benchmark
version: 1
---

O profile mais barato de obter é o de um benchmark, porque **o `go test` já sabe tirá-lo**: duas
flags, e o binário de teste grava um profile de CPU e um de memória ao terminar. Um benchmark também
é o lugar certo para começar por um segundo motivo. Ele roda o código que importa num laço, com a
entrada que você escolheu, sem mais nada acontecendo, então o profile fala desse código e não do que
um programa inteiro faz enquanto inicia e encerra.

O trabalho a medir é o pacote `tally` da lição 1, contando linhas. Ana trabalha numa cópia do `hits`
da lição 1 em `~/prof`, para que os profiles e um log grande das seções 04 e 05 fiquem longe do
projeto de verdade. A cópia tem os três arquivos que a lição 1 imprimiu (`main.go`,
`tools/genlog/main.go` e `internal/tally/tally.go`) e um `go.mod` próprio.

## Um benchmark para o `Count`

A lição 29 de `go-concurrency` ensinou benchmarks; este tem o formato que ela ensinou, num arquivo
próprio ao lado do `tally.go`. Salve como `internal/tally/bench_test.go`:

```go
package tally_test

import (
	"bytes"
	"os"
	"testing"

	"example.com/hits/internal/tally"
)

func BenchmarkCount(b *testing.B) {
	data, err := os.ReadFile("testdata/access.log")
	if err != nil {
		b.Fatal(err)
	}
	b.SetBytes(int64(len(data)))
	for b.Loop() {
		if _, err := tally.Count(bytes.NewReader(data)); err != nil {
			b.Fatal(err)
		}
	}
}
```

**O log é lido uma vez, antes do laço**, então o que se cronometra é a contagem e não a leitura do
disco. O `b.Loop` roda o corpo quantas vezes for preciso para ter um tempo estável e exclui da medição
tudo o que vem antes do laço. O `b.SetBytes` diz ao framework quanta entrada uma iteração consome, o
que acrescenta uma coluna de vazão ao resultado. O `go test` roda os testes de um pacote com o
diretório do pacote como diretório de trabalho, então `testdata/access.log` quer dizer
`internal/tally/testdata/access.log`, e o comando go ignora um diretório chamado `testdata` quando
procura pacotes. A entrada é do `genlog`, cem mil linhas:

```
ana@vm:~/prof$ mkdir -p internal/tally/testdata
ana@vm:~/prof$ go run ./tools/genlog -n 100000 > internal/tally/testdata/access.log
ana@vm:~/prof$ stat -c "%s bytes  %n" internal/tally/testdata/access.log
4571935 bytes  internal/tally/testdata/access.log
```

## Duas flags

`-cpuprofile` e `-memprofile` recebem cada uma um nome de arquivo. **Com qualquer uma delas, o comando
go também guarda o binário de teste**, o que o `go help testflag` descreve como gravá-lo "as -c
would":

```
ana@vm:~/prof$ go test -bench Count -benchmem -cpuprofile cpu.out -memprofile mem.out ./internal/tally
goos: linux
goarch: amd64
pkg: example.com/hits/internal/tally
cpu: Intel(R) Xeon(R) Processor
BenchmarkCount-4   	      43	  25577435 ns/op	 178.75 MB/s	13323728 B/op	  200009 allocs/op
PASS
ok  	example.com/hits/internal/tally	1.115s
ana@vm:~/prof$ ls
cpu.out
go.mod
internal
main.go
mem.out
tally.test
tools
```

A linha do benchmark é a que a lição 29 de `go-concurrency` explicou: 43 iterações de 25.577.435
nanossegundos cada, uns 25,6 milissegundos para contar 4,57 MB, 178,75 MB por segundo. Com
`-benchmem` ela ganha as colunas de memória, e elas são a primeira descoberta antes de abrir qualquer
profile: **200.009 alocações por iteração, para 100.000 linhas, são duas alocações por linha**. O
`cpu.out`, o `mem.out` e o `tally.test` ficam no diretório onde o `go test` rodou.

## A primeira olhada

O `go tool pprof` lê um profile. Com um formato de saída como `-top`, ele imprime esse relatório e
sai; sem formato, abre um prompt interativo, que a lição 13 usa. O `sed` tira a linha com a data da
execução:

```
ana@vm:~/prof$ go tool pprof -top cpu.out | sed /^Time:/d | head -14
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: cpu
Duration: 1.10s, Total samples = 1.20s (108.63%)
Showing nodes accounting for 1.20s, 100% of 1.20s total
      flat  flat%   sum%        cum   cum%
     0.25s 20.83% 20.83%      0.39s 32.50%  strings.Fields
     0.05s  4.17% 25.00%      0.05s  4.17%  runtime.memmove
     0.05s  4.17% 29.17%      0.05s  4.17%  time.parseRFC3339[go.shape.string].func1 (inline)
     0.04s  3.33% 32.50%      0.04s  3.33%  internal/strconv.Atoi
     0.04s  3.33% 35.83%      0.06s  5.00%  runtime.mallocgcSmallNoScanSC6
     0.04s  3.33% 39.17%      0.09s  7.50%  runtime.mapassign_fast64
     0.04s  3.33% 42.50%      0.09s  7.50%  time.ParseDuration
     0.03s  2.50% 45.00%         1s 83.33%  example.com/hits/internal/tally.Count
```

O cabeçalho diz o que foi medido. A execução durou 1,10 segundo e guarda 1,20 segundo de amostras,
ou seja, 120 tiques do relógio de 10 ms, mais do que a duração porque o coletor de lixo trabalhou em
outros núcleos enquanto o benchmark rodava. Abaixo vem uma linha por função. **`strings.Fields` vem
primeiro, com um quinto de todas as amostras**, e `tally.Count`, perto do fim do trecho, quase não tem
amostras próprias e aparece em 83% das pilhas. O que as duas colunas de números significam, e por que
ordenam as funções de jeitos tão diferentes, é o assunto da lição 13; esta lição é sobre obter o
arquivo.

A seção 02 disse que o profiler de CPU dá cem tiques por segundo, e o arquivo confirma. O `-raw`
imprime o profile como está guardado, e as primeiras linhas dizem o que uma amostra mede:

```
ana@vm:~/prof$ go tool pprof -raw cpu.out | sed /^Time:/d | head -5
PeriodType: cpu nanoseconds
Period: 10000000
Duration: 1.10
Samples:
samples/count cpu/nanoseconds
```

Um período de 10.000.000 de nanossegundos são 10 ms. Cada amostra carrega dois valores, uma contagem
e os nanossegundos que ela representa.

## O profile de memória

Os mesmos comandos no `mem.out`:

```
ana@vm:~/prof$ go tool pprof -top mem.out | sed /^Time:/d | head -9
File: tally.test
Build ID: fbb66d70844d1cbc66568f65c6144283b6439bff
Type: alloc_space
Showing nodes accounting for 554.90MB, 98.95% of 560.77MB total
Dropped 32 nodes (cum <= 2.80MB)
      flat  flat%   sum%        cum   cum%
  332.53MB 59.30% 59.30%   332.53MB 59.30%  strings.Fields
  217.51MB 38.79% 98.09%   217.51MB 38.79%  bufio.(*Scanner).Text (inline)
    4.37MB  0.78% 98.86%     4.37MB  0.78%  os.readFileContents
ana@vm:~/prof$ go tool pprof -raw mem.out | sed /^Time:/d | head -4
PeriodType: space bytes
Period: 524288
Samples:
alloc_objects/count alloc_space/bytes[dflt] inuse_objects/count inuse_space/bytes
```

**O `go test -memprofile` grava o profile `allocs`**, então o relatório abre em `alloc_space`: 560,77
MB alocados em todas as iterações que o benchmark rodou, quase tudo por duas funções,
`strings.Fields` e `bufio.(*Scanner).Text`. São as duas alocações por linha que o `-benchmem`
contou. O cabeçalho do `-raw` mostra as quatro visões da seção 02 num arquivo só, com `[dflt]` ao
lado da que aparece por padrão, e um período de 524.288 bytes, os 512 KB de
`runtime.MemProfileRate`.

Duas observações práticas. **O profile de uma execução de um segundo tem pouco mais de cem
amostras**, o suficiente para ver que `strings.Fields` domina e não para ordenar as funções que
levam 3% cada; o `-benchtime` roda o benchmark por mais tempo, `5s` para cinco segundos ou `200x`
para exatamente 200 iterações, e enche o profile na mesma medida; a lição 13 usa o segundo. E um
profile carrega os próprios nomes de função, por isso `go tool pprof cpu.out` não precisou de mais
nada; as visões que mostram código de máquina são a exceção, e querem o binário antes do profile,
como em `go tool pprof -disasm Count tally.test cpu.out`. É para isso que serve o `tally.test` que
ficou para trás.
