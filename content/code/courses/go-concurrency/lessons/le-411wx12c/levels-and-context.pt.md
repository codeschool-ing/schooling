---
title: Níveis que mudam, e o contexto que viaja
version: 1
---

Duas necessidades chegam com o primeiro incidente em produção. Alguém quer os registros `DEBUG`
agora, sem um reinício que faria o problema sumir. E alguém quer que todo registro sobre uma
requisição leve o id dela, vindo de código que nunca recebeu um logger com ele. **Um
`slog.LevelVar` responde à primeira, e um handler que lê o `context.Context` responde à segunda**:
o mesmo contexto que as lições 10 e 11 passam por toda chamada. Salvo como `levels/main.go`:

```schooling-example
{"language": "go", "file": "levels/main.go", "parts": [{"code": "// Command levels changes what is logged while the program runs, and takes\n// a request id from the context.\npackage main\n\nimport (\n\t\"context\"\n\t\"log/slog\"\n\t\"os\"\n)\n\nfunc noTime(groups []string, a slog.Attr) slog.Attr {\n\tif a.Key == slog.TimeKey && len(groups) == 0 {\n\t\treturn slog.Attr{}\n\t}\n\treturn a\n}\n\n", "note": "O mesmo `noTime` de antes."}, {"code": "type ctxKey struct{}\n\n", "note": "Um tipo de chave próprio, como a lição 10 recomenda para valores de contexto, para nenhum outro pacote colidir com ele."}, {"code": "// withRequest adds the request id it finds in the context to every record.\ntype withRequest struct{ slog.Handler }\n\nfunc (h withRequest) Handle(ctx context.Context, r slog.Record) error {\n\tif id, ok := ctx.Value(ctxKey{}).(string); ok {\n\t\tr.AddAttrs(slog.String(\"request_id\", id))\n\t}\n\treturn h.Handler.Handle(ctx, r)\n}\n\n", "note": "**O `withRequest` embute um `slog.Handler` e substitui só o `Handle`.** Antes de repassar o registro, ele procura um id de requisição no contexto e, quando há um, o acrescenta como atributo."}, {"code": "func main() {\n\tvar level slog.LevelVar // Info, its zero value\n\tbase := slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: &level, ReplaceAttr: noTime})\n\tlog := slog.New(withRequest{base})\n\n", "note": "**O nível é um `LevelVar`, uma variável que o handler lê em todo registro**, e não um valor copiado quando o handler foi criado. O valor zero dele é `INFO`."}, {"code": "\tctx := context.WithValue(context.Background(), ctxKey{}, \"r-81f3\")\n\tlog.DebugContext(ctx, \"query plan\", \"rows\", 3)\n\tlog.InfoContext(ctx, \"order placed\", \"order\", 1042)\n\n", "note": "`DebugContext` e `InfoContext` são as chamadas de log que levam um contexto até o handler. Em `INFO`, o registro de debug é descartado."}, {"code": "\tlevel.Set(slog.LevelDebug)\n\tlog.DebugContext(ctx, \"query plan\", \"rows\", 3)\n\tlog.Info(\"no context, no request id\")\n}\n", "note": "`level.Set` baixa o nível com o programa rodando, e o próximo registro de debug é escrito. `log.Info`, sem contexto, chega ao handler com um contexto vazio, então não ganha id de requisição."}]}
```

```
ana@vm:~/logs$ go run ./levels
level=INFO msg="order placed" order=1042 request_id=r-81f3
level=DEBUG msg="query plan" rows=3 request_id=r-81f3
level=INFO msg="no context, no request id"
```

Três registros de quatro chamadas. O primeiro `query plan` estava abaixo do nível e sumiu; o
segundo, depois do `level.Set`, foi escrito. `request_id=r-81f3` foi acrescentado pelo handler às
duas chamadas que levavam o contexto, e falta na que não levava.

## De onde um `LevelVar` é mudado

Num serviço de verdade, a chamada `level.Set` fica atrás de algo que um operador alcança: um sinal,
uma flag lida na partida como mostrou a lição 21, ou um endpoint administrativo. **Todo handler
criado com o mesmo `LevelVar` o segue na hora**, e nada precisa reiniciar, que é a questão: o
problema ainda está acontecendo enquanto você olha.

Ligar o `DEBUG` em produção é um custo além de uma ajuda. Registros são gravados num disco ou
enviados por uma rede, e um caminho quente que registra uma linha de debug por requisição pode
multiplicar o volume por cem. Ligue pelo tempo que precisar, e volte.

## Por que o contexto, e não um logger no contexto

Uma alternativa tentadora é pôr um logger inteiro dentro do contexto e buscá-lo em todo lugar. O
handler acima mantém o logger onde foi construído e põe no contexto só o id da requisição, que toda
função da chamada já recebe como primeiro argumento. **O valor viaja com a requisição; a decisão de
como escrevê-lo fica num lugar só.** Uma função que registra com `InfoContext(ctx, …)` não precisa
saber nada de ids de requisição, e um id acrescentado ao contexto onde a requisição chega, num
handler HTTP como o da lição 12, alcança todo registro abaixo dele.
