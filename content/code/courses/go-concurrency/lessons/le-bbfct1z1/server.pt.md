---
title: Um servidor de verdade para um cliente chamar
version: 1
---

A lição 27 prometeu um `Source` que busca documentos via HTTP, testado contra a coisa real. A coisa
real não precisa ser o servidor de produção de alguém. **`httptest.NewServer` inicia um servidor
HTTP de verdade, numa porta livre de `127.0.0.1`, servindo o handler que você lhe der**, e devolve
o endereço dele. O cliente testado não consegue distingui-lo de outro servidor qualquer, porque ele
não é diferente de outro servidor qualquer.

## O cliente

O `HTTPSource` transforma `Open(ctx, "a.txt")` em `GET <BaseURL>/a.txt`, salvo como
`httpsource.go`:

```go
package wordcount

import (
	"context"
	"fmt"
	"io"
	"io/fs"
	"net/http"
)

// HTTPSource fetches documents from a server: Open(ctx, "a.txt") is
// GET BaseURL/a.txt.
type HTTPSource struct {
	BaseURL string
	Client  *http.Client
}

func (s HTTPSource) Open(ctx context.Context, name string) (io.ReadCloser, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, s.BaseURL+"/"+name, nil)
	if err != nil {
		return nil, err
	}
	resp, err := s.Client.Do(req)
	if err != nil {
		return nil, err
	}
	switch resp.StatusCode {
	case http.StatusOK:
		return resp.Body, nil
	case http.StatusNotFound:
		resp.Body.Close()
		return nil, fs.ErrNotExist
	default:
		resp.Body.Close()
		return nil, fmt.Errorf("GET %s: %s", req.URL, resp.Status)
	}
}
```

O corpo é o documento, então um 200 o entrega sem ler e o `defer` de `TopOf` o fecha. Todo outro
status fecha o corpo aqui, porque ninguém mais vai fechá-lo. Um 404 vira `fs.ErrNotExist`, o mesmo
erro que o `FSSource` dá, então quem chama trata um documento que falta do mesmo jeito onde quer que
ele more, e o `Handler` da seção 02 o transforma num 404 dele.

## O teste

O servidor serve arquivos de um `fstest.MapFS`, por meio do `http.FileServerFS`, o servidor de
arquivos da biblioteca padrão. Um segundo teste usa um handler que falha em toda requisição. Salvo
como `httpsource_test.go`:

```go
package wordcount

import (
	"errors"
	"io/fs"
	"net/http"
	"net/http/httptest"
	"slices"
	"strings"
	"testing"
	"testing/fstest"
)

func TestHTTPSource(t *testing.T) {
	srv := httptest.NewServer(http.FileServerFS(fstest.MapFS{
		"a.txt": {Data: []byte("go go stop")},
	}))
	defer srv.Close()
	t.Logf("serving on %s", srv.URL)
	src := HTTPSource{BaseURL: srv.URL, Client: srv.Client()}

	got, err := TopOf(t.Context(), src, "a.txt", 1)
	if err != nil {
		t.Fatalf("TopOf: %v", err)
	}
	if want := []Entry{{"go", 2}}; !slices.Equal(got, want) {
		t.Errorf("TopOf(a.txt, 1) = %v, want %v", got, want)
	}
	if _, err := TopOf(t.Context(), src, "b.txt", 1); !errors.Is(err, fs.ErrNotExist) {
		t.Errorf("missing document: err = %v, want fs.ErrNotExist", err)
	}
}

func TestHTTPSourceServerError(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "out of order", http.StatusInternalServerError)
	}))
	defer srv.Close()
	src := HTTPSource{BaseURL: srv.URL, Client: srv.Client()}

	_, err := TopOf(t.Context(), src, "a.txt", 1)
	if err == nil || !strings.Contains(err.Error(), "500 Internal Server Error") {
		t.Errorf("err = %v, want one naming the 500", err)
	}
}
```

```
ana@vm:~/wordcount$ go test -v -run HTTPSource
=== RUN   TestHTTPSource
    httpsource_test.go:19: serving on http://127.0.0.1:40299
--- PASS: TestHTTPSource (0.01s)
=== RUN   TestHTTPSourceServerError
--- PASS: TestHTTPSourceServerError (0.00s)
PASS
ok  	example.com/wordcount	0.015s
```

Uma porta real na interface de loopback, uma requisição real e uma resposta real, em poucos
milissegundos. O `defer srv.Close()` desliga o servidor quando o teste retorna. O `srv.Client()` é
um cliente preparado para aquele servidor; para um `NewServer` simples é um cliente comum, e para o
`NewTLSServer`, a variante HTTPS, é um que confia no certificado do servidor de teste.

## Onde cada ferramenta serve

O recorder da seção 02 e o servidor daqui respondem a perguntas diferentes, e **o lado da conversa
que você está testando decide qual usar**:

| você está testando | use | porque |
|---|---|---|
| um handler: o que ele responde | `httptest.NewRecorder` | sem porta, sem goroutine, a resposta é um valor a inspecionar |
| um cliente: o que ele faz com as respostas | `httptest.NewServer` | o cliente precisa de um endereço real para se conectar |
| os dois juntos, de ponta a ponta | `httptest.NewServer(Handler(...))` | roteamento, cabeçalhos e o fio, tudo em jogo |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Dois testes, um para cada lado de uma conversa HTTP. Testando o handler: o teste monta uma requisição com httptest.NewRequest, chama ServeHTTP diretamente e lê a resposta de um recorder; nenhuma rede entra. Testando o cliente: o teste inicia httptest.NewServer em 127.0.0.1, e o HTTPSource manda uma requisição real pela rede de loopback e lê uma resposta real.\"><defs><marker id=\"l28two-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l28two-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"240\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">testando o handler</text><rect x=\"370\" y=\"20\" width=\"330\" height=\"240\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">testando o cliente</text><rect x=\"40\" y=\"64\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o teste</text><rect x=\"200\" y=\"64\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Handler(src)</text><path d=\"M160 81 H198\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28two-amber)\"></path><text x=\"180\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">ServeHTTP(rec, req)</text><rect x=\"40\" y=\"170\" width=\"290\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">httptest.NewRecorder → Result()</text><path d=\"M265 98 V168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28two-phosphor)\"></path><path d=\"M100 168 V100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28two-phosphor)\"></path><text x=\"185\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma chamada de método, sem rede</text><rect x=\"390\" y=\"64\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">HTTPSource</text><rect x=\"550\" y=\"64\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">httptest.NewServer</text><rect x=\"550\" y=\"170\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">127.0.0.1:port</text><path d=\"M455 98 C 455 160, 500 187, 548 187\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28two-phosphor)\"></path><text x=\"510\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">GET /a.txt</text><path d=\"M625 168 V100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28two-phosphor)\"></path><path d=\"M548 72 H522\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l28two-amber)\"></path><text x=\"536\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">200</text><text x=\"535\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma conexão real no loopback</text></svg>", "caption": "O lado que você testa decide a ferramenta: um handler é chamado diretamente; um cliente precisa de alguém a quem se conectar."}
```

Nenhum dos dois substitui um teste contra o serviço real numa etapa posterior, mais lenta. O que
eles dão é um teste rápido da sua metade da conversa, rodado a cada mudança.
