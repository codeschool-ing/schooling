---
title: "staticcheck: os bugs que o vet deixa passar"
version: 1
---

A lição 7 terminou com uma tabela do que o `go vet` nunca vai dizer, e o critério de precisão dele é o
motivo: uma checagem que acerta nove vezes em dez não basta para o vet. **O `staticcheck` é uma suíte
de analisadores sobre o mesmo framework que faz outra troca**: ele relata um bug muito provável em vez
de certo, código que tem uma grafia mais simples, uma chamada a algo obsoleto e código que ninguém
chama. Ele ainda busca poucos alarmes falsos, e é isso que deixa um projeto rodá-lo com os padrões e
mantê-lo ligado no CI.

## Um arquivo que o vet aprova

Tudo nesta lição acontece num só módulo, `~/lint`, com os quatro arquivos que a lição 1 imprime,
`tools/genlog/main.go`, `internal/tally/tally.go`, `main.go` e `main_test.go`, criado com
`go mod init example.com/hits`. Instale a versão fixada e rode-a sobre o `hits` como está:

```
ana@vm:~/lint$ go install honnef.co/go/tools/cmd/staticcheck@v0.8.2 && staticcheck -version
staticcheck 2026.2.2 (0.8.2)
ana@vm:~/lint$ go vet ./... && staticcheck ./...; echo $?
0
```

O `go install` não imprimiu nada porque o módulo já estava no cache aqui; numa primeira instalação ele
lista o que baixa. **O `hits` está limpo**: o vet e o staticcheck saem com 0 e não dizem nada, o que é
uma leitura justa de um programa pequeno escrito com cuidado.

Para ter o que achar, dê ao `hits` um arquivo do tipo que todo programa ganha cedo ou tarde: um resumo
que pode ser salvo em disco e lido de volta. Ele compila, e cada linha dele é algo que as pessoas
escrevem de verdade. Salve-o como `internal/tally/report.go`:

```go
package tally

import (
	"context"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

type report struct {
	lines, errors, api int
}

func NewReport(s Summary) *report {
	r := &report{lines: s.Lines}
	for status, n := range s.ByStatus {
		if status >= 500 {
			r.errors += n
		}
	}
	for path, n := range s.ByPath {
		if strings.Index(path, "/api/") != -1 {
			r.api += n
		}
	}
	return r
}

// ErrorShare is the share of requests that failed on the server.
func (r *report) ErrorShare() float64 {
	n := uint(r.lines)
	if n >= 0 {
		return float64(r.errors) / float64(n)
	}
	return 0
}

// Save writes the report to path, unless ctx is already done.
func Save(path string, ctx context.Context, r *report) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	if r.lines == 0 {
		return fmt.Errorf("Nothing to save.")
	}
	text := fmt.Sprintf("lines %d\nerrors %d\napi %d\n", r.lines, r.errors, r.api)
	os.WriteFile(path, []byte(text), 0o644)
	return nil
}

// ToCsv returns the report as one line of comma-separated values.
func (r *report) ToCsv() string {
	return fmt.Sprintf("%d,%d,%d", r.lines, r.errors, r.api)
}

// Load reads back what Save wrote.
func Load(path string) (string, error) {
	data, err := ioutil.ReadFile(path)
	return string(data), err
}

func percent(part, whole int) float64 {
	return 100 * float64(part) / float64(whole)
}
```

```
ana@vm:~/lint$ go vet ./...; echo $?
0
ana@vm:~/lint$ staticcheck ./...; echo $?
internal/tally/report.go:6:2: io/ioutil has been deprecated since Go 1.19: As of Go 1.16, the same functionality is now provided by package [io] or package [os], and those implementations should be preferred in new code. See the specific function documentation for details.  (SA1019)
internal/tally/report.go:23:6: should use strings.Contains(path, "/api/") instead (S1003)
internal/tally/report.go:33:5: every value of type uint is >= 0 (SA4003)
internal/tally/report.go:45:10: error strings should not be capitalized (ST1005)
internal/tally/report.go:45:10: error strings should not end with punctuation or newlines (ST1005)
internal/tally/report.go:63:6: func percent is unused (U1000)
1
```

**O vet o aprovou, e o staticcheck achou cinco problemas em seis linhas.** Cada linha termina com o
nome da checagem que a produziu, e as letras antes dos dígitos são a família a que a checagem pertence:

| família | o que procura | aqui |
|---|---|---|
| `SA`, staticcheck | código errado, ou muito provavelmente errado | `SA1019`, um pacote obsoleto; `SA4003`, uma condição sempre verdadeira |
| `S`, simple | código que tem um jeito mais curto de dizer a mesma coisa | `S1003`, `strings.Index(...) != -1` no lugar de `strings.Contains` |
| `ST`, stylecheck | convenções que o projeto Go escreveu | `ST1005`, uma string de erro com maiúscula e ponto final |
| `U1000`, unused | funções, tipos, campos e constantes que nada usa | `percent` |

**O `SA4003` é o que merece um relatório de bug.** `n` é um `uint`, então `n >= 0` vale para todo
valor que ele pode ter, e a guarda contra divisão por zero não guarda nada. O autor queria `n > 0`. Com
um log vazio, o `ErrorShare` divide 0.0 por 0.0, e a divisão de ponto flutuante por zero não entra em
pânico em Go: devolve `NaN`, que depois viaja para o que quer que imprima ou tire a média da fração. O
`SA1019` é menos urgente e igualmente real: o `io/ioutil` ainda funciona, e a própria documentação dele
diz que código novo deve usar `io` e `os`, que é o que a mensagem cita.

Os outros três não são bugs. `S1003` e `ST1005` são sobre leitura: `strings.Contains` diz o que a linha
quer dizer, e uma string de erro costuma ser impressa depois de outra coisa, como em
`hits: Nothing to save.`, onde uma maiúscula no meio da linha parece engano. **O `U1000` é sobre
peso**: uma função que ninguém chama ainda precisa ser lida, compilada e mantida funcionando.

## 149 checagens, e as oito desligadas

O `-list-checks` imprime todas as checagens que o programa conhece, uma por linha, e os dois primeiros
caracteres bastam para contar as famílias:

```
ana@vm:~/lint$ staticcheck -list-checks | wc -l
149
ana@vm:~/lint$ staticcheck -list-checks | cut -c1-2 | sort | uniq -c
     35 S1
     95 SA
     18 ST
      1 U1
ana@vm:~/lint$ staticcheck -explain SA4003
Comparing unsigned values against negative values is pointless

Available since
    2017.1

Online documentation
    https://staticcheck.dev/docs/checks#SA4003
```

**Quatro famílias, 149 checagens.** Uma quinta, `QF` de *quick fix*, existe no mesmo projeto e falta na
lista de propósito: são refatorações que um editor oferece numa linha, pelo `gopls`, e o
`cmd/staticcheck` só as registra atrás de uma flag de depuração. O `-explain` imprime para que serve uma
checagem e onde fica a página completa dela, que é o jeito mais rápido de decidir se vale discutir com
uma linha num log de CI.

**Nem todas as 149 rodam por padrão.** Oito ficam desligadas, porque apontam código que muitos projetos
escrevem de propósito: `ST1000`, um comentário de pacote ausente ou malformado; `ST1003`, nomes como
`ToCsv` que quebram a convenção de siglas do Go; `ST1016`, métodos cujos receptores têm nomes
diferentes; `ST1020` a `ST1022`, comentários de documentação que não começam com o nome que documentam;
`ST1023`, uma variável declarada com um tipo que o valor já informa; e `SA9003`, um ramo vazio. As
outras ficam ligadas, e esse padrão é o ponto: **uma checagem ligada em todo projeto é uma cujos alarmes
falsos os mantenedores tiveram de responder**.

## Escolhendo as checagens

A flag `-checks` recebe uma lista em que `inherit` quer dizer "o que já valia", um nome acrescenta uma
checagem e um nome com sinal de menos tira uma. Padrões também funcionam: `ST*` é a família de estilo
inteira.

```
ana@vm:~/lint$ staticcheck -checks=inherit,-ST1005 ./internal/tally; echo $?
internal/tally/report.go:6:2: io/ioutil has been deprecated since Go 1.19: As of Go 1.16, the same functionality is now provided by package [io] or package [os], and those implementations should be preferred in new code. See the specific function documentation for details.  (SA1019)
internal/tally/report.go:23:6: should use strings.Contains(path, "/api/") instead (S1003)
internal/tally/report.go:33:5: every value of type uint is >= 0 (SA4003)
internal/tally/report.go:63:6: func percent is unused (U1000)
1
```

**Uma lista na linha de comando é uma lista que cada pessoa e cada job de CI precisa digitar igual.** O
arquivo `staticcheck.conf` a guarda em vez disso. O staticcheck procura um no diretório de cada pacote e
em todos os diretórios acima, e o mais próximo vence; `inherit` nele quer dizer "o que o arquivo de cima
disse", ou os padrões, no topo. Salve este no topo do módulo, `staticcheck.conf`:

```toml
# staticcheck.conf: read from the package's directory and every one above it.
checks = ["inherit", "ST1003"]
initialisms = ["inherit", "CSV"]
```

Ele liga o `ST1003` e acrescenta `CSV` à lista de siglas que a checagem conhece, que começa com `API`,
`HTTP`, `ID`, `JSON`, `URL` e mais três dúzias, mas não `CSV`:

```
ana@vm:~/lint$ staticcheck ./... | grep -v SA1019
internal/tally/report.go:23:6: should use strings.Contains(path, "/api/") instead (S1003)
internal/tally/report.go:33:5: every value of type uint is >= 0 (SA4003)
internal/tally/report.go:45:10: error strings should not be capitalized (ST1005)
internal/tally/report.go:45:10: error strings should not end with punctuation or newlines (ST1005)
internal/tally/report.go:53:18: method ToCsv should be ToCSV (ST1003)
internal/tally/report.go:63:6: func percent is unused (U1000)
```

O `grep` tira do caminho a linha comprida do `SA1019`. **O `ToCsv` era invisível para os padrões e
agora é relatado**, porque o arquivo ligou uma checagem e lhe ensinou uma palavra.

## Silenciando uma linha

Alguns achados estão certos em geral e errados para uma linha. A resposta do staticcheck é um
comentário da forma `//lint:ignore CHECAGEM motivo`, posto na linha acima da que ele desculpa, e **o
motivo é obrigatório**: uma diretiva sem ele é recusada com
`malformed linter directive; missing the required reason field?`. Eis duas, postas com `sed`, uma onde
está o achado e outra na linha acima de um laço que o contém:

```
ana@vm:~/lint$ sed -i '/^func percent/i //lint:ignore U1000 kept for the -percent flag of the next release' internal/tally/report.go
ana@vm:~/lint$ sed -i '/for path, n := range/i //lint:ignore S1003 a loop over paths' internal/tally/report.go
ana@vm:~/lint$ staticcheck ./... | grep -v SA1019
internal/tally/report.go:22:1: this linter directive didn't match anything; should it be removed? (staticcheck)
internal/tally/report.go:24:6: should use strings.Contains(path, "/api/") instead (S1003)
internal/tally/report.go:34:5: every value of type uint is >= 0 (SA4003)
internal/tally/report.go:46:10: error strings should not be capitalized (ST1005)
internal/tally/report.go:46:10: error strings should not end with punctuation or newlines (ST1005)
internal/tally/report.go:54:18: method ToCsv should be ToCSV (ST1003)
```

**O `percent` sumiu, e a segunda diretiva é relatada como não casando com nada.** O `U1000` é relatado
na linha em que `func percent` começa, então o comentário acima o desculpou. O `S1003` é relatado no
`if` dentro do laço, duas linhas abaixo da diretiva, e uma diretiva cobre exatamente uma linha, então
ela não desculpou nada e o staticcheck disse isso. Esse aviso vale a pena: uma diretiva esquecida
depois que o código embaixo dela foi corrigido ou movido continuaria prometendo algo que já não cumpre.
Para um arquivo inteiro, `//lint:file-ignore CHECAGEM motivo` faz o mesmo de qualquer lugar do arquivo.
Apague as duas linhas de diretiva e o `staticcheck.conf` antes da seção 03, que parte do arquivo como
foi impresso.
