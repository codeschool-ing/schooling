---
title: Atributos, grupos e segredos
version: 1
---

Os valores de um registro são os seus atributos, e a maioria se repete. Toda linha sobre uma
requisição deveria levar o id dela, e passá-lo em toda chamada é como um acaba esquecido. **O
`Logger.With` devolve um logger novo que acrescenta os seus atributos a todo registro que
escreve.** O programa abaixo o usa, agrupa dois valores sob um nome e mantém uma credencial fora do
log, salvo como `attrs/main.go`:

```schooling-example
{"language": "go", "file": "attrs/main.go", "parts": [{"code": "// Command attrs attaches context to a logger and keeps a secret out of it.\npackage main\n\nimport (\n\t\"log/slog\"\n\t\"os\"\n)\n\nfunc noTime(groups []string, a slog.Attr) slog.Attr {\n\tif a.Key == slog.TimeKey && len(groups) == 0 {\n\t\treturn slog.Attr{}\n\t}\n\treturn a\n}\n\n", "note": "O mesmo `noTime` do programa da seção anterior, para a saída não depender de quando ele rodou."}, {"code": "// Token is a credential. Its LogValue is what any handler records.\ntype Token string\n\nfunc (Token) LogValue() slog.Value { return slog.StringValue(\"REDACTED\") }\n\n", "note": "**Um tipo com um método `LogValue` decide como é registrado**, seja qual for o handler que o escreve. O `Token` responde `REDACTED`, então a credencial não chega a um log por acidente."}, {"code": "func main() {\n\tlog := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{ReplaceAttr: noTime}))\n\n", "note": "Um handler JSON para o programa inteiro."}, {"code": "\treq := log.With(\"request_id\", \"r-81f3\", \"user\", 7)\n\treq.Info(\"order placed\", slog.Int(\"order\", 1042))\n", "note": "`log.With` devolve um logger novo; o próprio `log` não muda. `slog.Int` monta um atributo com o tipo declarado, o mesmo que o par `\"order\", 1042`, escrito de um jeito que um erro de digitação não desequilibra os pares."}, {"code": "\treq.Info(\"shipping\", slog.Group(\"address\", \"city\", \"Recife\", \"zip\", \"50000-000\"))\n\n", "note": "`slog.Group` aninha atributos sob uma chave, que o JSON escreve como um objeto dentro do objeto."}, {"code": "\treq.Info(\"charging card\", \"token\", Token(\"tok_live_4f9a\"))\n", "note": "O token é passado como está. O `LogValue` dele roda dentro do handler."}, {"code": "\treq.Info(\"odd number of arguments\", \"order\")\n}\n", "note": "**Um argumento a menos**: `\"order\"` não tem valor depois dele."}]}
```

```
ana@vm:~/logs$ go run ./attrs
{"level":"INFO","msg":"order placed","request_id":"r-81f3","user":7,"order":1042}
{"level":"INFO","msg":"shipping","request_id":"r-81f3","user":7,"address":{"city":"Recife","zip":"50000-000"}}
{"level":"INFO","msg":"charging card","request_id":"r-81f3","user":7,"token":"REDACTED"}
{"level":"INFO","msg":"odd number of arguments","request_id":"r-81f3","user":7,"!BADKEY":"order"}
```

Os dois primeiros atributos de toda linha são `request_id` e `user`, escritos uma vez no `With`. O
endereço chegou como objeto, `"address":{"city":"Recife",…}`, e o token como `REDACTED`. **A última
linha é o erro à vista**: com um número ímpar de argumentos, o `slog` não tem como saber que a
string sozinha era uma chave, então a registra sob `!BADKEY`. O registro é escrito mesmo assim,
porque uma chamada de log que falhasse esconderia justamente a linha de que alguém precisa. O
`go vet` pega o erro antes de rodar:

```
ana@vm:~/logs$ go vet ./attrs; echo $?
attrs/main.go:29:2: call to slog.Logger.Info missing a final value
1
```

**O `go vet` confere os pares de toda chamada de `slog` que consegue ver**, e sai com o status 1. É
o mais barato dos hábitos que esta lição recomenda: rode-o antes de todo commit, como disse a lição
4 de `go`.

## O que não pôr num atributo

Um log é lido por mais gente, e guardado por mais tempo, do que os dados que ele descreve. Uma
senha, um token, um número de cartão ou o endereço completo de uma pessoa numa linha de log são
esses dados copiados para um lugar com menos proteção. O `LogValue` no tipo é a defesa que não
depende de todo mundo lembrar: o tipo que guarda um segredo diz uma vez como é registrado. Recife e
o CEP do programa acima são exemplo de um valor que é pessoal e mesmo assim vai parar em logs todo
dia; se deveria ir é uma decisão do time dono dos dados, tomada antes da primeira linha escrita.
