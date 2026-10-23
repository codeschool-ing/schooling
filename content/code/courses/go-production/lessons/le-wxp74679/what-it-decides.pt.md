---
title: O que o gofmt decide, e o que ele deixa
version: 1
---

A maioria dos formatadores vem com um arquivo de configuração: tabs ou espaços, largura do recuo,
onde fica a chave, até que comprimento uma linha pode ir. **O `gofmt` não tem ajuste nenhum desses,
e essa é a qualidade dele.** Aqui está cada flag que ele aceita:

```
ana@vm:~/fmt$ gofmt -h
usage: gofmt [flags] [path ...]
  -cpuprofile string
    	write cpu profile to this file
  -d	display diffs instead of rewriting files
  -e	report all errors (not just the first 10 on different lines)
  -l	list files whose formatting differs from gofmt's
  -r string
    	rewrite rule (e.g., 'a[b:len(a)] -> a[b:]')
  -s	simplify code
  -w	write result to (source) file instead of stdout
```

Três dizem para onde vai a saída, uma informa erros, uma faz o profiling do próprio `gofmt`, e duas,
`-s` e `-r`, mudam código em vez de layout. **Nenhuma escolhe um estilo.** Existe um layout só, e todo
programa deste curso está impresso nele, menos o arquivo desarrumado de propósito da seção 02.

## A discussão que ele encerra

Um time com um formatador configurável precisa concordar sobre a configuração, e depois continuar
concordando: o editor de quem chegou agora, com outros ajustes, produz um commit que reformata
arquivos que ninguém queria mudar, e a única linha que importava some dentro de um diff de trezentas.
**Com o `gofmt` não há nada sobre o que concordar**, então uma revisão nunca discute layout e um diff
só mostra linhas cujo significado mudou. Se o layout escolhido é o melhor deixa de importar; o que
importa é que ele é o mesmo em todo lugar, inclusive no código que você está lendo pela primeira vez.

Uma escolha nem cabe ao `gofmt`. **A gramática do Go põe a chave de abertura na mesma linha**, porque
o analisador léxico encerra uma instrução numa quebra de linha depois de um parêntese de fechamento.
Uma chave numa linha só dela é erro de sintaxe, e o `gofmt`, lendo aqui da entrada padrão, se recusa
a imprimi-la:

```
ana@vm:~/fmt$ printf "package p\n\nfunc f()\n{\n}\n" | gofmt
<standard input>:4:1: unexpected semicolon or newline before {
```

## O que ele deixa como está

A impressora trabalha com a árvore sintática mais algumas coisas que guarda do arquivo original, e a
lista do que ela não toca importa tanto quanto a lista do que ela toca. **A primeira é o comprimento
da linha: o `gofmt` nunca quebra uma linha longa.** A linha do `append` que ele produziu na seção 02
continua numa linha só, dois tabs e outros 107 caracteres:

```
ana@vm:~/fmt$ awk 'length > 100 {print NR ": " length " characters"}' internal/tally/classes.go
22: 109 characters
```

O resto da lista é mais curto de dizer:

- Quebras de linha que você escolheu. Quebre uma chamada longa depois de uma vírgula e o `gofmt`
  mantém a quebra e recua a continuação um tab a mais; ele não junta linhas de volta. Onde quebrar
  aquela linha de 109 caracteres, se for o caso, é decisão sua.
- Nomes. `rows`, `n` e `c` ficam como estão. Se um nome é claro, ou se está exportado quando não
  deveria, é pergunta para os linters da lição 8.
- Linhas em branco que você pôs, até uma seguida. As três linhas em branco depois da struct
  viraram uma; uma única linha em branco entre dois grupos de instruções fica onde você a pôs.
- O texto dos comentários. Um comentário é movido e recuado junto com o código, e nunca é
  requebrado nem reescrito.

## `-s`: simplificações que mantêm o significado

O `-s` vai um passo além do layout: ele reescreve algumas construções em outras mais curtas que
querem dizer exatamente o mesmo, todas listadas no `go doc cmd/gofmt`. A que você mais vai encontrar
é um literal composto que repete o tipo dos elementos. Aqui está um teste para `Classes`, escrito do
jeito que muita gente escreve a primeira tabela de structs. `internal/tally/classes_test.go`:

```go
package tally

import (
	"slices"
	"strings"
	"testing"
)

func TestClasses(t *testing.T) {
	log := "2026-10-01T09:00:01Z GET / 200 5ms\n" +
		"2026-10-01T09:00:02Z GET /login 404 7ms\n" +
		"2026-10-01T09:00:03Z POST /login 201 9ms\n" +
		"2026-10-01T09:00:04Z GET /health 503 2ms\n"
	s, err := Count(strings.NewReader(log))
	if err != nil {
		t.Fatal(err)
	}
	want := []Class{
		Class{Name: "2xx", Requests: 2, Share: 0.5},
		Class{Name: "3xx", Requests: 0, Share: 0},
		Class{Name: "4xx", Requests: 1, Share: 0.25},
		Class{Name: "5xx", Requests: 1, Share: 0.25},
	}
	if got := Classes(s); !slices.Equal(got, want) {
		t.Errorf("Classes = %v, want %v", got, want)
	}
}
```

Ele passa, e o `gofmt` puro fica satisfeito com ele. Só o `-s` tem algo a dizer:

```
ana@vm:~/fmt$ go test ./internal/tally
ok  	example.com/hits/internal/tally	0.015s
ana@vm:~/fmt$ gofmt -l .
ana@vm:~/fmt$ gofmt -s -l .
internal/tally/classes_test.go
ana@vm:~/fmt$ gofmt -s -d internal/tally/classes_test.go
diff internal/tally/classes_test.go.orig internal/tally/classes_test.go
--- internal/tally/classes_test.go.orig
+++ internal/tally/classes_test.go
@@ -16,10 +16,10 @@
 		t.Fatal(err)
 	}
 	want := []Class{
-		Class{Name: "2xx", Requests: 2, Share: 0.5},
-		Class{Name: "3xx", Requests: 0, Share: 0},
-		Class{Name: "4xx", Requests: 1, Share: 0.25},
-		Class{Name: "5xx", Requests: 1, Share: 0.25},
+		{Name: "2xx", Requests: 2, Share: 0.5},
+		{Name: "3xx", Requests: 0, Share: 0},
+		{Name: "4xx", Requests: 1, Share: 0.25},
+		{Name: "5xx", Requests: 1, Share: 0.25},
 	}
 	if got := Classes(s); !slices.Equal(got, want) {
 		t.Errorf("Classes = %v, want %v", got, want)
ana@vm:~/fmt$ gofmt -s -w internal/tally/classes_test.go && gofmt -s -l .
```

Dentro de um `[]Class{...}` todo elemento é um `Class`, então o nome do tipo na frente de cada um não
diz nada que o compilador já não saiba. **O `-s` não faz parte do `go fmt`**: a linha do `go fmt -n`
na seção 02 rodou `gofmt -l -w` e nada mais. Um arquivo pode estar formatado corretamente e ainda
assim ser simplificável, e se o seu time quer o `-s`, precisa pedi-lo pelo nome, no ajuste do editor
ou na verificação da seção 05.

## `-r`: uma regra de reescrita sobre a árvore sintática

O `-r` recebe uma regra no formato `padrão -> substituição`, em que os dois lados são expressões Go e
**toda letra minúscula sozinha é um curinga** que casa com qualquer expressão. O `main.go` da lição 1
escreve as mensagens de erro com `fmt.Fprintf(stderr, "hits: %v\n", err)` em quatro lugares. O
`fmt.Fprintln` imprimiria os mesmos bytes com menos para ler, já que põe um espaço entre os operandos
e uma quebra de linha depois do último. Uma regra faz as quatro mudanças:

```
ana@vm:~/fmt$ gofmt -r 'fmt.Fprintf(w, "hits: %v\n", e) -> fmt.Fprintln(w, "hits:", e)' -l .
main.go
ana@vm:~/fmt$ gofmt -r 'fmt.Fprintf(w, "hits: %v\n", e) -> fmt.Fprintln(w, "hits:", e)' -d main.go | grep '^[-+]'
--- main.go.orig
+++ main.go
-			fmt.Fprintf(stderr, "hits: %v\n", err)
+			fmt.Fprintln(stderr, "hits:", err)
-		fmt.Fprintf(stderr, "hits: %v\n", err)
+		fmt.Fprintln(stderr, "hits:", err)
-		fmt.Fprintf(stderr, "hits: %v\n", err)
+		fmt.Fprintln(stderr, "hits:", err)
-		fmt.Fprintf(stderr, "hits: %v\n", err)
+		fmt.Fprintln(stderr, "hits:", err)
```

O `w` casou com `stderr` e o `e` com `err`; a string literal teve de casar exatamente. Rodando com
`-d`, nada foi gravado, e esta lição deixa o `main.go` como a lição 1 o imprimiu.

**A regra casa sintaxe e não sabe nada de tipos**, e esse é o limite dela. Suponha que você decida
que o campo `Duration` de `tally.Entry` deveria se chamar `Took`, e tente a regra óbvia:

```
ana@vm:~/fmt$ gofmt -r 'a.Duration -> a.Took' -d internal/tally/tally.go | grep '^[-+]'
--- internal/tally/tally.go.orig
+++ internal/tally/tally.go
-	Duration time.Duration
+	Duration time.Took
-	Total    time.Duration
+	Total    time.Took
-		s.Total += e.Duration
+		s.Total += e.Took
```

O `a` casou com `time` com a mesma facilidade com que casou com `e`, então a regra renomeou um tipo
da biblioteca padrão que não existe com esse nome, e deixou o próprio campo, que é declarado sem
ponto, como `Duration`. O resultado não compila. **O `-r` serve para uma mudança mecânica na forma de
uma expressão; renomear exige uma ferramenta que saiba a que cada nome se refere**, que é a operação
de renomear do `gopls`, o servidor de linguagem que a seção 04 apresenta.
