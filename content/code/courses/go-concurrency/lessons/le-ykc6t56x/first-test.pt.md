---
title: Um teste é uma função Go que o comando go chama
version: 1
---

As lições 1 a 24 conferiram os seus programas rodando-os e lendo o que imprimiam. Isso funciona
uma vez, enquanto você está olhando, e deixa de funcionar no dia em que outra pessoa muda o código.
**Um teste é uma função que roda o código e confere a resposta sozinha**, então a conferência pode
ser repetida por qualquer pessoa, em qualquer máquina, em um segundo. Go não precisa de framework
para isso: o pacote `testing` e o comando `go test` fazem parte do toolchain que o curso `go`
instalou.

As lições 25 a 30 fazem crescer um pacote pequeno, `example.com/wordcount`, em `~/wordcount`,
criado com `go mod init example.com/wordcount`, e o testam um pouco mais a cada lição. Ele começa
com uma função que lê um texto e conta as palavras, salva como `wordcount.go`:

```go
// Package wordcount counts the words in a text.
package wordcount

import (
	"bufio"
	"io"
	"strings"
)

// Count reads r to the end and returns how many times each word appears,
// compared in lower case.
func Count(r io.Reader) (map[string]int, error) {
	counts := make(map[string]int)
	sc := bufio.NewScanner(r)
	sc.Split(bufio.ScanWords)
	for sc.Scan() {
		counts[strings.ToLower(sc.Text())]++
	}
	return counts, sc.Err()
}
```

Ela recebe um `io.Reader`, a interface da lição 17, então um arquivo, uma resposta de rede e uma
string podem ser contados pelo mesmo código. Um `bufio.Scanner`, da lição 18, dividido por
`bufio.ScanWords` em vez de por linhas, entrega uma palavra de cada vez.

## O primeiro teste

Um teste mora num arquivo cujo nome termina em `_test.go`, no mesmo diretório e no mesmo pacote.
O `go build` ignora esses arquivos e o `go test` os compila junto. **Um teste é qualquer função cujo
nome começa com `Test`, seguido de letra maiúscula, e cujo único parâmetro é um `*testing.T`.** O
primeiro conta uma frase cuja resposta qualquer pessoa confere de olho, salvo como
`wordcount_test.go`:

```go
package wordcount

import (
	"strings"
	"testing"
)

func TestCount(t *testing.T) {
	got, err := Count(strings.NewReader("Go is fun. Go is fast, and go is simple."))
	if err != nil {
		t.Fatalf("Count returned an error: %v", err)
	}
	if got["go"] != 3 {
		t.Errorf(`count of "go" = %d, want 3`, got["go"])
	}
	if got["fun"] != 1 {
		t.Errorf(`count of "fun" = %d, want 1`, got["fun"])
	}
	if got["fast"] != 1 {
		t.Errorf(`count of "fast" = %d, want 1`, got["fast"])
	}
}
```

Não existe `assert`. Uma conferência é um `if` comum, e `t.Errorf` registra uma falha com uma
mensagem que você mesmo escreve. `strings.NewReader` transforma a frase num reader, então o teste
não precisa de arquivo. Rodado do diretório do pacote, o `go test` compila um binário de teste,
roda cada função `Test` que há nele e informa:

```
ana@vm:~/wordcount$ go test
--- FAIL: TestCount (0.00s)
    wordcount_test.go:17: count of "fun" = 0, want 1
    wordcount_test.go:20: count of "fast" = 0, want 1
FAIL
exit status 1
FAIL	example.com/wordcount	0.003s
```

**O primeiro teste achou um defeito numa função que parecia pronta.** A frase diz `fun.` e `fast,`,
e o `ScanWords` divide só nos espaços, então a pontuação ficou grudada nas palavras e o map contou
`fun.` e `fast,` no lugar. `go` passou, porque nenhuma das três ocorrências encostava num ponto ou
numa vírgula. Cada falha dá o arquivo e a linha do `t.Errorf` que a relatou, e a última linha diz
qual pacote falhou. O `go test` saiu com status 1, que é o que um script ou um job de CI confere.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O que go build e go test compilam. go build pega o wordcount.go e deixa o wordcount_test.go de fora. go test pega os dois, acrescenta uma função main gerada pelo pacote testing, compila um binário de teste, roda cada função Test que há nele e transforma os resultados num relatório e num status de saída.\"><defs><marker id=\"l25gotest-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l25gotest-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"200\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o diretório do pacote</text><rect x=\"40\" y=\"62\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">wordcount.go</text><rect x=\"40\" y=\"104\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">wordcount_test.go</text><text x=\"300\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">go build</text><path d=\"M200 70 C 250 50, 300 45, 380 45\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25gotest-phosphor)\"></path><rect x=\"380\" y=\"30\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">compilado, resultado descartado</text><text x=\"300\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">fica de fora</text><path d=\"M205 119 H260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"262\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">go test</text><path d=\"M220 140 C 280 150, 330 185, 378 192\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25gotest-amber)\"></path><rect x=\"20\" y=\"180\" width=\"200\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"120\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um main gerado</text><path d=\"M220 195 C 280 200, 330 205, 378 205\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25gotest-amber)\"></path><rect x=\"380\" y=\"180\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">binário de teste</text><path d=\"M520 200 H555\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l25gotest-amber)\"></path><rect x=\"557\" y=\"160\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"632\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chama cada TestXxx</text><rect x=\"557\" y=\"204\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"632\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PASS ou FAIL, saída 0 ou 1</text><path d=\"M632 194 V204\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path></svg>", "caption": "O go build nunca vê um arquivo _test.go; o go test compila o pacote com os testes num programa próprio e o roda."}
```

## Consertar o código, não o teste

O teste faz a pergunta certa, então quem muda é o código. Cada palavra perde tudo o que não é
letra nem dígito nas pontas antes de ser contada. O arquivo inteiro de novo, como `wordcount.go`:

```go
// Package wordcount counts the words in a text.
package wordcount

import (
	"bufio"
	"io"
	"strings"
	"unicode"
)

// Count reads r to the end and returns how many times each word appears.
// Words are compared in lower case, with the punctuation around them removed.
func Count(r io.Reader) (map[string]int, error) {
	counts := make(map[string]int)
	sc := bufio.NewScanner(r)
	sc.Split(bufio.ScanWords)
	for sc.Scan() {
		w := strings.ToLower(strings.TrimFunc(sc.Text(), notLetter))
		if w != "" {
			counts[w]++
		}
	}
	return counts, sc.Err()
}

func notLetter(r rune) bool { return !unicode.IsLetter(r) && !unicode.IsDigit(r) }
```

`strings.TrimFunc` tira runas das duas pontas enquanto a função disser sim, e deixa o meio em paz.
O `if w != ""` impede que um travessão solto ou uma aspa perdida seja contado como palavra vazia.

```
ana@vm:~/wordcount$ go test
PASS
ok  	example.com/wordcount	0.002s
ana@vm:~/wordcount$ go test -v
=== RUN   TestCount
--- PASS: TestCount (0.00s)
PASS
ok  	example.com/wordcount	0.003s
```

Um pacote que passa imprime uma linha. O `-v` imprime uma linha quando cada teste começa e outra
quando termina, o que vale a pena quando uma execução está lenta e você quer ver onde ela está.

## `Errorf` ou `Fatalf`

Os dois marcam o teste como falho. **`t.Errorf` deixa a função seguir; `t.Fatalf` a para ali
mesmo.** O teste acima usa os dois de propósito. Se `Count` devolvesse um erro, o map ao lado não
valeria a conferência, e mais três falhas sobre ele só enterrariam a que importa, então essa
conferência é `Fatalf`. As três contagens são independentes, e ver as três de uma vez foi o que
deixou a falha acima fácil de ler: duas erradas e uma certa, então o problema era algo que `go` não
tinha.
