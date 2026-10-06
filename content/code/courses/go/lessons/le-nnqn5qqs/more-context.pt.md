---
title: "Mais contexto: GOTRACEBACK, debug.Stack e slog"
version: 1
---

Costuma-se imaginar um trace como tudo ou nada: o runtime o imprime quando o programa morre, e um
programa que faz recover não tem nada para imprimir. Nenhuma das metades é verdade. **Quanto o
runtime imprime é uma configuração, e um programa que faz recover pode pedir o trace ele mesmo.**
Esta seção faz as duas coisas, com o programa de pedidos da seção 02.

## `GOTRACEBACK`

A variável de ambiente `GOTRACEBACK` decide quanto um programa imprime ao morrer. O pacote
`runtime` a documenta num parágrafo:

```
ana@vm:~/stacks$ go doc runtime | sed -n 243,260p
The GOTRACEBACK variable controls the amount of output generated when a Go
program fails due to an unrecovered panic or an unexpected runtime condition.
By default, a failure prints a stack trace for the current goroutine, eliding
functions internal to the run-time system, and then exits with exit code 2.
The failure prints stack traces for all goroutines if there is no current
goroutine or the failure is internal to the run-time. GOTRACEBACK=none omits
the goroutine stack traces entirely. GOTRACEBACK=single (the default) behaves
as described above. GOTRACEBACK=all adds stack traces for all user-created
goroutines. GOTRACEBACK=system is like “all” but adds stack frames for
run-time functions and shows goroutines created internally by the run-time.
GOTRACEBACK=crash is like “system” but crashes in an operating system-specific
manner instead of exiting. For example, on Unix systems, the crash raises
SIGABRT to trigger a core dump. GOTRACEBACK=wer is like “crash” but doesn't
disable Windows Error Reporting (WER). For historical reasons, the GOTRACEBACK
settings 0, 1, and 2 are synonyms for none, all, and system, respectively.
The runtime/debug.SetTraceback function allows increasing the amount of output
at run time, but it cannot reduce the amount below that specified by the
environment variable.
```

`none` é a que tira alguma coisa:

```
ana@vm:~/stacks$ GOTRACEBACK=none ./stacks; echo $?
panic: runtime error: index out of range [4] with length 4
2
```

A mensagem e o código de saída sobrevivem e todos os quadros somem, então ninguém consegue dizer
qual índice deu errado. **O padrão, `single`, é a configuração certa para quase todo programa**, e
os movimentos úteis são para cima. `all` acrescenta toda goroutine que o programa iniciou, que é o
que um servidor precisa quando a goroutine que entrou em panic estava esperando outra; o curso
`go-concurrency` escreve programas em que isso importa. `system` acrescenta os quadros e as
goroutines do próprio runtime, que interessam a quem persegue um bug no próprio Go. `crash` também
deixa um core dump, uma cópia da memória do processo, para um depurador abrir depois.

A variável pertence a quem inicia o programa, uma definição de serviço ou o ambiente de um
contêiner, e vale sem recompilar nada.

## O trace de um panic que você recuperou

A lição 36 pôs um recover numa fronteira para que uma requisição ruim ou um trabalho ruim não
encerrasse o programa. Esse recover tem um custo: o runtime só imprime um trace para um panic que
mata o programa, então **um panic recuperado não deixa trace a menos que o programa escreva um**.
Uma linha de log que diz `index out of range` e mais nada manda alguém procurar um índice no
código inteiro.

`~/stacks-jobs` calcula o preço de três pedidos, um de cada vez, com as mesmas quatro funções de
`~/stacks`. `price` cuida de um pedido e é a fronteira:

```go
func price(id int, lines []line) {
	defer func() {
		if r := recover(); r != nil {
			slog.Error("order failed", "order", id, "panic", r)
			os.Stderr.Write(debug.Stack())
		}
	}()
	slog.Info("order priced", "order", id, "total", orderTotal(lines))
}

func main() {
	log.SetFlags(0) // slog's default output goes through log
	orders := [][]line{
		{{"coffee", 2}},
		{{"cake", 4}},
		{{"coffee", 1}, {"cake", 1}},
	}
	for i, o := range orders {
		price(i+1, o)
	}
}
```

```
ana@vm:~/stacks-jobs$ go build && ./jobs; echo $?
INFO order priced order=1 total=854
ERROR order failed order=2 panic="runtime error: index out of range [4] with length 4"
goroutine 1 [running]:
runtime/debug.Stack()
	/usr/local/go/src/runtime/debug/stack.go:26 +0x5e
main.price.func1()
	/home/ana/stacks-jobs/main.go:41 +0xfe
panic({0x675570?, 0x2e62bc970030?})
	/usr/local/go/src/runtime/panic.go:859 +0x125
main.unitPrice(...)
	/home/ana/stacks-jobs/main.go:22
main.lineTotal(...)
	/home/ana/stacks-jobs/main.go:26
main.orderTotal(...)
	/home/ana/stacks-jobs/main.go:32
main.price(0x2, {0x2e62bc9ebe30?, 0x2e62bc9bce38?, 0x41e8f9?})
	/home/ana/stacks-jobs/main.go:44 +0x1fd
main.main()
	/home/ana/stacks-jobs/main.go:55 +0x12f
INFO order priced order=3 total=1150
0
```

O pedido 2 falhou e os pedidos 1 e 3 tiveram o preço calculado. O programa terminou com código 0,
porque nenhum panic chegou ao topo de uma goroutine. Dois pacotes fizeram o trabalho na função
adiada.

**`log/slog` escreve linhas de log estruturadas.** `slog.Info` e `slog.Error` recebem uma mensagem
e depois pares de chave e valor, e os imprimem como `chave=valor`, então `order=2` pode ser buscado,
e contado, por quem quer que colete os logs. O `slog` entrega a saída padrão dele ao pacote `log`,
e é por isso que `log.SetFlags(0)` tirou a data do começo de cada linha, como fez no servidor da
lição 36:

```
ana@vm:~/stacks-jobs$ go doc log/slog | sed -n 30,33p
The default handler formats the log record's message, time, level, and
attributes as a string and passes it to the log package.

    2022/11/08 15:28:26 INFO hello count=3
```

Um serviço costuma trocar o padrão por um handler que escreve um objeto JSON por linha, um formato
que sistemas de log leem sem precisar aprender:

```
ana@vm:~/stacks-jobs$ go doc log/slog | sed -n 50,57p
The package also provides JSONHandler, whose output is line-delimited JSON:

    logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
    logger.Info("hello", "count", 3)

produces this output:

    {"time":"2022-11-08T15:28:26.000000000-05:00","level":"INFO","msg":"hello","count":3}
```

**`debug.Stack` devolve o trace da goroutine que o chama**, formatado exatamente como o runtime
imprime um:

```
ana@vm:~/stacks-jobs$ go doc runtime/debug.Stack
package debug // import "runtime/debug"

func Stack() []byte
    Stack returns a formatted stack trace of the goroutine that calls it. It
    calls runtime.Stack with a large enough buffer to capture the entire trace.

```

Leia o trace que ele escreveu de cima para baixo. `runtime/debug.Stack` é a chamada que tirou a
foto. `main.price.func1` é a função literal adiada, que o compilador batiza com o nome da função em
que ela está. `panic` é a função do runtime que estava conduzindo o panic. E debaixo desses três,
ainda ali, estão `unitPrice`, `lineTotal` e `orderTotal`, os quadros que o panic estava deixando.
**Uma função adiada roda em cima dos quadros que entraram em panic**, antes que eles saiam da pilha,
e é por isso que um trace tirado dentro dela ainda mostra a linha 22, onde está o bug.

Os valores entre parênteses nas linhas `panic` e `main.price` são endereços de memória, e não são
os mesmos de uma execução para a outra:

```
ana@vm:~/stacks-jobs$ for i in 1 2; do ./jobs 2>&1 | grep '^panic('; done
panic({0x675570?, 0x32f11243a030?})
panic({0x675570?, 0x17250a3a000?})
```

A palavra do tipo, `0x675570`, ficou parada e a segunda palavra mudou, e é por isso que esta lição
cita uma execução de cada. **Compare traces por função, arquivo e linha, nunca pelos valores em
hexadecimal.** Duas quedas na mesma linha são um bug só, digam o que disserem os endereços.

Num serviço de verdade, o trace pertence ao próprio registro de log, e não a uma escrita separada
na saída de erro, para que a linha que informa a falha e o trace que a explica fiquem juntos:
`string(debug.Stack())` é mais um valor para mais uma chave.
