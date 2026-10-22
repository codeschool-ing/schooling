---
title: Que linhas os testes rodaram
version: 1
---

Depois de cinco lições de testes, uma pergunta justa é o que eles deixam de fora. **Cobertura é a
parcela das instruções do código que rodou pelo menos uma vez enquanto os testes rodavam**, e o
`go test` a mede com uma flag. O compilador reescreve o pacote com um contador em cada bloco de
instruções, roda os testes e informa quais contadores se mexeram.

## O número, depois o mapa

```
ana@vm:~/wordcount$ go test -cover
PASS
coverage: 93.4% of statements
ok  	example.com/wordcount	0.067s
```

Um número para o pacote inteiro. Ele diz quanto, não onde, e o onde é aquilo sobre o que uma pessoa
pode agir. O `-coverprofile` escreve os contadores num arquivo, e o `go tool cover` o lê, aqui uma
linha por função:

```
ana@vm:~/wordcount$ go test -coverprofile=c.out
PASS
coverage: 93.4% of statements
ok  	example.com/wordcount	0.062s
ana@vm:~/wordcount$ go tool cover -func=c.out
example.com/wordcount/file.go:6:	CountFile	100.0%
example.com/wordcount/fssource.go:14:	Open		100.0%
example.com/wordcount/handler.go:13:	Handler		86.7%
example.com/wordcount/httpsource.go:18:	Open		91.7%
example.com/wordcount/source.go:16:	TopOf		87.5%
example.com/wordcount/top.go:17:	Top		100.0%
example.com/wordcount/wordcount.go:13:	Count		100.0%
example.com/wordcount/wordcount.go:26:	notLetter	100.0%
total:					(statements)	93.4%
```

Cinco funções rodaram todas as instruções. Três não, e cada instrução que falta é um caminho sobre o
qual ninguém perguntou. `go tool cover -html=c.out -o cover.html` escreve o mesmo perfil como uma
página, o código de cada arquivo pintado de verde onde rodou e de vermelho onde não rodou. Abra-a
num navegador, e as linhas vermelhas são estas três:

- O `500` do `Handler`: nenhum teste fez o `TopOf` falhar com outra coisa que não um documento que
  falta.
- O `count %s: %w` do `TopOf`: nenhuma fonte entregou um documento que falhasse durante a leitura.
- A conferência depois do `http.NewRequestWithContext` no `HTTPSource.Open`: nenhum teste lhe deu
  uma URL base tão quebrada que nem uma requisição pudesse ser montada.

## Fechando a lacuna que importa

As duas primeiras são uma lacuna só: um documento que falha no meio. Um disco pode fazer isso, e uma
rede também, e nada testou o que o pacote diz quando acontece. A biblioteca padrão tem a ferramenta
para isso em `testing/iotest`, cujo `ErrReader` devolve um erro na primeira leitura. Um `Source` que
entrega um desses, e um teste pelo `Handler`, salvos como `readfail_test.go`:

```go
package wordcount

import (
	"context"
	"errors"
	"io"
	"net/http/httptest"
	"testing"
	"testing/iotest"
)

// brokenSource hands over documents that fail on their first read.
type brokenSource struct{}

func (brokenSource) Open(ctx context.Context, name string) (io.ReadCloser, error) {
	return io.NopCloser(iotest.ErrReader(errors.New("disk read failed"))), nil
}

func TestHandlerReadFails(t *testing.T) {
	rec := httptest.NewRecorder()
	Handler(brokenSource{}).ServeHTTP(rec, httptest.NewRequest("GET", "/top?doc=note&n=2", nil))
	if res := rec.Result(); res.StatusCode != 500 {
		t.Errorf("status %d, want 500", res.StatusCode)
	}
}
```

```
ana@vm:~/wordcount$ go test -coverprofile=c.out
PASS
coverage: 98.4% of statements
ok  	example.com/wordcount	0.061s
ana@vm:~/wordcount$ go tool cover -func=c.out
example.com/wordcount/file.go:6:	CountFile	100.0%
example.com/wordcount/fssource.go:14:	Open		100.0%
example.com/wordcount/handler.go:13:	Handler		100.0%
example.com/wordcount/httpsource.go:18:	Open		91.7%
example.com/wordcount/source.go:16:	TopOf		100.0%
example.com/wordcount/top.go:17:	Top		100.0%
example.com/wordcount/wordcount.go:13:	Count		100.0%
example.com/wordcount/wordcount.go:26:	notLetter	100.0%
total:					(statements)	98.4%
```

O `Handler` e o `TopOf` alcançaram todas as instruções, e o teste perguntou algo real: que uma falha
no meio de um documento sai como um 500, e não como uma resposta contada pela metade.

**A terceira lacuna fica aberta, de propósito.** Alcançá-la exige uma URL base que o `net/http` se
recuse a interpretar, um erro de configuração que falharia na primeira requisição de qualquer
pessoa, em voz alta. Um teste para isso exercitaria mais o parser do `net/http` do que este pacote.
O número fica abaixo de 100 e o motivo está escrito aqui. É para isso que a cobertura serve:
**um mapa do que ninguém perguntou ainda, lido por uma pessoa que decide, e não uma meta.** Um time
que põe uma porcentagem como objetivo ganha testes escritos para mexer na porcentagem, e a próxima
seção mostra o que eles podem deixar passar.
