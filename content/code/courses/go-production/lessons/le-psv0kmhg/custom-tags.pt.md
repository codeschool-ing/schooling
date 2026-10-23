---
title: Tags suas
version: 1
---

Uma tag de build não precisa nomear um sistema. **Qualquer palavra numa linha `//go:build` que o
build não define sozinho é falsa, até uma linha de comando defini-la com `-tags`.** Isso faz de uma
restrição um interruptor de arquivos inteiros: código que existe num build do programa e está
ausente do outro, escolhido quando o programa é compilado e não quando ele roda.

Dois usos são comuns o bastante para mostrar. Um build de depuração que diz mais que o que você
distribui, e um conjunto de testes lentos ou exigentes demais para rodar toda vez.

## Um build de depuração

O `main.go` da seção 02 chama `debugf` depois de cada contagem, e `debugf` é uma variável que guarda
uma função que não faz nada. Um arquivo compilado só com a tag `debug` a substitui. Salve como
`debug.go`:

```go
//go:build debug

package main

import (
	"fmt"
	"io"
)

func init() {
	debugf = func(w io.Writer, format string, a ...any) {
		fmt.Fprintf(w, "hits: debug: "+format+"\n", a...)
	}
}
```

**Uma função `init` roda antes do `main`**, então quando o `summarise` chama `debugf`, um build de
debug já tem a versão que imprime. Compilado dos dois jeitos:

```
ana@vm:~/tags$ go build -o hits . && ./hits top -n 1 access.log
path    requests
/login  2576
ana@vm:~/tags$ go build -tags debug -o hits-debug . && ./hits-debug top -n 1 access.log
hits: debug: 20000 lines, 914867 bytes in 6.991181ms
path    requests
/login  2576
```

O build comum imprimiu a tabela da aula 1 e nada mais. O build de debug imprimiu antes uma linha a
mais na saída de erro: as 20.000 linhas, os 914.867 bytes do `access.log` e o tempo que o
`tally.Count` levou, uns poucos milissegundos. O tempo muda a cada execução; as duas contagens não.

**As tags fazem parte do que um binário registra sobre o próprio build**, ao lado do `GOOS` e do
`GOARCH` que a aula 16 lê de volta com o mesmo comando, então um binário de debug que vá parar onde
não devia pode ser reconhecido:

```
ana@vm:~/tags$ go version -m hits-debug | grep -- -tags
	build	-tags=debug
ana@vm:~/tags$ go list -f '{{.GoFiles}}' .; go list -tags debug -f '{{.GoFiles}}' .
[main.go progress.go progress_unix.go]
[debug.go main.go progress.go progress_unix.go]
ana@vm:~/tags$ strings hits | grep -c "hits: debug: "; strings hits-debug | grep -c "hits: debug: "
0
1
```

O `go list -tags debug` acrescenta `debug.go` aos arquivos que o pacote compila. E a string que abre
a linha de debug está num binário e não no outro: o `strings` imprime o texto legível de um arquivo,
e o `grep -c` conta as ocorrências. **Código atrás de uma tag que não foi passada não está no
binário**, e essa é a diferença entre uma tag e uma flag `-debug` lida na execução.

A variável no `main.go` é um jeito de organizar isso. O outro jeito comum é um par de arquivos,
`debug.go` com `//go:build debug` e `nodebug.go` com `//go:build !debug`, cada um definindo a mesma
função ou constante. O par diz mais nos nomes dos arquivos; a variável faz com que só um arquivo
precise existir, e o build comum não pode quebrar por falta de um par.

## Como escrever `-tags`

Todo comando go que compila ou lê pacotes aceita `-tags`: `build`, `run`, `test`, `vet`, `list`,
`install`. Várias tags formam um argumento só, **separadas por vírgulas**: `-tags debug,integration`.
A forma antiga com espaços ainda funciona, e o `go help build` a chama de obsoleta. Uma tag que nada
no código cita é aceita sem uma palavra, então um `-tags debgu` digitado errado compila o binário
comum e não diz nada. Para passar as mesmas tags a todo comando num shell, `GOFLAGS=-tags=debug` faz
isso; definir e esquecer é como um build de debug acaba distribuído.

## Testes que esperam ser chamados

O `main_test.go` da aula 1 chama `run` com um buffer para cada fluxo e termina em milissegundos. Ele
nunca compila o programa nem inicia um processo. Um teste que faz isso, compila o `hits`, escreve um
log com o `genlog` e roda o binário sobre ele como uma pessoa faria, pega outra classe de erro e
custa um build a cada vez. **Um teste assim fica atrás de uma tag**, para o `go test` pulá-lo e um
job de CI que o peça rodá-lo. Salve como `integration_test.go`:

```go
//go:build integration

package main

import (
	"bytes"
	"os/exec"
	"path/filepath"
	"testing"
)

// TestBinary builds hits and runs the binary the way a person does, on a log
// that genlog writes. It needs the go command and a build of its own, so it
// runs only when somebody asks for it with -tags integration.
func TestBinary(t *testing.T) {
	bin := filepath.Join(t.TempDir(), "hits")
	if out, err := exec.Command("go", "build", "-o", bin, ".").CombinedOutput(); err != nil {
		t.Fatalf("go build: %v\n%s", err, out)
	}
	log, err := exec.Command("go", "run", "./tools/genlog", "-n", "20000").Output()
	if err != nil {
		t.Fatalf("genlog: %v", err)
	}

	cmd := exec.Command(bin, "top", "-n", "1")
	cmd.Stdin = bytes.NewReader(log)
	out, err := cmd.Output()
	if err != nil {
		t.Fatalf("hits top: %v", err)
	}
	if want := "path    requests\n/login  2576\n"; string(out) != want {
		t.Errorf("hits top printed %q, want %q", out, want)
	}

	var stderr bytes.Buffer
	cmd = exec.Command(bin)
	cmd.Stderr = &stderr
	if err := cmd.Run(); err == nil {
		t.Error("hits with no command succeeded")
	}
	if stderr.String() != usage {
		t.Errorf("hits with no command printed %q, want the usage", stderr.String())
	}
}
```

A última checagem compara o que o binário imprime sem comando com `usage`, a constante do `main.go`,
para que uma mudança no texto de uso não deixe o binário para trás. Sem a tag e com ela:

```
ana@vm:~/tags$ go test -count=1 .
ok  	example.com/hits	0.002s
ana@vm:~/tags$ go test -count=1 -tags integration -run TestBinary -v .
=== RUN   TestBinary
--- PASS: TestBinary (0.32s)
PASS
ok  	example.com/hits	0.322s
ana@vm:~/tags$ go list -f '{{.TestGoFiles}} {{.IgnoredGoFiles}}' .
[main_test.go] [debug.go integration_test.go progress_darwin.go progress_other.go]
```

**O `go test` simples não compilou `integration_test.go`**; o `go list` o cita entre os arquivos
ignorados, junto com `debug.go` e os dois arquivos por sistema que esta máquina não usa. Com
`-tags integration` o teste compilou o `hits`, rodou e passou em cerca de um terço de segundo, mais
de cem vezes o `0.002s` da execução comum. O `-run TestBinary` escolheu o teste pelo nome, e o `-count=1`
impediu que as duas execuções viessem do cache.

## O que uma tag custa

Um arquivo atrás de uma tag só é compilado por um comando que cite a tag. **Todo outro comando o
trata como se ele não existisse**: `go build`, `go vet` e `go test` leem o pacote sem ele. Então uma
mudança em outro lugar pode quebrá-lo, e nada do que você roda normalmente avisa.

Aqui está isso acontecendo. O `gofmt -r` reescreve código Go seguindo um padrão, e
`'usage -> usageText'` renomeia a constante em todo o `main.go`, o tipo de arrumação que qualquer um
faria:

```
ana@vm:~/tags$ gofmt -r 'usage -> usageText' -w main.go && go vet ./... && go test -count=1 ./... && echo green
ok  	example.com/hits	0.002s
?   	example.com/hits/internal/tally	[no test files]
?   	example.com/hits/tools/genlog	[no test files]
green
ana@vm:~/tags$ go vet -tags integration .
# example.com/hits
# [example.com/hits]
vet: ./integration_test.go:41:24: undefined: usage
ana@vm:~/tags$ gofmt -r 'usageText -> usage' -w main.go && go vet -tags integration . && echo clean
clean
```

Depois da renomeação, o `go vet` saiu limpo, todos os testes passaram e a linha disse `green`. **O
único arquivo que ainda diz `usage` é o que nenhum desses comandos compilou**, e só o `go vet -tags
integration` o encontrou. Num projeto, isso é um job de CI que roda uma vez por noite, ou um arquivo
que ninguém compila desde que a pessoa que o escreveu saiu. O segundo `gofmt -r` devolveu o nome.

O remédio não é evitar tags, que fazem um serviço que nada mais faz. É garantir que **toda tag que o
código usa seja citada por pelo menos um comando que roda a cada mudança**, o que na maioria dos
projetos quer dizer uma execução do vet por tag no CI. A seção 05 escreve essa execução.
