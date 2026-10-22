---
title: Deadlock, barulhento e silencioso
version: 1
---

A regra da seção 02 tem uma consequência que morde todo mundo uma vez. **Um envio num canal sem
buffer, sem nenhuma outra goroutine pronta para receber, espera para sempre**, e o mesmo vale para um
recebimento sem ninguém enviando. Quando isso deixa toda goroutine do programa esperando, nada pode
andar de novo: isso é um deadlock.

## O tipo barulhento

A versão mais curta envia e recebe na mesma goroutine, salvo como `stuck.go`:

```go
// Command stuck sends on an unbuffered channel with nobody to receive.
package main

import "fmt"

func main() {
	ch := make(chan int)
	ch <- 42
	fmt.Println(<-ch)
}
```

```
ana@vm:~/buffers$ go run stuck.go
fatal error: all goroutines are asleep - deadlock!

goroutine 1 [chan send]:
main.main()
	/home/ana/buffers/stuck.go:8 +0x36
exit status 2
ana@vm:~/buffers$ go vet stuck.go && echo "vet: no complaint"
vet: no complaint
ana@vm:~/buffers$ sed 's/make(chan int)/make(chan int, 1)/' stuck.go > stuck-fixed.go
ana@vm:~/buffers$ go run stuck-fixed.go
42
```

`main` envia num canal sem buffer, e a única goroutine que poderia receber é o próprio `main`,
ocupado enviando. Nada vai andar nunca, e o runtime percebeu: **`fatal error: all goroutines are
asleep - deadlock!`**, goroutine 1 no estado `[chan send]`, na linha 8, que é `ch <- 42`. O estado
entre colchetes vale a leitura em qualquer relatório desses; ele diz o que a goroutine esperava
fazer.

O `go vet` aprovou o arquivo, porque isso não é algo que o texto de um programa mostra com
segurança: depende de que goroutines existem quando o envio roda. Um buffer de um basta para
consertar este programa em particular, e a transcrição faz essa mudança com `sed`: o envio agora tem
espaço, retorna na hora, e o recebimento pega o valor. **Esse conserto funciona porque exatamente um
valor é enviado antes do recebimento.** Envie dois, e o segundo bloqueia como antes. Um buffer muda
o ponto em que um programa trava; não decide se ele trava.

## O tipo silencioso

A conferência do runtime tem uma condição, e a condição é a armadilha: ela só dispara quando
**toda** goroutine está bloqueada. Aqui uma goroutine fica presa exatamente como o `stuck.go`,
enquanto `main` se ocupa de outra coisa e depois retorna normalmente, salvo como `partial.go`:

```go
// Command partial leaves one goroutine stuck on a send while main carries on.
package main

import (
	"fmt"
	"runtime"
	"time"
)

func main() {
	results := make(chan int)
	go func() {
		results <- 42 // nobody will ever receive this
	}()

	for i := 1; i <= 3; i++ {
		time.Sleep(100 * time.Millisecond)
		fmt.Println("main still working, goroutines alive:", runtime.NumGoroutine())
	}
	fmt.Println("main returns")
}
```

```
ana@vm:~/buffers$ go run partial.go; echo "exit status: $?"
main still working, goroutines alive: 2
main still working, goroutines alive: 2
main still working, goroutines alive: 2
main returns
exit status: 0
```

Nenhum erro, status de saída 0. **A goroutine ficou presa do primeiro ao último instante**,
`NumGoroutine` a contou três vezes, e nada em lugar nenhum a relatou, porque `main` nunca ficou
bloqueado: estava dormindo, o que conta como uma goroutine que ainda pode andar. Quando `main`
retornou, a goroutine presa foi simplesmente descartada com o processo.

Num programa que retorna depois de um segundo, isso não custa nada. Num servidor que roda por meses,
uma goroutine presa assim a cada requisição é um vazamento de goroutine: memória que cresce até o
processo ser morto, sem mensagem em momento nenhum. **O deadlock barulhento é o de sorte.** A lição 6
trata do silencioso: como acontece, como achá-lo, e os padrões que o evitam.
