---
title: Um Parse mais rápido
version: 1
---

O profile disse três coisas. O `strings.Fields` leva dois terços do `Parse`; cerca de dois quintos do custo dele é alocar a fatia que devolve e os write barriers que preenchê-la exige; e o horário, o suspeito de
sempre, custa um quarto disso. **A mudança que vale fazer é a que remove a fatia**, e ela tem de deixar
toda resposta do `Parse` exatamente como era, porque o `hits` está correto hoje e um programa mais
rápido e errado não é melhoria.

## Primeiro, os números a bater

Antes de mexer no código, Ana guarda os resultados atuais do benchmark num arquivo, dez execuções,
porque uma execução de benchmark numa máquina compartilhada é uma amostra de um número com ruído:

```
ana@vm:~/prof$ go test -run '^$' -bench Count -benchmem -count 10 ./internal/tally > old.txt
```

O `-count 10` roda o benchmark dez vezes; o `-benchmem` mantém as colunas de memória. A seção 06
compara este arquivo com o que é gravado depois da mudança.

## O que o `strings.Fields` faz e o `Parse` não precisa

O `strings.Fields` separa em qualquer sequência de espaço em branco, como o Unicode o define, e
devolve uma fatia nova com quantos campos encontrar. As linhas do `genlog`, como a maioria dos logs de
acesso, têm exatamente cinco campos separados por um espaço simples, em ASCII imprimível. Então o plano
é uma função que **trata só esse caso simples, sem alocar, e recusa todo o resto**, e um `Parse` que
pergunta a ela primeiro e recorre ao `strings.Fields` quando ela recusa. O recurso mantém toda linha
estranha no caminho antigo, que já se sabe correto. Em `~/prof`, salve como
`internal/tally/split.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/tally/split.go",
  "parts": [
    {
      "code": "package tally\n\n// split5 cuts line into five fields at single spaces, without allocating.\n// It answers only for the plain case: printable ASCII, one space between\n// fields and none at either end. For anything else ok is false, and Parse\n// asks strings.Fields, which knows every kind of white space.\nfunc split5(line string) (f [5]string, ok bool) {",
      "note": "**Um arquivo novo no mesmo pacote**, então nada fora do `tally` vê o `split5`. Ele devolve um array de cinco strings, um valor de tamanho fixo que vive no quadro de quem chamou, enquanto o `strings.Fields` devolve uma fatia que precisou alocar no heap."
    },
    {
      "code": "\tn, start := 0, 0\n\tfor i := 0; i < len(line); i++ {\n\t\tswitch c := line[i]; {\n\t\tcase c == ' ':\n\t\t\tif i == start || n == 4 {\n\t\t\t\treturn f, false\n\t\t\t}\n\t\t\tf[n] = line[start:i]\n\t\t\tn, start = n+1, i+1\n\t\tcase c < '!' || c > '~':\n\t\t\treturn f, false\n\t\t}\n\t}",
      "note": "Uma passada pelos bytes. Um espaço encerra um campo: um campo vazio (dois espaços, ou um no começo) ou um quinto espaço quer dizer que a linha não é o caso simples. **Qualquer byte fora de `!` a `~` também recusa**: essa faixa é o ASCII imprimível, e fora dela ficam o tab, a quebra de linha e todo byte de um caractere de vários bytes, inclusive os espaços Unicode em que o `strings.Fields` separaria."
    },
    {
      "code": "\tif n != 4 || start == len(line) {\n\t\treturn f, false\n\t}\n\tf[4] = line[start:]\n\treturn f, true\n}",
      "note": "Exatamente quatro espaços vistos, e algo depois do último: o quinto campo é o resto da linha. As strings em `f` são fatias da própria `line`, então nada foi copiado."
    }
  ]
}
```

E o `Parse` muda só nas primeiras linhas. `internal/tally/tally.go`, inteiro:

```schooling-example
{
  "language": "go",
  "file": "internal/tally/tally.go",
  "parts": [
    {
      "code": "// Package tally reads the lines of an access log and counts them.\npackage tally\n\nimport (\n\t\"bufio\"\n\t\"cmp\"\n\t\"fmt\"\n\t\"io\"\n\t\"slices\"\n\t\"strconv\"\n\t\"strings\"\n\t\"time\"\n)\n\n// Entry is one line of the log.\ntype Entry struct {\n\tTime     time.Time\n\tMethod   string\n\tPath     string\n\tStatus   int\n\tDuration time.Duration\n}\n",
      "note": "Igual à lição 1, imports incluídos: o `strings` continua necessário, para as linhas que o `split5` recusa."
    },
    {
      "code": "// Parse reads one line: a time, a method, a path, a status and a duration,\n// separated by spaces.\nfunc Parse(line string) (Entry, error) {\n\tf, ok := split5(line)\n\tif !ok {\n\t\tall := strings.Fields(line)\n\t\tif len(all) != 5 {\n\t\t\treturn Entry{}, fmt.Errorf(\"want 5 fields, got %d\", len(all))\n\t\t}\n\t\tf = [5]string(all)\n\t}\n\tt, err := time.Parse(time.RFC3339, f[0])\n\tif err != nil {\n\t\treturn Entry{}, err\n\t}\n\tstatus, err := strconv.Atoi(f[3])\n\tif err != nil {\n\t\treturn Entry{}, fmt.Errorf(\"status: %w\", err)\n\t}\n\td, err := time.ParseDuration(f[4])\n\tif err != nil {\n\t\treturn Entry{}, err\n\t}\n\treturn Entry{Time: t, Method: f[1], Path: f[2], Status: status, Duration: d}, nil\n}\n",
      "note": "**A única mudança no arquivo.** O `split5` é consultado primeiro e, quando responde, os cinco campos dele são usados como estão. Quando recusa, o código antigo roda, palavra por palavra, dentro do `if`, então uma linha com tabs, ou seis campos, ou um caminho acentuado recebe exatamente o que recebia antes, mensagem de erro incluída. `[5]string(all)` converte uma fatia de tamanho 5 num array das mesmas cinco strings."
    },
    {
      "code": "// Summary is what Count found.\ntype Summary struct {\n\tLines    int\n\tByStatus map[int]int\n\tByPath   map[string]int\n\tTotal    time.Duration\n}\n\n// Count reads every line from r. A line it cannot parse stops it, and the\n// error names the line.\nfunc Count(r io.Reader) (Summary, error) {\n\ts := Summary{ByStatus: map[int]int{}, ByPath: map[string]int{}}\n\tsc := bufio.NewScanner(r)\n\tfor n := 1; sc.Scan(); n++ {\n\t\te, err := Parse(sc.Text())\n\t\tif err != nil {\n\t\t\treturn s, fmt.Errorf(\"line %d: %w\", n, err)\n\t\t}\n\t\ts.Lines++\n\t\ts.ByStatus[e.Status]++\n\t\ts.ByPath[e.Path]++\n\t\ts.Total += e.Duration\n\t}\n\treturn s, sc.Err()\n}\n\n// PathCount is one row of Top.\ntype PathCount struct {\n\tPath string `json:\"path\"`\n\tHits int    `json:\"hits\"`\n}\n\n// Top returns the n paths with the most requests, the most first. Paths\n// with the same count come in alphabetical order.\nfunc Top(s Summary, n int) []PathCount {\n\trows := make([]PathCount, 0, len(s.ByPath))\n\tfor p, h := range s.ByPath {\n\t\trows = append(rows, PathCount{p, h})\n\t}\n\tslices.SortFunc(rows, func(a, b PathCount) int {\n\t\treturn cmp.Or(cmp.Compare(b.Hits, a.Hits), cmp.Compare(a.Path, b.Path))\n\t})\n\treturn rows[:min(n, len(rows))]\n}",
      "note": "`Summary`, `Count`, `PathCount` e `Top` estão exatamente como a lição 1 os imprimiu."
    }
  ]
}
```

**O `split5` nunca precisa acertar uma linha difícil, só as linhas que aceita.** Ele só aceita aquelas em que o espaço simples é o único espaço em branco, e nessas o `strings.Fields` teria cortado exatamente nos mesmos lugares. Todo o resto, tabs, espaços dobrados, um caminho
acentuado, um sexto campo, desce pelo caminho que sempre o tratou.

## Provando que concorda

Esse argumento convence e ainda assim pode estar errado, então ganha um teste. A propriedade a testar
não é "o `split5` devolve estes campos para esta linha", e sim a geral: **onde ele responde, responde o
que o `strings.Fields` responderia**. `internal/tally/split_test.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/tally/split_test.go",
  "parts": [
    {
      "code": "package tally\n\nimport (\n\t\"os\"\n\t\"slices\"\n\t\"strings\"\n\t\"testing\"\n)\n",
      "note": "**`package tally`, não `tally_test`**: o `split5` não é exportado, e só um teste de dentro do pacote consegue chamá-lo."
    },
    {
      "code": "// agree fails the test if split5 answers for line and strings.Fields would\n// have answered differently. It reports whether split5 answered.\nfunc agree(t *testing.T, line string) bool {\n\tt.Helper()\n\tf, ok := split5(line)\n\tif !ok {\n\t\treturn false\n\t}\n\tif want := strings.Fields(line); !slices.Equal(f[:], want) {\n\t\tt.Errorf(\"split5(%q) = %q, strings.Fields says %q\", line, f, want)\n\t}\n\treturn true\n}\n",
      "note": "A propriedade numa função: **onde o `split5` responde, responde o que o `strings.Fields` responderia.** Recusar é sempre permitido, porque o `Parse` então recorre ao próprio `strings.Fields`. O `t.Helper` faz uma falha apontar para a linha de quem chamou, e não para esta."
    },
    {
      "code": "// Lines on which a careless split5 would disagree with strings.Fields.\nvar tricky = []string{\n\t\"\",\n\t\"GET / 200\",\n\t\"a b c d e f\",\n\t\" a b c d e\",\n\t\"a b c d e \",\n\t\"a  b c d e\",\n\t\"a\\tb c d e f\",\n\t\"a b c d e f\",\n\t\"a\\u0085b c d e f\",\n}\n",
      "note": "As linhas que um separador escrito à mão erra: campos de menos ou de mais, espaços numa ponta ou dobrados, e três tipos de espaço em branco que não são o caractere de espaço, `\\t`, o espaço sem quebra U+00A0 e o U+0085."
    },
    {
      "code": "func TestSplit5(t *testing.T) {\n\tfor _, line := range tricky {\n\t\tagree(t, line)\n\t}\n\tdata, err := os.ReadFile(\"testdata/access.log\")\n\tif err != nil {\n\t\tt.Fatal(err)\n\t}\n\tlines := strings.Split(strings.TrimSuffix(string(data), \"\\n\"), \"\\n\")\n\tfor _, line := range lines {\n\t\tif !agree(t, line) {\n\t\t\tt.Fatalf(\"split5 left a line genlog wrote to strings.Fields: %q\", line)\n\t\t}\n\t}\n}\n",
      "note": "Duas verificações. As linhas difíceis não podem ser respondidas errado, e **cada uma das 100.000 linhas que o `genlog` escreveu precisa ser respondida**, porque um `split5` que recusasse tudo seria correto e inútil."
    },
    {
      "code": "func FuzzSplit5(f *testing.F) {\n\tfor _, line := range tricky {\n\t\tf.Add(line)\n\t}\n\tf.Fuzz(func(t *testing.T, line string) {\n\t\tagree(t, line)\n\t})\n}",
      "note": "**Um alvo de fuzz afirma a mesma propriedade para qualquer string.** O `go test` o roda nas sementes dadas a `f.Add` toda vez; o `go test -fuzz` gera entradas novas a partir delas, pelo tempo que for permitido, procurando uma que falhe."
    }
  ]
}
```

Os testes que a lição 5 escreveu para o `tally`, o `internal/tally/tally_test.go` dela com as linhas
ruins e as mensagens de erro, também vão para `~/prof`: eles verificam a outra metade da promessa, que
o `Parse` continua recusando o que recusava, com as mesmas palavras. Primeiro o `go vet`, depois todos
os testes do módulo, o `main_test.go` da lição 1 incluído:

```
ana@vm:~/prof$ go vet ./... && go test ./...
ok  	example.com/hits	(cached)
ok  	example.com/hits/internal/tally	0.386s
?   	example.com/hits/tools/genlog	[no test files]
```

**Um teste que nunca falhou não mostrou que consegue falhar.** Então Ana quebra o `split5` de
propósito, apagando as duas linhas que recusam qualquer byte fora do ASCII imprimível, que é o erro que
um separador escrito à mão costuma cometer, e roda o pacote de novo:

```
ana@vm:~/prof$ cp internal/tally/split.go split.go.bak
ana@vm:~/prof$ sed -i "/c < .!. || c > .~./,+1d" internal/tally/split.go
ana@vm:~/prof$ go test ./internal/tally
--- FAIL: TestSplit5 (0.04s)
    split_test.go:39: split5("a\tb c d e f") = ["a\tb" "c" "d" "e" "f"], strings.Fields says ["a" "b" "c" "d" "e" "f"]
    split_test.go:39: split5("a\u00a0b c d e f") = ["a\u00a0b" "c" "d" "e" "f"], strings.Fields says ["a" "b" "c" "d" "e" "f"]
    split_test.go:39: split5("a\u0085b c d e f") = ["a\u0085b" "c" "d" "e" "f"], strings.Fields says ["a" "b" "c" "d" "e" "f"]
--- FAIL: FuzzSplit5 (0.00s)
    --- FAIL: FuzzSplit5/seed#6 (0.00s)
        split_test.go:58: split5("a\tb c d e f") = ["a\tb" "c" "d" "e" "f"], strings.Fields says ["a" "b" "c" "d" "e" "f"]
    --- FAIL: FuzzSplit5/seed#7 (0.00s)
        split_test.go:58: split5("a\u00a0b c d e f") = ["a\u00a0b" "c" "d" "e" "f"], strings.Fields says ["a" "b" "c" "d" "e" "f"]
    --- FAIL: FuzzSplit5/seed#8 (0.00s)
        split_test.go:58: split5("a\u0085b c d e f") = ["a\u0085b" "c" "d" "e" "f"], strings.Fields says ["a" "b" "c" "d" "e" "f"]
FAIL
FAIL	example.com/hits/internal/tally	0.390s
FAIL
ana@vm:~/prof$ mv split.go.bak internal/tally/split.go
```

Três das linhas difíceis pegam o erro, o tab e os dois espaços Unicode, uma vez no `TestSplit5` e uma
vez como sementes do alvo de fuzz, que o `go test` roda como testes comuns. Cada falha imprime as duas
respostas lado a lado, `["a\tb" "c" "d" "e" "f"]` contra seis campos, que é o bug inteiro numa linha.
O `mv` devolve o arquivo.

## Fuzzing para as linhas em que ninguém pensou

A lista de linhas difíceis tem os casos em que alguém pensou. O `go test -fuzz` procura os outros: ele
parte das sementes, faz mutações nelas, guarda as entradas que chegam a código novo e roda o alvo em
cada uma, com um worker por processador, até o tempo acabar ou aparecer uma falha:

```
ana@vm:~/prof$ go test -fuzz FuzzSplit5 -fuzztime 10s ./internal/tally
fuzz: elapsed: 0s, gathering baseline coverage: 0/26 completed
fuzz: elapsed: 0s, gathering baseline coverage: 26/26 completed, now fuzzing with 4 workers
fuzz: elapsed: 3s, execs: 395640 (131840/sec), new interesting: 0 (total: 26)
fuzz: elapsed: 6s, execs: 845178 (149859/sec), new interesting: 0 (total: 26)
fuzz: elapsed: 9s, execs: 1264941 (139915/sec), new interesting: 0 (total: 26)
fuzz: elapsed: 10s, execs: 1398846 (124132/sec), new interesting: 0 (total: 26)
PASS
ok  	example.com/hits/internal/tally	10.972s
```

**Cerca de 1,4 milhão de strings geradas em dez segundos, e nenhuma em que o `split5` e o
`strings.Fields` discordem.** "new interesting" conta as entradas que levaram o código por um caminho
que nenhuma entrada anterior tinha seguido. O fuzzer guarda essas no cache do comando go e parte delas da próxima vez. Por isso esta execução começou de 26 entradas, as nove sementes e o que fuzzing
anterior nesta máquina tinha guardado; uma primeira execução começa das nove. Uma falha teria sido
gravada em `testdata/fuzz/FuzzSplit5/` dentro do pacote, como um arquivo que o `go test` passa a rodar
como semente para sempre, então um bug encontrado uma vez continua testado. Fuzzing não é prova, mas,
junto com o argumento acima e as 100.000 linhas do `genlog`, é toda a evidência que uma mudança deste
tamanho merece.
