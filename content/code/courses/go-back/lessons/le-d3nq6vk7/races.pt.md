---
title: Testes que rodam ao mesmo tempo que o código
version: 1
---

Um servidor atende requisições de forma concorrente, então um teste que envia uma requisição por vez deixa
sem teste a parte mais perigosa. Este cria um evento com dez lugares e põe cinquenta compradores tentando
um lugar cada, todos de uma vez, pelo roteador inteiro:

```go
// boxoffice/concurrency_test.go
package main

import (
	"net/http"
	"strings"
	"sync"
	"testing"
)

// Fifty buyers want one seat each of an event with ten left. Ten get one.
func TestConcurrentPurchases(t *testing.T) {
	srv := newTestServer(t)
	body := `{"name": "Small Room", "seats": 10}`
	req, _ := http.NewRequest("POST", srv.URL+"/admin/events", strings.NewReader(body))
	req.Header.Set("Authorization", "Bearer "+managerToken)
	resp, err := srv.Client().Do(req)
	if err != nil || resp.StatusCode != http.StatusCreated {
		t.Fatalf("creating the event: %v %v", resp, err)
	}
	resp.Body.Close()

	var wg sync.WaitGroup
	sold := 0
	for range 50 {
		wg.Go(func() {
			resp, err := srv.Client().Post(srv.URL+"/events/3/tickets", "application/json",
				strings.NewReader(`{"quantity": 1, "email": "fan@example.com"}`))
			if err != nil {
				t.Error(err)
				return
			}
			resp.Body.Close()
			if resp.StatusCode == http.StatusCreated {
				sold++
			}
		})
	}
	wg.Wait()
	if sold != 10 {
		t.Errorf("%d tickets sold, want 10", sold)
	}
}
```

O `wg.Go`, do go-concurrency, inicia cada comprador numa goroutine e o conta no `WaitGroup`. O evento é o
número 3 porque o `newMemStore` já tem dois. Rodando normalmente, ele passa:

```
ana@vm:~/boxoffice$ go test -run TestConcurrentPurchases .
ok  	example.com/boxoffice	(cached)
```

**E está errado.** Rode o mesmo teste com o detector de corrida:

```
ana@vm:~/boxoffice$ go test -race -run TestConcurrentPurchases .
==================
WARNING: DATA RACE
Read at 0x00c0000192a8 by goroutine 21:
  example.com/boxoffice.TestConcurrentPurchases.func1()
      /home/ana/boxoffice/concurrency_test.go:35 +0x27a

Previous write at 0x00c0000192a8 by goroutine 20:
  example.com/boxoffice.TestConcurrentPurchases.func1()
      /home/ana/boxoffice/concurrency_test.go:35 +0x28f

Goroutine 21 (running) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72
  testing.tRunner()
      /usr/local/go/src/testing/testing.go:2193 +0x21c
  testing.(*T).Run.gowrap1()
      /usr/local/go/src/testing/testing.go:2258 +0x38

Goroutine 20 (finished) created at:
  sync.(*WaitGroup).Go()
      /usr/local/go/src/sync/waitgroup.go:238 +0x72
  testing.tRunner()
      /usr/local/go/src/testing/testing.go:2193 +0x21c
  testing.(*T).Run.gowrap1()
      /usr/local/go/src/testing/testing.go:2258 +0x38
==================
--- FAIL: TestConcurrentPurchases (0.03s)
    testing.go:1865: race detected during execution of test
FAIL
FAIL	example.com/boxoffice	0.041s
FAIL
```

O detector observou todo acesso à memória enquanto o teste rodava e encontrou duas goroutines mexendo na
mesma variável sem nada que as ordenasse. O relatório aponta **a linha, `concurrency_test.go:35`, que é o
`sold++`**: cinquenta goroutines incrementando um inteiro. Um incremento é uma leitura e uma escrita, e duas
goroutines podem ler 7 e escrever 8. A primeira execução passou porque, daquela vez, isso não aconteceu;
numa máquina mais ocupada a contagem sairia 9 de vez em quando, e o teste falharia uma vez por semana sem
nada que explicasse.

O defeito está no teste, não no boxoffice: o `memStore` segura o seu mutex, e o servidor vendeu exatamente
dez. **O código do próprio teste também roda de forma concorrente, e ele segue as mesmas regras do código
que testa.** A correção é um `atomic.Int64`, cujo `Add` é um passo indivisível:

```go
// boxoffice/concurrency_test.go
package main

import (
	"net/http"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
)

// Fifty buyers want one seat each of an event with ten left. Ten get one.
func TestConcurrentPurchases(t *testing.T) {
	srv := newTestServer(t)
	body := `{"name": "Small Room", "seats": 10}`
	req, _ := http.NewRequest("POST", srv.URL+"/admin/events", strings.NewReader(body))
	req.Header.Set("Authorization", "Bearer "+managerToken)
	resp, err := srv.Client().Do(req)
	if err != nil || resp.StatusCode != http.StatusCreated {
		t.Fatalf("creating the event: %v %v", resp, err)
	}
	resp.Body.Close()

	var wg sync.WaitGroup
	var sold atomic.Int64
	for range 50 {
		wg.Go(func() {
			resp, err := srv.Client().Post(srv.URL+"/events/3/tickets", "application/json",
				strings.NewReader(`{"quantity": 1, "email": "fan@example.com"}`))
			if err != nil {
				t.Error(err)
				return
			}
			resp.Body.Close()
			if resp.StatusCode == http.StatusCreated {
				sold.Add(1)
			}
		})
	}
	wg.Wait()
	if n := sold.Load(); n != 10 {
		t.Errorf("%d tickets sold, want 10", n)
	}
}
```

```
ana@vm:~/boxoffice$ go test -race -run TestConcurrentPurchases .
ok  	example.com/boxoffice	(cached)
```

O detector de corrida precisa do cgo, e é por isso que a aula 1 conferiu o gcc. Ele só vê corridas que
acontecem enquanto observa, então não encontra nada em código que nenhum teste roda de forma concorrente;
este teste existe para fazer o caso concorrente acontecer. A seção 08 mede quanto custa deixá-lo ligado.
