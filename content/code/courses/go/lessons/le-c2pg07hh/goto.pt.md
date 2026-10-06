---
title: goto, e os dois saltos que ele recusa
version: 1
---

O `goto` é uma das 25 palavras-chave que a lição 1 contou. Ele recebe um rótulo como os da seção
02 e salta para ele de qualquer ponto da mesma função. Este programa, em `~/flow-goto`, é um laço sem nenhum `for`:

```go
package main

import "fmt"

func main() {
	i := 0
again:
	fmt.Println("turn", i)
	i++
	if i < 3 {
		goto again
	}
	fmt.Println("after", i, "turns")
}
```

```
ana@vm:~/flow-goto$ go run .
turn 0
turn 1
turn 2
after 3 turns
```

É também exatamente o que ninguém deveria escrever. **Todo laço feito de `goto` é um `for` que não
diz que é um.** `for i := 0; i < 3; i++` põe o início, a condição e o passo numa linha e o corpo
entre chaves, e quem lê vê a forma antes de ler um único comando dela. Aqui, quem lê precisa achar
o rótulo, achar cada `goto` que o nomeia e deduzir, pelas condições em volta, que a coisa toda é um
laço. O `break` e o `continue` da seção 02, os rótulos da seção 03 e um `return` antecipado cobrem
quase todo salto de que um programa Go precisa, e cada um deles diz para onde vai pelo lugar onde
está escrito.

## Os dois saltos que o compilador recusa

O risco de qualquer salto é cair onde uma variável existe mas a declaração dela nunca rodou. Go
recusa os dois jeitos de chegar lá:

```go
package main

import "fmt"

func main() {
	n := len("hello")
	if n > 3 {
		goto done
	}
	msg := "short"
	fmt.Println(msg)
done:
	fmt.Println("finished")

	goto inside
	if n > 0 {
	inside:
		fmt.Println("inside the if")
	}
}
```

```
ana@vm:~/flow-jump$ go build
# example.com/jump
./main.go:8:8: goto done jumps over declaration of msg at ./main.go:10:6
./main.go:15:7: goto inside jumps into block starting at ./main.go:16:11
```

**Um `goto` não pode pular uma declaração cuja variável ainda está no escopo no rótulo.** `msg` é
declarada na linha 10 e o escopo dela vai até o fim de `main`, então em `done:` o nome `msg`
existiria sem que a declaração tivesse rodado. A mensagem dá o nome da variável e a linha. Declarar
`msg` acima do `goto` com `var msg string`, e só atribuir o valor abaixo, satisfaz a regra, porque
aí nada novo entra no escopo no rótulo.

**E um `goto` não pode saltar para dentro de um bloco vindo de fora dele.** O corpo do `if` é um
bloco próprio, o escopo mais interno da lição 6, e entrar nele em `inside:` pularia a condição que
o protege. Saltar para fora de um bloco é permitido: o laço do começo desta seção faz isso de dentro
do seu `if`, e o `break` faz isso o tempo todo.

## Onde ele ainda é usado

O código-fonte do próprio Go tem alguns lugares em que um `goto` é a coisa mais clara disponível, e
a biblioteca padrão do Go 1.27.1 do laboratório está em `/usr/local/go/src` para quem quiser olhar.
O uso mais denso é o código que roda num processo novo entre o `fork` e o `exec` no Linux:

```
ana@vm:~/flow-goto$ grep -c 'goto childerror' /usr/local/go/src/syscall/exec_linux.go
37
ana@vm:~/flow-goto$ sed -n '228,232p' /usr/local/go/src/syscall/exec_linux.go
	// vfork requires that the child not touch any of the parent's
	// active stack frames. Hence, the child does all post-fork
	// processing in this stack frame and never returns, while the
	// parent returns immediately from this frame and does all
	// post-fork processing in the outer frame.
ana@vm:~/flow-goto$ sed -n '678,683p' /usr/local/go/src/syscall/exec_linux.go
childerror:
	// send error code on pipe
	RawSyscall(SYS_WRITE, uintptr(pipe), uintptr(unsafe.Pointer(&err1)), unsafe.Sizeof(err1))
	for {
		RawSyscall(SYS_EXIT, 253, 0, 0)
	}
```

Trinta e sete linhas de uma única função saltam para o mesmo rótulo. O comentário diz por que a
saída comum está fechada: o processo filho **nunca retorna** desta função, então cada falha não pode
fazer `return err` como a lição 32 mostra. Em vez disso, cada uma salta para `childerror:`, que
escreve o código de erro num pipe para o processo pai e encerra o processo. Uma saída, compartilhada
por todas as falhas, numa função que não pode retornar: é essa a forma em que o `goto` ainda cabe.

Quão raro ele é, contado na mesma árvore de código-fonte, sem os testes:

```
ana@vm:~/flow-goto$ grep -rE --include=*.go '^\s*goto\b' /usr/local/go/src | grep -vc -e _test.go -e testdata
572
ana@vm:~/flow-goto$ grep -rE --include=*.go '^\s*break\b' /usr/local/go/src | grep -vc -e _test.go -e testdata
22416
```

572 linhas começam com `goto` e 22.416 começam com `break`, mais ou menos um `goto` para cada
quarenta. Você vai ler `goto` no código dos outros de vez em quando, em lugares como este. **Escreva
um só quando `break`, `continue`, um rótulo e `return` já tiverem sido tentados e cada um tiver
deixado a função mais difícil de ler.**
