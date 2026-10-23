---
title: O `go test` como instrumento de todo dia
version: 1
---

O `go test` também é um build. **Para cada pacote, ele compila o pacote junto com os arquivos
`_test.go` num binário de teste, roda esse binário e guarda o resultado no cache de build.** As
lições 25 e 26 do `go-concurrency` ensinaram a escrever os testes. Esta seção trata de rodá-los do
jeito que você faz cinquenta vezes por dia: todos, um só, só os rápidos, até a primeira falha, e
numa forma que um programa consegue ler. Para isso é preciso um pacote com mais de um teste, então o
`tally` ganha os seus.

## Testes para o `tally`

`internal/tally/tally_test.go`, ao lado do `tally.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/tally/tally_test.go",
  "parts": [
    {
      "code": "package tally_test\n\nimport (\n\t\"fmt\"\n\t\"strings\"\n\t\"testing\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "**O pacote é `tally_test`, não `tally`.** Um arquivo de teste pode declarar o nome do pacote com `_test` acrescentado, e aí ele é compilado como um pacote separado que importa o `tally` como qualquer outro chamador faria. Ele só enxerga o que é exportado, que é o que o `go doc` vai mostrar na seção 05."
    },
    {
      "code": "func TestParse(t *testing.T) {\n\ttests := []struct {\n\t\tname    string\n\t\tline    string\n\t\tstatus  int\n\t\twantErr string // what the error starts with; \"\" for none\n\t}{\n\t\t{\"good\", \"2026-10-01T09:00:01Z POST /api/users 404 115ms\", 404, \"\"},\n\t\t{\"short line\", \"GET / 200\", 0, \"want 5 fields, got 3\"},\n\t\t{\"bad status\", \"2026-10-01T09:00:01Z GET / OK 5ms\", 0, \"status: \"},\n\t\t{\"bad duration\", \"2026-10-01T09:00:01Z GET / 200 5\", 0, \"time: missing unit\"},\n\t}",
      "note": "Uma tabela de linhas e do que cada uma deve produzir, o formato da lição 26 do `go-concurrency`. **O `name` de cada linha vira o nome de um subteste**, e os nomes foram escolhidos para que o `-run` consiga pegar um grupo deles: duas linhas começam com `bad`."
    },
    {
      "code": "\tfor _, tt := range tests {\n\t\tt.Run(tt.name, func(t *testing.T) {\n\t\t\te, err := tally.Parse(tt.line)\n\t\t\tif tt.wantErr != \"\" {\n\t\t\t\tif err == nil || !strings.HasPrefix(err.Error(), tt.wantErr) {\n\t\t\t\t\tt.Fatalf(\"error %v, want one starting %q\", err, tt.wantErr)\n\t\t\t\t}\n\t\t\t\treturn\n\t\t\t}\n\t\t\tif err != nil {\n\t\t\t\tt.Fatal(err)\n\t\t\t}\n\t\t\tif e.Status != tt.status {\n\t\t\t\tt.Errorf(\"status %d, want %d\", e.Status, tt.status)\n\t\t\t}\n\t\t})\n\t}\n}\n",
      "note": "O `t.Run` inicia um subteste por linha. O `t.Fatalf` encerra só aquele subteste; o laço segue para a linha seguinte."
    },
    {
      "code": "func TestTop(t *testing.T) {\n\ts := tally.Summary{ByPath: map[string]int{\"/b\": 2, \"/a\": 2, \"/c\": 5}}\n\tgot := fmt.Sprint(tally.Top(s, 2))\n\tif want := \"[{/c 5} {/a 2}]\"; got != want {\n\t\tt.Errorf(\"Top = %s, want %s\", got, want)\n\t}\n}\n",
      "note": "O `Top` é conferido num `Summary` montado à mão, com dois caminhos empatados em 2, para que o desempate alfabético faça parte do teste."
    },
    {
      "code": "func TestCountMillion(t *testing.T) {\n\tif testing.Short() {\n\t\tt.Skip(\"a million lines; skipped with -short\")\n\t}\n\tvar b strings.Builder\n\tfor i := range 1_000_000 {\n\t\tfmt.Fprintf(&b, \"2026-10-01T09:00:01Z GET /p%d 200 5ms\\n\", i%100)\n\t}\n\ts, err := tally.Count(strings.NewReader(b.String()))\n\tif err != nil {\n\t\tt.Fatal(err)\n\t}\n\tif s.Lines != 1_000_000 || len(s.ByPath) != 100 {\n\t\tt.Errorf(\"%d lines and %d paths, want 1000000 and 100\", s.Lines, len(s.ByPath))\n\t}\n}\n",
      "note": "**Um teste que sabe que é lento pergunta `testing.Short()`** e se pula quando a execução começou com `-short`. Este monta um milhão de linhas na memória e as conta."
    },
    {
      "code": "func ExampleTop() {\n\tlog := \"2026-10-01T09:00:01Z GET /login 200 5ms\\n\" +\n\t\t\"2026-10-01T09:00:02Z GET / 200 3ms\\n\" +\n\t\t\"2026-10-01T09:00:03Z POST /login 401 9ms\\n\"\n\ts, err := tally.Count(strings.NewReader(log))\n\tif err != nil {\n\t\tfmt.Println(err)\n\t\treturn\n\t}\n\tfor _, r := range tally.Top(s, 2) {\n\t\tfmt.Println(r.Path, r.Hits)\n\t}\n\t// Output:\n\t// /login 2\n\t// / 1\n}",
      "note": "**Um exemplo é um teste cuja saída esperada é o comentário `// Output:`.** O `go test` o roda e compara o que ele imprimiu, linha a linha; o `go doc` o lista ao lado do `Top`."
    }
  ]
}
```

## Todos, e o cache

O `./...` funciona para o `go test` como funciona para o `go build`, então um comando só testa o
módulo inteiro. Rodado duas vezes:

```
ana@vm:~/daily$ go test ./...
ok  	example.com/hits	0.006s
ok  	example.com/hits/internal/tally	0.483s
?   	example.com/hits/tools/genlog	[no test files]
ana@vm:~/daily$ go test ./...
ok  	example.com/hits	(cached)
ok  	example.com/hits/internal/tally	(cached)
?   	example.com/hits/tools/genlog	[no test files]
ana@vm:~/daily$ go test -count=1 ./internal/tally
ok  	example.com/hits/internal/tally	0.502s
```

O `genlog` não tem arquivos de teste e diz isso com `?`. Os testes do `tally` levaram **0,483
segundo**, quase todo ele no milhão de linhas, e na segunda vez a linha disse **`(cached)`**: nada
foi compilado e nada rodou. O comando go achou o mesmo binário de teste e as mesmas flags no cache, e
imprimiu a saída que tinha guardado.

**Um resultado em cache é um resultado passado, e só vale o que valem as entradas que a chave do
cache enxerga**: o código, as flags e, para um teste que abre arquivos dentro do módulo ou lê
variáveis de ambiente, esses arquivos e variáveis. Um teste que conversa com um banco de dados ou lê
o relógio entra no cache como se a resposta dele não pudesse mudar. O `-count=1` é o jeito idiomático
de dizer "rode de verdade", e ele rodou em 0,502 segundo. A maioria das flags de todo dia mantém o
cache em uso, e o `go help test` as lista: `-run`, `-short`, `-v`, `-failfast`, `-timeout` e mais
algumas. E o `go test` sem pacote nenhum, o "modo de diretório local" desse texto de ajuda, nunca
usa o cache.

## Os rápidos, uma lista e uma escolha

O `-short` liga uma flag que os testes leem com `testing.Short()`. O `go test` não faz mais nada com
ela, então um teste só é curto se alguém o escreveu para ser:

```
ana@vm:~/daily$ go test -short -v ./internal/tally
=== RUN   TestParse
=== RUN   TestParse/good
=== RUN   TestParse/short_line
=== RUN   TestParse/bad_status
=== RUN   TestParse/bad_duration
--- PASS: TestParse (0.00s)
    --- PASS: TestParse/good (0.00s)
    --- PASS: TestParse/short_line (0.00s)
    --- PASS: TestParse/bad_status (0.00s)
    --- PASS: TestParse/bad_duration (0.00s)
=== RUN   TestTop
--- PASS: TestTop (0.00s)
=== RUN   TestCountMillion
    tally_test.go:52: a million lines; skipped with -short
--- SKIP: TestCountMillion (0.00s)
=== RUN   ExampleTop
--- PASS: ExampleTop (0.00s)
PASS
ok  	example.com/hits/internal/tally	0.003s
ana@vm:~/daily$ go test -list . ./internal/tally
TestParse
TestTop
TestCountMillion
ExampleTop
ok  	example.com/hits/internal/tally	0.002s
```

**O `TestCountMillion` se pulou, com o seu motivo, e o pacote levou 0,003 segundo** em vez de meio
segundo. Um hook de pre-commit roda `-short`; a CI roda tudo. O `-list` recebe uma expressão regular
e imprime os testes e exemplos de primeiro nível que casam com ela, sem rodar nenhum; um subteste só
é criado quando o pai roda, então não tem como ser listado.

O `-run` também recebe uma expressão regular, e é a flag mais usada. **Uma barra a divide numa
expressão por nível de subteste**, então `TestParse/bad` quer dizer "um teste de primeiro nível que
case com `TestParse`, e depois um subteste que case com `bad`":

```
ana@vm:~/daily$ go test -run TestParse/bad -v ./internal/tally
=== RUN   TestParse
=== RUN   TestParse/bad_status
=== RUN   TestParse/bad_duration
--- PASS: TestParse (0.00s)
    --- PASS: TestParse/bad_status (0.00s)
    --- PASS: TestParse/bad_duration (0.00s)
PASS
ok  	example.com/hits/internal/tally	0.004s
ana@vm:~/daily$ go test -run "TestParse/bad status" -v ./internal/tally
=== RUN   TestParse
=== RUN   TestParse/bad_status
--- PASS: TestParse (0.00s)
    --- PASS: TestParse/bad_status (0.00s)
PASS
ok  	example.com/hits/internal/tally	0.002s
ana@vm:~/daily$ go test -run Top -v ./internal/tally
=== RUN   TestTop
--- PASS: TestTop (0.00s)
=== RUN   ExampleTop
--- PASS: ExampleTop (0.00s)
PASS
ok  	example.com/hits/internal/tally	0.002s
```

Os nomes da tabela viraram nomes de subteste com cada espaço trocado por um sublinhado,
`bad_status`. O segundo comando mostra que o `-run` aplica a mesma troca ao padrão, então o nome
como está escrito na tabela também funciona. **As expressões não são ancoradas**: `Top` casou com
`TestTop` e também com `ExampleTop`, porque para o `-run` um exemplo é um teste. `-run '^TestTop$'`
é o jeito de dizer exatamente um.

## Parando na primeira falha

Para ver uma falha, Ana quebra uma linha de propósito, trocando o status que a linha `good` espera
de 404 para 403, e roda o pacote duas vezes:

```
ana@vm:~/daily$ sed -i 's/115ms", 404/115ms", 403/' internal/tally/tally_test.go
ana@vm:~/daily$ go test ./internal/tally
--- FAIL: TestParse (0.00s)
    --- FAIL: TestParse/good (0.00s)
        tally_test.go:36: status 404, want 403
FAIL
FAIL	example.com/hits/internal/tally	0.473s
FAIL
ana@vm:~/daily$ go test -failfast -v ./internal/tally
=== RUN   TestParse
=== RUN   TestParse/good
    tally_test.go:36: status 404, want 403
--- FAIL: TestParse (0.00s)
    --- FAIL: TestParse/good (0.00s)
=== RUN   ExampleTop
--- PASS: ExampleTop (0.00s)
FAIL
FAIL	example.com/hits/internal/tally	0.004s
FAIL
ana@vm:~/daily$ sed -i 's/115ms", 403/115ms", 404/' internal/tally/tally_test.go
```

A primeira execução imprimiu a falha e mais nada sobre os testes que passaram, que é o que o
`go test` faz com um pacote listado pelo nome sem `-v`. Ela também rodou tudo, milhão de linhas
incluído, e levou **0,473 segundo** para relatar uma falha na primeira linha do primeiro teste.
**O `-failfast` não inicia nenhum teste novo depois da primeira falha**: as outras três linhas do
`TestParse`, o `TestTop` e o `TestCountMillion` nem começaram, e a execução levou 0,004 segundo. O
exemplo rodou mesmo assim. O `go help testflag` descreve a flag como algo que para os testes, e
nesta versão um exemplo é iniciado de qualquer jeito, o que vale saber antes que um exemplo lento vá
parar num pacote. O status de saída é 1 nos dois casos, e o último `sed` devolve a linha original.

## Saída para um programa, e cobertura

O `-json` transforma a execução num objeto JSON por evento, que é o que sistemas de CI e editores
leem. O campo `Time` abre cada linha com a data da execução, então o `cut` o tira aqui:

```
ana@vm:~/daily$ go test -json -run TestTop ./internal/tally | cut -d, -f2-
"Action":"start","Package":"example.com/hits/internal/tally"}
"Action":"run","Package":"example.com/hits/internal/tally","Test":"TestTop"}
"Action":"output","Package":"example.com/hits/internal/tally","Test":"TestTop","Output":"=== RUN   TestTop\n","OutputType":"frame"}
"Action":"output","Package":"example.com/hits/internal/tally","Test":"TestTop","Output":"--- PASS: TestTop (0.00s)\n","OutputType":"frame"}
"Action":"pass","Package":"example.com/hits/internal/tally","Test":"TestTop","Elapsed":0}
"Action":"output","Package":"example.com/hits/internal/tally","Output":"PASS\n","OutputType":"frame"}
"Action":"output","Package":"example.com/hits/internal/tally","Output":"ok  \texample.com/hits/internal/tally\t0.003s\n"}
"Action":"pass","Package":"example.com/hits/internal/tally","Elapsed":0.004}
```

Cada linha nomeia o seu pacote e, quando há, o seu teste; o `"Action"` diz o que aconteceu: `start`,
`run`, `output`, `pass`, `fail`, `skip`. Uma ferramenta que conta falhas em mil pacotes filtra por
`"Action":"fail"` em vez de interpretar o texto feito para uma pessoa.

O `-cover` acrescenta uma porcentagem à linha de cada pacote. A lição 30 do `go-concurrency` trata
de cobertura direito; aqui ela é só mais uma flag do mesmo comando:

```
ana@vm:~/daily$ go test -cover ./...
ok  	example.com/hits	0.003s	coverage: 49.3% of statements
ok  	example.com/hits/internal/tally	0.388s	coverage: 93.3% of statements
	example.com/hits/tools/genlog		coverage: 0.0% of statements
```

**93,3% das instruções do `tally` rodaram** sob os seus próprios testes, e 49,3% das do `main` sob o
`TestRun`. O `genlog`, sem teste nenhum, aparece com 0,0% em vez de ficar de fora, então um pacote
que ninguém testou se destaca na lista.
