---
title: O que escrever você mesmo custou de fato
version: 1
---

O jeito justo de pesar um framework é contra o código que você escreve no lugar dele, e o
boxoffice tem esse código. As aulas 1 a 3 escreveram cada peça de encanamento que um framework
teria fornecido, e ela pode ser contada:

```
ana@vm:~/boxoffice$ wc -l middleware.go recover.go cors.go auth.go json.go decode.go problem.go
  58 middleware.go
  25 recover.go
  30 cors.go
  41 auth.go
  25 json.go
  48 decode.go
  42 problem.go
 269 total
ana@vm:~/boxoffice$ wc -l store.go events.go admin.go routes.go main.go
  81 store.go
 107 events.go
  65 admin.go
  18 routes.go
  34 main.go
 305 total
```

O primeiro comando conta o encanamento, os arquivos que existiriam em qualquer serviço HTTP e não
dizem nada sobre ingressos: a cadeia de middlewares e o gravador de status, a recuperação de
pânico, o CORS, a autenticação por token, escrever JSON, ler JSON, e o formato de problema com a
tradução de erros. **269 linhas, comentários e linhas em branco incluídos.** O segundo conta aquilo
de que o boxoffice trata, o store, os handlers e as rotas: 305.

## O que são as 269 linhas

| arquivo | linhas | o que um framework oferece no lugar |
|---|---|---|
| `middleware.go` | 58 | um middleware de log, e a própria cadeia |
| `recover.go` | 25 | um middleware de recuperação |
| `cors.go` | 30 | um middleware de CORS com uma struct de configuração |
| `auth.go` | 41 | um middleware de autenticação basic ou bearer, ou nada, porque a autenticação em geral é sua mesmo |
| `json.go` | 25 | `c.JSON` |
| `decode.go` | 48 | `c.Bind` ou `ShouldBindJSON`, com menos rigor por padrão |
| `problem.go` | 42 | um tratador de erros central, no formato dele |

**Cada uma dessas linhas é código que você lê, entende e muda no mesmo editor que o resto do
serviço.** Quando o decodificador recusa um corpo, a frase que ele usa está no `decode.go`, e
mudá-la é um diff de uma linha; na aula 4, mudar o `Bad Request` do Echo ou a mensagem do validador
do Gin queria dizer aprender onde cada framework guarda seus ganchos. Quando a aula 15 testar um
handler, ela testa estas linhas também, com as mesmas ferramentas.

## O que elas não custaram

As 269 linhas não trouxeram **nenhum módulo novo**: o `go.mod` do boxoffice ainda não lista nada
além do próprio módulo, e o binário não carrega nada que o boxoffice não chame. Elas não custaram
curva de aprendizado, porque usam exatamente os tipos que as aulas 1 a 3 ensinaram: `http.Handler`,
`ResponseWriter`, `encoding/json`, `context`. E não vão custar atualização: **a promessa de
compatibilidade do Go 1 quer dizer que código escrito contra o `net/http` em 2012 ainda compila**,
e nada nestes arquivos depende de uma versão posterior à 1.22.

O que elas custaram foi a escrita, uma vez, e o dever de acertar. O `decode.go` levou o maior
cuidado na aula 3 porque a versão óbvia de uma linha está errada de quatro jeitos, e a versão de um
framework teve esses erros encontrados por milhares de usuários. **Esse é o argumento mais forte que
um framework tem, e é um bom argumento** para código difícil de acertar. Para um `writeJSON` de 25
linhas, não é grande argumento.
