---
title: Escolhendo as checagens, e onde o vet para
version: 1
---

O vet tem poucos ajustes, de propósito: a suíte foi feita para rodar como vem. **O que dá para mudar é
quais analisadores rodam e, em alguns deles, o que eles sabem sobre o seu código.** Cada analisador é
uma flag com o nome dele, e a regra para combiná-las é curta: cite um ou mais como `-NOME` e só esses
rodam; desligue um com `-NOME=false` e todos os outros rodam.

```
ana@vm:~/vetted$ go vet -printf=false ./report ./notfound; echo $?
0
ana@vm:~/vetted$ go vet -copylocks -lostcancel ./... 2>&1 | sort
counter/main.go:15:9: Add passes lock by value: example.com/vetted/counter.Counter contains sync.Mutex
fetch/main.go:21:2: the cancel function is not used on all paths (possible context leak)
fetch/main.go:23:3: this return statement may be reached without using the cancel var defined on line 21
```

A primeira linha rodou tudo menos o `printf` sobre os dois programas cujo único bug é de `printf`, e
passou. A segunda rodou dois analisadores sobre o módulo inteiro e achou os bugs do `counter` e do
`fetch` e nada mais. A saída passa pelo `sort` porque **o vet checa os pacotes em paralelo e imprime as
descobertas de cada pacote quando ele termina**, então a ordem muda de uma execução para outra.

Desligar um analisador num projeto inteiro raramente é o certo; o caso para isso é um analisador que
vive relatando um padrão que o seu código usa de propósito, e a primeira coisa a tentar costuma ser
reescrever o padrão. **O vet não tem comentário que silencie uma linha**, e isso é deliberado: o critério
de precisão da seção 02 é o que deveria torná-lo desnecessário.

## O seu próprio `printf`

A maioria dos programas ganha uma função auxiliar de log que recebe um formato e argumentos, e **uma
string de formato só é checada quando o vet sabe que a função é um `printf`**. Ele deduz isso sozinho
na maioria dos casos: uma função que repassa o `format` e o `args...` direto ao `fmt.Sprintf`, ao
`fmt.Printf` ou a qualquer outra função que ele já sabe que formata é um *printf wrapper*, e quem a
chama é checado como quem chama o `fmt.Printf`. O `applog/main.go` tem duas auxiliares, escritas de
dois jeitos:

```go
// Command applog reports through two helpers of its own.
package main

import (
	"fmt"
	"os"
)

// logf writes one line to standard error, after the program's name.
func logf(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "applog: "+format+"\n", args...)
}

// warnf does the same with a label, by formatting the message first.
func warnf(format string, args ...any) {
	msg := fmt.Sprintf(format, args...)
	fmt.Fprintln(os.Stderr, "applog: warning:", msg)
}

func main() {
	logf("served %s in %d ms", "/login")
	warnf("%s took %d ms", 250, "/api/orders")
}
```

```
ana@vm:~/vetted$ go run ./applog
applog: served /login in %!d(MISSING) ms
applog: warning: %!s(int=250) took %!d(string=/api/orders) ms
ana@vm:~/vetted$ go vet ./applog
applog/main.go:22:9: example.com/vetted/applog.warnf format %s has arg 250 of wrong type int
ana@vm:~/vetted$ go vet -printf.funcs=logf ./applog
applog/main.go:21:21: example.com/vetted/applog.logf format %d reads arg #2, but call has 1 arg
applog/main.go:22:9: example.com/vetted/applog.warnf format %s has arg 250 of wrong type int
```

As duas chamadas estão erradas, e a execução simples mostra isso. O vet pegou só o `warnf`. **O `logf`
monta um formato novo por concatenação, então o parâmetro `format` dele nunca é repassado como
formato**, e a dedução do vet não o acompanha. Há duas correções. A flag `-printf.funcs` cita funções
extras a tratar como formatadoras, e um nome terminado em `f` é tomado como tendo um argumento de
formato antes do resto; o terceiro comando a usou e pegou o argumento que faltava. **A correção melhor é
o formato que o `warnf` já tem**: formatar primeiro com `fmt.Sprintf`, depois acrescentar a decoração.
Isso continua funcionando sem uma flag que cada pessoa e cada job de CI precisam lembrar de passar.

## O que o vet nunca vai dizer

Os três critérios do vet deixam de fora mais do que deixam entrar, e saber o que fica de fora impede
você de ler uma execução limpa como mais do que ela é.

| não é trabalho do vet | por quê | onde se acha |
|---|---|---|
| estilo: nomes, redação de comentários, uma função longa | código correto escrito de outro jeito não é bug | os linters da lição 8 |
| uma variável local ou um import não usados | o compilador já os recusa | `go build` |
| uma função, um parâmetro ou um nome exportado não usados | válidos, e muitas vezes propositais | o `staticcheck` da lição 8 |
| a maioria das desreferências de nil e das variáveis sombreadas | achá-las com precisão suficiente é a parte difícil | a lição 8, e os testes |
| uma corrida de dados entre goroutines | ela acontece em tempo de execução | o detector de corrida da lição 15 |

A quarta linha vale a pena ver. O `load/main.go` lê um nome de um arquivo:

```go
// Command load reads a name from a file, or says why it could not.
package main

import (
	"fmt"
	"os"
	"strings"
)

type Config struct {
	Name   string
	Source string
}

func parse(data []byte) (*Config, error) {
	return &Config{Name: strings.TrimSpace(string(data))}, nil
}

func load(path string) (*Config, error) {
	var cfg *Config
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	if len(data) > 0 {
		cfg, err := parse(data)
		if err != nil {
			return nil, err
		}
		cfg.Source = path
	}
	return cfg, nil
}

func main() {
	cfg, err := load("name.txt")
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	fmt.Println(cfg.Name, "from", cfg.Source)
}
```

```
ana@vm:~/vetted$ echo hits > name.txt
ana@vm:~/vetted$ go vet ./load; echo $?
0
ana@vm:~/vetted$ go run ./load 2>&1 | head -1
panic: runtime error: invalid memory address or nil pointer dereference
```

O vet deixou passar e o programa quebrou. **`cfg, err := parse(data)` declarou um segundo `cfg` dentro
do `if`**, preencheu esse e o largou na chave de fechamento, então o `load` devolveu o `cfg` de fora,
ainda nulo. Sombrear é válido e geralmente intencional, e separar o acidente da intenção é a parte
difícil: o analisador que procura isso diz na própria documentação que "generates too many false
positives and is not yet enabled by default", gera alarmes falsos demais e ainda não vem ligado. É o
critério de precisão, aplicado.

## Um vet que roda outros analisadores

O comando go pode rodar outra ferramenta de análise no lugar do vet, com `-vettool`, desde que ela
seja construída sobre o mesmo framework, `golang.org/x/tools/go/analysis`. Esse analisador, o
`shadow`, fica nesse módulo, fora da suíte, e pode ser instalado e chamado no dia em que você
quiser. A versão do `x/tools` é a que o curso fixa para o `goimports` da lição 6, e é por isso que o
`go install` não imprimiu nada aqui: o módulo já estava no cache desde a lição 6. Numa primeira
instalação ele lista o que baixa.

```
ana@vm:~/vetted$ go install golang.org/x/tools/go/analysis/passes/shadow/cmd/shadow@v0.52.0
ana@vm:~/vetted$ go vet -vettool=$(command -v shadow) ./load
load/main.go:26:3: declaration of "cfg" shadows declaration at line 20
```

**Uma linha, e ela é o bug.** Essa é a porta por onde a lição 8 entra: o `staticcheck` e o
`golangci-lint` são coleções de analisadores que fazem trocas diferentes das do vet, mais checagens
por um pouco mais de ruído, e o framework por baixo é o mesmo.
