---
title: unsafe.Pointer, uintptr e os seis padrões válidos
version: 1
---

Dois tipos carregam um endereço, e é fácil confundi-los porque os dois aparecem impressos como
número. **`unsafe.Pointer` é um ponteiro que o sistema de tipos deixou de verificar**: pode ser
convertido de e para um ponteiro de qualquer tipo, e o coletor de lixo continua o vendo como
ponteiro. **`uintptr` é um inteiro**, largo o bastante para guardar um endereço e sem mais
significado para o runtime do que um `int` guardando uma temperatura. A documentação de
`unsafe.Pointer` lista as quatro conversões que tornam o primeiro tipo especial:

- um valor ponteiro de qualquer tipo pode ser convertido em `Pointer`;
- um `Pointer` pode ser convertido em valor ponteiro de qualquer tipo;
- um `uintptr` pode ser convertido em `Pointer`;
- um `Pointer` pode ser convertido em `uintptr`.

As duas primeiras são o jeito de ler um tipo como outro. As duas últimas são o jeito de um
endereço virar aritmética e voltar, e é nelas que mora quase todo mau uso.

## Os padrões que a documentação permite

O `go doc unsafe.Pointer` lista seis padrões e diz de todo o resto que é "likely to be invalid
today or to become invalid in the future", provavelmente inválido hoje ou no futuro. Essa frase é o
contrato. **Nenhuma regra da linguagem torna errado o código de fora da lista; existe a lista, e o
código fora dela pode compilar, rodar e passar nos testes até que uma versão mude alguma coisa por
baixo dele.**

| | padrão | o exemplo da documentação |
|---|---|---|
| 1 | `*T1` para `Pointer` para `*T2`, quando `T2` não é maior e tem layout equivalente | `math.Float64bits` lendo um `float64` como `uint64` |
| 2 | `Pointer` para `uintptr`, e nunca de volta | imprimir um endereço |
| 3 | `Pointer` para `uintptr` e de volta, com aritmética, numa expressão só | o endereço de um campo ou de um elemento de array |
| 4 | `Pointer` para `uintptr` na lista de argumentos de uma chamada como `syscall.Syscall` | passar um buffer para o kernel |
| 5 | o resultado de `reflect.Value.Pointer` ou `UnsafeAddr`, convertido na hora | o `reflect` da lição 21 alcançando a memória |
| 6 | o campo `Data` de `reflect.SliceHeader` ou `StringHeader` | montar um slice à mão, hoje depreciado |

O padrão 3 vem com três condições que a documentação explicita. **O resultado precisa continuar
apontando para dentro do objeto alocado original**, então até um ponteiro um byte depois do fim de
um slice é inválido, coisa que C permite. O ponteiro não pode ser `nil`. E as duas conversões
precisam aparecer na mesma expressão, com nada além de aritmética entre elas. O padrão 6 é
história: o `go doc reflect.SliceHeader` diz "Deprecated: Use unsafe.Slice or unsafe.SliceData
instead", as funções que a seção 04 usa.

## Um inteiro não mantém nada vivo

O motivo do "na mesma expressão" é o que o coletor de lixo consegue ver. Ele encontra os objetos
ainda em uso seguindo ponteiros, e um `uintptr` não é ponteiro. **Um objeto cujo único rastro é o
seu endereço num `uintptr` é lixo, e o coletor o libera.** Este programa guarda o endereço de um
`tally.Entry`, larga o ponteiro e pede ao runtime que avise quando a entrada for coletada. Salve-o
como `alive/main.go`:

```go
// Command alive shows that an address held as a uintptr keeps nothing alive.
package main

import (
	"fmt"
	"runtime"
	"time"
	"unsafe"

	"example.com/hits/internal/tally"
)

func main() {
	e := &tally.Entry{Method: "GET", Path: "/login", Status: 200}
	runtime.AddCleanup(e, func(path string) {
		fmt.Println("collector: freed the entry for", path)
	}, e.Path)

	addr := uintptr(unsafe.Pointer(e)) // an integer, not a reference
	e = nil                            // the last real reference is gone

	runtime.GC()
	time.Sleep(10 * time.Millisecond) // cleanups run on their own goroutine
	fmt.Printf("main still holds %#x, which now points at nothing of ours\n", addr)
}
```

`runtime.AddCleanup` roda uma função numa goroutine própria algum tempo depois que o primeiro
argumento deixa de ser alcançável. A função recebe `e.Path`, uma cópia, porque uma limpeza capaz de
alcançar a entrada a manteria alcançável para sempre. Rode duas vezes:

```
ana@vm:~/unsafe$ go run ./alive
collector: freed the entry for /login
main still holds 0x316c3ee96000, which now points at nothing of ours
ana@vm:~/unsafe$ go run ./alive
collector: freed the entry for /login
main still holds 0x7d5063e2000, which now points at nothing of ours
```

**A entrada foi liberada enquanto `main` ainda guardava o endereço dela.** Nada deu errado aqui,
porque o programa nunca transforma `addr` de volta em ponteiro, que é o padrão 2. Se fizesse isso,
leria memória que o alocador estava livre para entregar a qualquer coisa. O endereço muda a cada
execução porque o Go 1.27 põe o heap numa base aleatória em máquinas de 64 bits (o
`runtime/malloc.go` chama isso de `randomizeHeapBase`), então nem um número guardado de uma
execução significa algo na seguinte.

**O coletor atual não move nenhum objeto do heap, e isso não serve de defesa.** As pilhas das
goroutines se movem: uma pilha que fica sem espaço é copiada para uma maior e todo ponteiro para
dentro dela é ajustado, mas um `uintptr` com o endereço de uma variável local não é ajustado,
porque o runtime não sabe que aquilo é um endereço. O texto de ajuda da verificação `unsafeptr` do
`go vet` dá exatamente esse motivo: uma palavra assim "will be invisible to stack copying and to the
garbage collector", fica invisível para a cópia de pilha e para o coletor.

## O que o `go vet` pega

O próximo programa lê `Status` de um `tally.Entry` por aritmética de endereço, de três jeitos.
Salve-o como `field/main.go`:

```go
// Command field reads one field of a tally.Entry through unsafe.Pointer,
// once by a valid pattern and once by an invalid one.
package main

import (
	"fmt"
	"unsafe"

	"example.com/hits/internal/tally"
)

func main() {
	e := tally.Entry{Method: "POST", Path: "/api/users", Status: 404}

	// Pattern 3: Pointer to uintptr and back, in one expression.
	p := unsafe.Pointer(uintptr(unsafe.Pointer(&e)) + unsafe.Offsetof(e.Status))
	fmt.Println("pattern 3:  ", *(*int)(p))

	// unsafe.Add says the same thing without the round trip.
	q := unsafe.Add(unsafe.Pointer(&e), unsafe.Offsetof(e.Status))
	fmt.Println("unsafe.Add: ", *(*int)(q))

	// INVALID: the address spends a moment as a plain integer.
	u := uintptr(unsafe.Pointer(&e))
	r := unsafe.Pointer(u + unsafe.Offsetof(e.Status))
	fmt.Println("stored:     ", *(*int)(r))
}
```

`unsafe.Add`, do Go 1.17, é o padrão 3 sem a volta por `uintptr`, e a documentação acrescenta que
"the rules for valid uses of Pointer still apply", as regras de uso válido continuam valendo. Rode,
e depois passe o vet:

```
ana@vm:~/unsafe$ go run ./field
pattern 3:   404
unsafe.Add:  404
stored:      404
ana@vm:~/unsafe$ go vet ./field; echo $?
field/main.go:25:7: possible misuse of unsafe.Pointer
1
```

**Os três imprimiram 404, inclusive o inválido.** O endereço passou um comando inteiro como
inteiro, nada se moveu e nada foi coletado naquele instante, e o programa funcionou. Essa é a forma
comum de um bug de `unsafe`: não é uma falha na linha errada, é uma falha num outro dia, sob carga,
na execução em que o coletor ou a pilha agiram justo entre aquelas duas linhas. O `go vet` o achou
olhando o código em vez da execução: o `unsafeptr` acusa um `uintptr` convertido de volta em
`Pointer` em qualquer lugar fora dos padrões.

**O `go test` não roda essa verificação.** A ajuda dele lista o subconjunto do `vet` que roda antes
de um binário de teste (`atomic`, `bools`, `buildtag`, `directive`, `errorsas`, `ifaceassert`,
`nilfunc`, `printf`, `stdversion`, `stringintconv` e `tests`), e o `unsafeptr` não está nele. Um
projeto com `unsafe` precisa de `go vet ./...` como passo próprio, que é o assunto da lição 7.

## O que o `go vet` não pega, e o checkptr pega

O `vet` lê código, e algumas conversões inválidas têm cara de perfeitamente normais. Este programa
lê um código de status de um registro binário, uma vez por um cast de ponteiro e outra pelo
`encoding/binary`. Um registro é um byte de versão, um id de requisição de 16 bytes e o status em
oito bytes, 25 no total; o segundo registro está cortado um byte depois do início do status, como
um arquivo truncado o deixaria. Salve-o como `cast/main.go`:

```go
// Command cast reads the status code out of binary records. A record is a
// version byte, a request id of 16 bytes, and the status as eight
// little-endian bytes.
package main

import (
	"encoding/binary"
	"fmt"
	"unsafe"
)

const statusAt = 17

// quick reads the eight bytes of the status through a pointer cast.
func quick(rec []byte) uint64 {
	return *(*uint64)(unsafe.Pointer(&rec[statusAt]))
}

// checked reads the same eight bytes through encoding/binary.
func checked(rec []byte) uint64 {
	return binary.LittleEndian.Uint64(rec[statusAt:])
}

// record builds a whole record with the given status.
func record(status uint64) []byte {
	rec := make([]byte, statusAt+8)
	rec[0] = 1
	binary.LittleEndian.PutUint64(rec[statusAt:], status)
	return rec
}

// cut copies the first n bytes of a record, the way a truncated file would
// hand them over.
func cut(rec []byte, n int) []byte {
	return append([]byte(nil), rec[:n]...)
}

func main() {
	whole := record(404)
	for _, rec := range [][]byte{whole, cut(whole, statusAt+1)} {
		fmt.Printf("%d bytes: quick   %d\n", len(rec), quick(rec))
		fmt.Printf("%d bytes: checked %d\n", len(rec), checked(rec))
	}
}
```

```
ana@vm:~/unsafe$ go build -o bin/cast ./cast && bin/cast 2>&1 | head -4; echo ${PIPESTATUS[0]}
25 bytes: quick   404
25 bytes: checked 404
18 bytes: quick   3602879701896396948
panic: runtime error: index out of range [7] with length 1
2
ana@vm:~/unsafe$ go vet ./cast; echo $?
0
```

**O cast leu oito bytes onde o registro tinha um, e devolveu um número.** Os outros sete vieram de
depois do fim do registro: bytes sobrando da alocação dele e o primeiro byte do que quer que o
alocador tenha posto ao lado. O `encoding/binary` conferiu o tamanho e entrou em pânico, citando o
índice e o tamanho, que é para isso que serve uma verificação de limites. E o `go vet` fica calado.
Ele não tem regra nenhuma sobre o padrão 1, e se há mesmo oito bytes depois de `&rec[statusAt]`
depende do tamanho de `rec` em tempo de execução, que nenhuma leitura do código consegue saber.

O compilador consegue instrumentar toda conversão envolvendo `unsafe.Pointer` com uma verificação
em tempo de execução, chamada checkptr. **`-gcflags=all=-d=checkptr` a liga para todos os pacotes
do build**, e o `-race` também: o tratamento de flags do compilador diz "-race, -msan and -asan
imply -d=checkptr", mais um motivo para o detector de corrida da lição 15 estar no CI.

```
ana@vm:~/unsafe$ go build -gcflags=all=-d=checkptr -o bin/cast ./cast && bin/cast 2>&1 | head -3; echo ${PIPESTATUS[0]}
25 bytes: quick   404
25 bytes: checked 404
fatal error: checkptr: converted pointer straddles multiple allocations
2
ana@vm:~/unsafe$ go build -race -o bin/cast ./cast && bin/cast 2>&1 | head -3; echo ${PIPESTATUS[0]}
25 bytes: quick   404
25 bytes: checked 404
fatal error: checkptr: converted pointer straddles multiple allocations
2
```

**O registro inteiro passou e o cortado parou o programa**, antes que `quick` devolvesse seu número
inventado. O checkptr compara a alocação onde os oito bytes começam com aquela onde terminam, e aqui
elas diferem. O alocador entrega objetos pequenos em tamanhos fixos (16, 24 e 32 bytes são três
deles, listados em `internal/runtime/gc/sizeclasses.go`), então o registro de 18 bytes fica numa
vaga de 24, e os bytes 17 a 24 passam um byte além dela. A mesma comparação explica o limite dele.
Uma leitura que fica dentro dos bytes sobrando da própria vaga passa, e qualquer coisa na pilha
também, que o checkptr trata como uma região só. **Uma execução limpa sob o checkptr diz que nenhuma
conversão que ele verificou era inválida, e não diz nada sobre as que ele não conseguiu ver.**
