---
title: Rodando, e quanto custa
version: 1
---

A lição 1 encontrou o detector de corridas uma vez, no `count.go`, e as lições 2 a 15 o usaram como
conferência de passagem. Esta lição faz dele o assunto. **O detector de corridas não é um programa
separado que você aponta para o seu código; é outro build do seu código**, compilado de modo que
toda leitura e toda escrita de memória passem primeiro pelo ThreadSanitizer. O ThreadSanitizer
guarda, ao lado de cada pedaço de memória, um histórico curto de qual goroutine o tocou por último
e com o que essa goroutine tinha se sincronizado. Quando dois acessos se encontram sem
sincronização entre eles e pelo menos um é escrita, ele imprime um relatório.

A flag é a mesma para todo comando go que compila alguma coisa:

| comando | o que o `-race` dá a você |
|---|---|
| `go run -race file.go` | compila e roda um programa com o detector dentro |
| `go build -race` | um binário com o detector dentro, para rodar quantas vezes quiser |
| `go test -race ./...` | todo teste de todo pacote, com o detector observando |
| `go install -race` | o mesmo que `build`, instalado em `~/go/bin` |

## Quanto custa a conferência extra

Todo acesso à memória agora faz trabalho a mais, e o histórico precisa de memória própria. O jeito
de saber quanto é medir. Esta lição trabalha em `~/races`, criado com
`go mod init example.com/races`, e o primeiro programa faz quatro goroutines compartilharem um map
sob um mutex, a ferramenta da lição 8, e informa o próprio pico de memória como o kernel o contou.
Ele não tem corrida, então o detector não tem nada a relatar e só o custo aparece. Salvo como
`cost.go`:

```go
// Command cost does a fixed amount of shared work under a mutex and reports its peak memory.
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
	"sync"
)

func main() {
	var mu sync.Mutex
	counts := make(map[int]int)
	var wg sync.WaitGroup
	for g := range 4 {
		wg.Go(func() {
			for i := range 500_000 {
				mu.Lock()
				counts[(g+i)%1000]++
				mu.Unlock()
			}
		})
	}
	wg.Wait()
	fmt.Println("keys:", len(counts), "peak memory:", peak())
}

// peak reads the most memory the process has held, as the kernel counts it.
func peak() string {
	f, err := os.Open("/proc/self/status")
	if err != nil {
		return "unknown"
	}
	defer f.Close()
	s := bufio.NewScanner(f)
	for s.Scan() {
		if v, ok := strings.CutPrefix(s.Text(), "VmHWM:"); ok {
			return strings.TrimSpace(v)
		}
	}
	return "unknown"
}
```

Compilado duas vezes, uma normal e outra com o detector, e cronometrado com o `time` do shell:

```
ana@vm:~/races$ go build -o cost cost.go
ana@vm:~/races$ go build -race -o cost-race cost.go
ana@vm:~/races$ ls -l cost cost-race
-rwxr-xr-x 1 ana ana 2387083 Oct 16 19:27 cost
-rwxr-xr-x 1 ana ana 2976269 Oct 16 19:27 cost-race
ana@vm:~/races$ time ./cost
keys: 1000 peak memory: 2296 kB

real	0m0.156s
user	0m0.306s
sys	0m0.009s
ana@vm:~/races$ time ./cost-race
keys: 1000 peak memory: 21056 kB

real	0m1.852s
user	0m1.097s
sys	0m0.140s
```

**O mesmo programa levou 1,852 segundo em vez de 0,156, cerca de doze vezes mais, e ocupou 21.056 kB
de memória no pico em vez de 2.296, cerca de nove vezes mais.** O binário cresceu menos de 600 kB,
de 2.387.083 bytes para 2.976.269: a instrumentação é pequena, e o custo é pago enquanto o programa
roda. Essas proporções são deste programa, que quase não faz nada além de tomar uma trava e mexer
num map, então quase toda instrução que ele roda é uma que o detector confere. Um programa que passa
o tempo esperando uma rede paga bem menos, porque esperar não toca memória.

## Onde ele cabe

Esses números decidem onde o detector roda. **Ele cabe nos seus testes e nas suas próprias
execuções enquanto você desenvolve, e na CI a cada mudança**: `go test -race ./...` é a linha mais
útil que este curso acrescenta a um projeto. Ele não cabe no binário que você entrega, onde a
lentidão e a memória seriam pagas por todo usuário por uma conferência que só ajuda quem lê o
relatório.

Mais dois fatos moldam o uso. **Ele só encontra as corridas que acontecem enquanto observa**, então
uma corrida num caminho que nenhum teste percorre fica invisível, e é por isso que a seção 05 desta
lição escreve um teste cujo único trabalho é fazer as goroutines se encontrarem. E ele relata em vez
de parar: o programa segue depois de cada relatório e sai com o status 66 no fim, para que um script
ou um job de CI distinga uma execução limpa de uma suja sem ler o texto.
