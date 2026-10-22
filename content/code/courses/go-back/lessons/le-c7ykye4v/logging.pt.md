---
title: Registrando toda requisição
version: 1
---

O primeiro middleware responde à pergunta com que todo incidente começa: **o que o servidor
recebeu, e o que respondeu?** Uma linha por requisição com o método, o caminho, o status, o
tamanho do corpo e quanto tempo levou. Quatro desses cinco são fáceis, porque a requisição os traz
e um relógio mede o último. O status é o difícil.

## O status não se lê depois

O `ResponseWriter` tem métodos para escrever um status e nenhum para lê-lo de volta. Um middleware
chama `next.ServeHTTP(w, r)`, o handler escreve o que escreve, e quando ele retorna o middleware
não tem como perguntar a `w` o que saiu. **Então o middleware entrega ao handler outro writer**: um
que repassa tudo ao verdadeiro e lembra o que passou.

```schooling-example
{
  "language": "go",
  "file": "boxoffice/middleware.go",
  "parts": [
    {
      "code": "// boxoffice/middleware.go\npackage main\n\nimport (\n\t\"log\"\n\t\"net/http\"\n\t\"slices\"\n\t\"time\"\n)\n\n// chain wraps h in the middlewares given, the first one outermost.\nfunc chain(h http.Handler, mws ...func(http.Handler) http.Handler) http.Handler {\n\tfor _, mw := range slices.Backward(mws) {\n\t\th = mw(h)\n\t}\n\treturn h\n}\n\n",
      "note": "A função auxiliar da seção 02, no arquivo onde ela vai morar."
    },
    {
      "code": "// statusRecorder remembers the status and the size of what a handler wrote.\ntype statusRecorder struct {\n\thttp.ResponseWriter\n\tstatus int\n\tbytes  int\n}\n\n",
      "note": "**Embutir a interface dá ao `statusRecorder` todo método do writer que ele guarda**, o `Header` incluído, sem escrevê-los. Os dois campos são o que ele lembra."
    },
    {
      "code": "func (s *statusRecorder) WriteHeader(code int) {\n\tif s.status == 0 {\n\t\ts.status = code\n\t}\n\ts.ResponseWriter.WriteHeader(code)\n}\n\n",
      "note": "Ele sobrescreve o `WriteHeader`: anota o código e depois repassa a chamada. Só o primeiro código é guardado, porque só o primeiro chega ao cliente, como mostrou a seção 07 da aula 1."
    },
    {
      "code": "func (s *statusRecorder) Write(b []byte) (int, error) {\n\tif s.status == 0 {\n\t\ts.status = http.StatusOK\n\t}\n\tn, err := s.ResponseWriter.Write(b)\n\ts.bytes += n\n\treturn n, err\n}\n\n",
      "note": "E o `Write`: **uma escrita sem status antes dela quer dizer 200**, porque é isso que o writer verdadeiro vai mandar. A contagem de bytes é o que foi de fato escrito, `n`, e não o que foi pedido."
    },
    {
      "code": "// Unwrap lets http.ResponseController reach the writer underneath.\nfunc (s *statusRecorder) Unwrap() http.ResponseWriter {\n\treturn s.ResponseWriter\n}\n\n",
      "note": "**Um envoltório esconde os métodos que o tipo dele não declara.** O writer verdadeiro sabe descarregar para o cliente uma resposta pela metade, e o `statusRecorder` não sabe. `Unwrap` é a convenção que o `http.ResponseController` segue para cavar através dos envoltórios até o writer que sabe; a aula 13 precisa disso."
    },
    {
      "code": "func logRequests(next http.Handler) http.Handler {\n\treturn http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {\n\t\tstart := time.Now()\n\t\trec := &statusRecorder{ResponseWriter: w}\n\t\tnext.ServeHTTP(rec, r)\n\t\tif rec.status == 0 {\n\t\t\trec.status = http.StatusOK\n\t\t}\n\t\tlog.Printf(\"%s %s %d %dB %s\", r.Method, r.URL.Path, rec.status, rec.bytes,\n\t\t\ttime.Since(start).Round(time.Microsecond))\n\t})\n}\n",
      "note": "O middleware em si. O handler de dentro recebe `rec` em vez de `w`, escreve por ele e retorna; a linha é registrada depois. Um handler que não escreve nada recebe um 200 do servidor, então o log diz 200 também."
    }
  ]
}
```

## O que ele imprime

Três requisições contra o boxoffice, e o que o terminal do servidor imprimiu para elas:

```
ana@vm:~/boxoffice$ curl -s localhost:8080/events
1	Jazz at the Docks	120 of 120 seats left
2	Chamber Choir	0 of 80 seats left
ana@vm:~/boxoffice$ curl -s localhost:8080/events/9
no such event
ana@vm:~/boxoffice$ curl -s -X POST localhost:8080/events
Method Not Allowed
```

```
2026/10/16 19:29:24 GET /events 200 77B 25µs
2026/10/16 19:29:24 GET /events/9 404 14B 19µs
2026/10/16 19:29:24 POST /events 405 19B 29µs
```

**O 405 foi escrito pelo mux, não por um handler do boxoffice**, e é registrado do mesmo jeito,
porque o middleware envolve o mux. Durações de vinte e poucos microssegundos são o que custam um
mapa em memória e uma conexão de loopback; elas viram um número que vale acompanhar na aula 6,
quando houver um banco de dados atrás do handler.

## O que fica fora da linha

A linha guarda o caminho e não a query string, e nada dos cabeçalhos. Isso é uma escolha. **Um log
de acesso é lido por mais gente e guardado por mais tempo do que qualquer coisa que ele registra**,
então um token num cabeçalho `Authorization` ou um e-mail numa query string vazaria para ele na
primeira vez em que alguém registrasse "tudo, por garantia". A seção 06 manda um segredo num
cabeçalho em toda requisição da equipe, e nada dele chega a este log. A aula 12 troca o
`log.Printf` por log estruturado e volta à questão do que um log pode guardar.
