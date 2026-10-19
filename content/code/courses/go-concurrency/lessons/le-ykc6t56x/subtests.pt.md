---
title: Subtestes com `t.Run`
version: 1
---

Uma função de teste que confere uma frase diz pouco sobre as bordas: letras maiúsculas, acentos,
um texto vazio. Escrever `TestCountCase`, `TestCountAccents` e assim por diante funciona, e dá a
cada um um nome na saída, mas os nomes ficam colados à função e nada os agrupa. **`t.Run` inicia
um subteste: um teste com nome dentro de um teste, com o seu próprio `*testing.T`, o seu próprio
passou ou falhou e a sua própria linha no relatório.**

O arquivo de teste, reescrito como cinco subtestes de `TestCount`, salvo como `wordcount_test.go`:

```go
package wordcount

import (
	"strings"
	"testing"
)

func TestCount(t *testing.T) {
	t.Run("punctuation", func(t *testing.T) {
		got, err := Count(strings.NewReader("Go is fun. Go is fast, and go is simple."))
		if err != nil {
			t.Fatalf("Count returned an error: %v", err)
		}
		if got["fun"] != 1 || got["fast"] != 1 {
			t.Errorf(`counts of "fun", "fast" = %d, %d, want 1, 1`, got["fun"], got["fast"])
		}
	})
	t.Run("case", func(t *testing.T) {
		got, err := Count(strings.NewReader("Go GO go gO"))
		if err != nil {
			t.Fatalf("Count returned an error: %v", err)
		}
		if got["go"] != 4 {
			t.Errorf(`count of "go" = %d, want 4`, got["go"])
		}
	})
	t.Run("accents", func(t *testing.T) {
		got, err := Count(strings.NewReader("Ação, ação e AÇÃO."))
		if err != nil {
			t.Fatalf("Count returned an error: %v", err)
		}
		if got["ação"] != 3 {
			t.Errorf(`count of "ação" = %d, want 3`, got["ação"])
		}
	})
	t.Run("possessive", func(t *testing.T) {
		got, err := Count(strings.NewReader("Go and Go's tools"))
		if err != nil {
			t.Fatalf("Count returned an error: %v", err)
		}
		if got["go"] != 2 {
			t.Errorf(`count of "go" = %d, want 2`, got["go"])
		}
	})
	t.Run("empty", func(t *testing.T) {
		got, err := Count(strings.NewReader(""))
		if err != nil || len(got) != 0 {
			t.Errorf(`Count("") = %v, %v; want an empty map and no error`, got, err)
		}
	})
}
```

Cada subteste recebe um `t` novo, que esconde o de fora, e toda conferência dentro dele usa esse.
É isso que mantém uma falha dentro do subteste que a encontrou:

```
ana@vm:~/wordcount$ go test -v
=== RUN   TestCount
=== RUN   TestCount/punctuation
=== RUN   TestCount/case
=== RUN   TestCount/accents
=== RUN   TestCount/possessive
    wordcount_test.go:42: count of "go" = 1, want 2
=== RUN   TestCount/empty
--- FAIL: TestCount (0.00s)
    --- PASS: TestCount/punctuation (0.00s)
    --- PASS: TestCount/case (0.00s)
    --- PASS: TestCount/accents (0.00s)
    --- FAIL: TestCount/possessive (0.00s)
    --- PASS: TestCount/empty (0.00s)
FAIL
exit status 1
FAIL	example.com/wordcount	0.002s
```

**O nome de um subteste é o nome do pai, uma barra e a string passada a `t.Run`.** Quatro passaram
e um falhou, e o pai falhou porque um dos filhos falhou. A falha não impediu `empty` de rodar: um
subteste que chama `t.Fatalf` encerra aquele subteste e mais nada.

## Rodando um deles

O `-run` recebe uma expressão regular e roda só os testes cujo nome casa com ela. Com uma barra, cada
parte é comparada com um nível do nome, então um subteste sozinho pode rodar enquanto você trabalha
nele:

```
ana@vm:~/wordcount$ go test -v -run 'TestCount/possessive'
=== RUN   TestCount
=== RUN   TestCount/possessive
    wordcount_test.go:42: count of "go" = 1, want 2
--- FAIL: TestCount (0.00s)
    --- FAIL: TestCount/possessive (0.00s)
FAIL
exit status 1
FAIL	example.com/wordcount	0.002s
ana@vm:~/wordcount$ go test -run 'Count/^(case|accents)$'
PASS
ok  	example.com/wordcount	0.009s
```

O segundo padrão rodou dois subtestes por uma expressão, e não por um nome completo. O `^` e o `$`
fazem cada um casar com o nome inteiro, então `case` não pega também um futuro `lowercase`.

## Uma falha que é uma pergunta

O subteste `possessive` falhou porque `Go's` virou a palavra `go's`: o apóstrofo fica dentro da
palavra, e o `TrimFunc` só apara as pontas. Se isso é defeito depende de para que serve o pacote, e
**o código não pode decidir isso; alguém tem de decidir**. `don't` e `it's` são palavras por
direito próprio, e cortar em todo apóstrofo as transformaria em `don` e `t`. Este curso mantém o
apóstrofo de dentro e conta `go's` como palavra própria, então muda a expectativa, e não o código. A
seção 04 mostra o teste como ele termina esta lição, com essa decisão escrita nele.
