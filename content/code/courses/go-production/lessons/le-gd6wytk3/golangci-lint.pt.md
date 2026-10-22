---
title: "golangci-lint: um executor, uma configuração"
version: 1
---

As seções 02 e 03 rodaram dois linters, e um projeto que adota os dois agora tem duas instalações para
fixar, dois arquivos de configuração em dois formatos, dois estilos de saída e duas ideias do que um
código de saída quer dizer. Acrescente o `errcheck` para erros descartados e mais alguns, e o passo de
CI vira um script próprio. **O `golangci-lint` é um executor: carrega mais de cem linters dentro de um
binário, roda os que um único arquivo YAML nomeia, e os relata num formato com um código de saída.** A
maioria dos linters que ele carrega são analisadores sobre o mesmo framework do vet, então ele carrega
e verifica os tipos de cada pacote uma vez e entrega o resultado a todos, em paralelo, e guarda em
cache o que achou para arquivos que não mudaram.

## Instalando, e o que vem dentro

```
ana@vm:~/lint$ go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.14.0 && golangci-lint version
golangci-lint has version 2.14.0 built with go1.27.1 from (unknown, modified: ?, mod sum: "h1:ot8QffRa4LzAAEgtvNYrVs9esxQ7xoTwoAv6uhp4ngA=") on (unknown)
ana@vm:~/lint$ du -b $(command -v staticcheck revive golangci-lint)
17189203	/home/ana/go/bin/staticcheck
15818634	/home/ana/go/bin/revive
71168128	/home/ana/go/bin/golangci-lint
ana@vm:~/lint$ golangci-lint linters --no-config | head -6
Enabled by your configuration linters:
errcheck: Errcheck is a program for checking for unchecked errors in Go code. These unchecked errors can be critical bugs in some cases.
govet: Vet examines Go source code and reports suspicious constructs. It is roughly the same as 'go vet' and uses its passes. [auto-fix]
ineffassign: Detects when assignments to existing variables are not used. [fast]
staticcheck: It's the set of rules from staticcheck. [auto-fix]
unused: Checks Go code for unused constants, variables, functions and types.
ana@vm:~/lint$ golangci-lint help linters | grep -c ": "
115
ana@vm:~/lint$ go version -m $(command -v golangci-lint) | grep -E "honnef|revive"
	dep	github.com/mgechev/revive	v1.17.0	h1:hwTTVC3svSv9X2FA2hiYT17Uws+lfxDWhPxzBZZCREg=
	dep	honnef.co/go/tools	v0.8.1	h1:+JKf3xJ1ni4CwrhVg4/pqsfPGP6vNAXcKbMXJodYx3w=
```

O binário tem **71.168.128 bytes**, quatro vezes o tamanho do staticcheck, porque os outros linters
estão compilados dentro dele. O `golangci-lint help linters` lista 115 deles. Sem arquivo de
configuração roda o conjunto chamado `standard`, e são os cinco que o `linters` imprimiu: `errcheck`
para erros descartados, `govet`, `ineffassign` para atribuições que nada lê, `staticcheck` e `unused`.

O último comando mostra algo que vale saber antes de fixar uma versão. **O staticcheck e o revive
dentro do golangci-lint 2.14.0 são o v0.8.1 e o v1.17.0**, uma versão atrás do v0.8.2 e do v1.17.1
instalados sozinhos nas seções 02 e 03. Essas versões são escolha do golangci-lint, feita no `go.mod`
dele, e cada versão dele move algumas; o changelog da 2.14.0 lista onze linters atualizados, o revive
de 1.15.0 para 1.17.0 entre eles.

## Os padrões, no `~/lint`

O `~/lint` está como a seção 03 o deixou, com o `report.go` e sem a diretiva do revive. O
`--no-config` garante que nenhum arquivo é lido, e o `--output.text.print-issued-lines=false` imprime
uma linha por achado em vez de três:

```
ana@vm:~/lint$ golangci-lint run --no-config --output.text.print-issued-lines=false; echo $?
internal/tally/report.go:48:14: Error return value of `os.WriteFile` is not checked (errcheck)
main.go:33:13: Error return value of `fmt.Fprint` is not checked (errcheck)
main.go:42:13: Error return value of `fmt.Fprint` is not checked (errcheck)
main.go:45:13: Error return value of `fmt.Fprintf` is not checked (errcheck)
main.go:64:14: Error return value of `fmt.Fprintln` is not checked (errcheck)
main.go:66:14: Error return value of `fmt.Fprintf` is not checked (errcheck)
main.go:88:14: Error return value of `fmt.Fprintln` is not checked (errcheck)
main.go:108:16: Error return value of `f.Close` is not checked (errcheck)
tools/genlog/main.go:27:15: Error return value of `w.Flush` is not checked (errcheck)
tools/genlog/main.go:32:14: Error return value of `fmt.Fprintf` is not checked (errcheck)
internal/tally/report.go:59:15: inline: Call of ioutil.ReadFile should be inlined (govet)
internal/tally/report.go:6:2: SA1019: io/ioutil has been deprecated since Go 1.19: As of Go 1.16, the same functionality is now provided by package [io] or package [os], and those implementations should be preferred in new code. See the specific function documentation for details. (staticcheck)
internal/tally/report.go:23:6: S1003: should use strings.Contains(path, "/api/") instead (staticcheck)
internal/tally/report.go:33:5: SA4003: every value of type uint is >= 0 (staticcheck)
internal/tally/report.go:45:10: ST1005: error strings should not end with punctuation or newlines (staticcheck)
internal/tally/report.go:63:6: func percent is unused (unused)
16 issues:
* errcheck: 10
* govet: 1
* staticcheck: 4
* unused: 1
1
```

**Dezesseis achados, e dez deles são do `errcheck`.** É assim que fica uma primeira execução sobre um
projeto existente, e vale ler os dez antes de decidir o que significam:

| onde | o que foi descartado | vale corrigir? |
|---|---|---|
| `report.go:48` | o erro do `os.WriteFile` | sim: o `Save` relata sucesso para um arquivo que nunca escreveu |
| `genlog/main.go:27` | o erro do `w.Flush`, num `defer` | sim, discutivelmente: um disco cheio trunca o log e o `genlog` sai com 0 |
| `main.go:108` | o erro de fechar um arquivo aberto para leitura | não: não há nada que um leitor pudesse ter perdido |
| sete linhas de `fmt.Fprint` | o erro de escrever uma mensagem na saída de erro | não: se a saída de erro não aceita escrita, não há a quem avisar |

Um bug real, um caso de julgamento e oito linhas de ruído. **O golangci-lint 2 relata todos, de
propósito**: a versão 1 escondia por padrão os casos de imprimir e fechar, e o changelog da 2.0.0 traz
"No exclusions by default", o que deixa a escolha com cada projeto. As duas linhas de `govet` e
`staticcheck` sobre o `report.go` mostram duas coisas menores. O `govet` aqui roda um analisador que o
`go vet` não roda, `inline`, que relata chamadas a funções marcadas com `//go:fix inline`, e no Go
1.27.1 o `ioutil.ReadFile` é uma delas; é o analisador que o `go fix` usa para reescrever essas
chamadas. E há uma linha de `ST1005` onde o staticcheck sozinho imprimiu duas, porque por padrão o
golangci-lint mantém um achado por linha.

Lado a lado, os padrões das quatro ferramentas acharam isto:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 366\" role=\"img\" aria-label=\"Os nove problemas do report.go, um por linha, contra quatro ferramentas com seus padrões. O go vet não acha nenhum. O staticcheck acha cinco: o pacote obsoleto como SA1019, o strings.Index como S1003, o teste do uint como SA4003, a string de erro como ST1005 e a função sem uso como U1000. O revive acha quatro: a string de erro, o context passado em segundo, o comentário de documentação ausente e o tipo privado devolvido. O conjunto standard do golangci-lint acha seis: os cinco do staticcheck, a chamada obsoleta também pelo inline do govet, e o erro descartado de os.WriteFile pelo errcheck. Nenhuma ferramenta acha os nove.\"><text x=\"302.0\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">go vet</text><text x=\"388.0\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">staticcheck</text><text x=\"520.0\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">revive</text><text x=\"658.0\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">golangci-lint</text><text x=\"16\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um pacote obsoleto importado</text><rect x=\"270\" y=\"50\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"50\" width=\"92\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"388.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SA1019</text><rect x=\"442\" y=\"50\" width=\"156\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"606\" y=\"50\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"658.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SA1019, inline</text><text x=\"16\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">strings.Index comparado com -1</text><rect x=\"270\" y=\"80\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"80\" width=\"92\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"388.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S1003</text><rect x=\"442\" y=\"80\" width=\"156\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"606\" y=\"80\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"658.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S1003</text><text x=\"16\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um uint testado com &gt;= 0</text><rect x=\"270\" y=\"110\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"110\" width=\"92\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"388.0\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SA4003</text><rect x=\"442\" y=\"110\" width=\"156\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"606\" y=\"110\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"658.0\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SA4003</text><text x=\"16\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">erro com maiúscula e ponto final</text><rect x=\"270\" y=\"140\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"140\" width=\"92\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"388.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ST1005</text><rect x=\"442\" y=\"140\" width=\"156\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"520.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">error-strings</text><rect x=\"606\" y=\"140\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"658.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ST1005</text><text x=\"16\" y=\"182\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uma função que ninguém chama</text><rect x=\"270\" y=\"170\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"170\" width=\"92\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"388.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">U1000</text><rect x=\"442\" y=\"170\" width=\"156\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"606\" y=\"170\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"658.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">unused</text><text x=\"16\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">context fora do 1º parâmetro</text><rect x=\"270\" y=\"200\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"200\" width=\"92\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"442\" y=\"200\" width=\"156\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"520.0\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">context-as-argument</text><rect x=\"606\" y=\"200\" width=\"104\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"16\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">exportada, sem comentário</text><rect x=\"270\" y=\"230\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"230\" width=\"92\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"442\" y=\"230\" width=\"156\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"520.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">exported</text><rect x=\"606\" y=\"230\" width=\"104\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"16\" y=\"272\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">exportada, devolve tipo privado</text><rect x=\"270\" y=\"260\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"260\" width=\"92\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"442\" y=\"260\" width=\"156\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"520.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">unexported-return</text><rect x=\"606\" y=\"260\" width=\"104\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"16\" y=\"302\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o erro de os.WriteFile descartado</text><rect x=\"270\" y=\"290\" width=\"64\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"342\" y=\"290\" width=\"92\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"442\" y=\"290\" width=\"156\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"606\" y=\"290\" width=\"104\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"658.0\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">errcheck</text><line x1=\"16\" y1=\"326\" x2=\"710\" y2=\"326\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"16\" y=\"344\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">linhas achadas</text><text x=\"302.0\" y=\"344\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">0</text><text x=\"388.0\" y=\"344\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">5</text><text x=\"520.0\" y=\"344\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">4</text><text x=\"658.0\" y=\"344\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">6</text></svg>", "caption": "Os nove problemas do report.go contra quatro ferramentas, cada uma com seus padrões. O vet não acha nenhum, e nenhuma ferramenta sozinha acha os nove: as três linhas que só o revive acha faltam ao conjunto standard do golangci-lint, e a configuração logo abaixo as acrescenta."}
```

## Um arquivo de configuração

O `.golangci.yml` no topo do módulo é achado sozinho; o `golangci-lint` o procura no diretório atual e
nos de cima. Este mantém o conjunto standard, acrescenta as três regras do revive que mais nada tem e
mais o `error-strings`, e silencia os erros que todo programa descarta. Salve-o como `.golangci.yml`:

```schooling-example
{
  "language": "yaml",
  "file": ".golangci.yml",
  "parts": [
    {
      "code": "# .golangci.yml: what golangci-lint runs over this module, and what it keeps quiet.\nversion: \"2\"\n",
      "note": "**`version: \"2\"` é obrigatório.** O golangci-lint 2 recusa um arquivo sem ele, com `unsupported version of the configuration` e status de saída 3, e o `golangci-lint migrate` reescreve um arquivo da versão 1 neste formato."
    },
    {
      "code": "linters:\n  default: standard\n  enable:\n    - revive\n    - nolintlint",
      "note": "`default` escolhe o conjunto de partida: `standard` são os cinco do `golangci-lint linters`, e `all`, `none` e `fast` são os outros. `enable` acrescenta a ele, aqui o revive e um linter que verifica os próprios comentários `//nolint`."
    },
    {
      "code": "  settings:\n    revive:\n      rules:\n        - name: context-as-argument\n        - name: error-strings\n        - name: exported\n        - name: unexported-return\n    nolintlint:\n      require-explanation: true\n      require-specific: true",
      "note": "As configurações de cada linter ficam sob o nome dele. As regras do revive são as do TOML, escritas em YAML, e **listar qualquer uma desliga também aqui os padrões do revive**, por isso as quatro que este módulo quer estão nomeadas. O `nolintlint` vai exigir um nome de linter e um motivo em todo `//nolint`."
    },
    {
      "code": "  exclusions:\n    presets:\n      - std-error-handling\n",
      "note": "**Um preset é um conjunto nomeado de exclusões.** O `std-error-handling` faz o `errcheck` parar de relatar os erros que quase todo programa descarta de propósito: imprimir, fechar, dar flush, `os.Remove`, definir uma variável de ambiente."
    },
    {
      "code": "formatters:\n  enable:\n    - gofmt\n    - goimports\n  settings:\n    goimports:\n      local-prefixes:\n        - example.com/hits\n",
      "note": "Os dois formatadores da lição 6, rodados pelo mesmo binário. `local-prefixes` é o `goimports -local`, escrito uma vez. O `golangci-lint run` relata um arquivo que não está formatado, e o `golangci-lint fmt` o reescreve."
    },
    {
      "code": "issues:\n  max-issues-per-linter: 0\n  max-same-issues: 0\n  uniq-by-line: false",
      "note": "Por padrão a saída para em 50 achados por linter e 3 com o mesmo texto, e mantém um achado por linha. **Zero tira os dois limites**, e `uniq-by-line: false` mostra dois achados que caem na mesma linha."
    }
  ]
}
```

O `golangci-lint config verify` confere um arquivo contra o schema embutido no binário. **Isso importa
porque o `run` ignora uma chave que não conhece**: um arquivo dizendo `enabel:` onde queria `enable:`
roda o conjunto standard, relata sobre ele e sai com 0, sem o revive jamais começar. O schema não deixa
passar:

```
ana@vm:~/lint$ printf 'version: "2"\nlinters:\n  enabel: [revive]\n' > typo.yml
ana@vm:~/lint$ golangci-lint config verify -c typo.yml; echo $?
jsonschema: "linters" does not validate with "/properties/linters/additionalProperties": additional properties 'enabel' not allowed
The command is terminated due to an error: the configuration contains invalid elements
3
```

Então a checagem vale a pena antes de usar o arquivo de verdade, e no CI antes dos linters:

```
ana@vm:~/lint$ golangci-lint config verify && golangci-lint run --output.text.print-issued-lines=false; echo $?
internal/tally/report.go:48:14: Error return value of `os.WriteFile` is not checked (errcheck)
internal/tally/report.go:59:15: inline: Call of ioutil.ReadFile should be inlined (govet)
internal/tally/report.go:15:1: exported: exported function NewReport should have comment or be unexported (revive)
internal/tally/report.go:15:27: unexported-return: exported func NewReport returns unexported type *tally.report, which can be annoying to use (revive)
internal/tally/report.go:40:24: context-as-argument: context.Context should be the first parameter of a function (revive)
internal/tally/report.go:45:21: error-strings: error strings should not be capitalized or end with punctuation or a newline (revive)
internal/tally/report.go:6:2: SA1019: io/ioutil has been deprecated since Go 1.19: As of Go 1.16, the same functionality is now provided by package [io] or package [os], and those implementations should be preferred in new code. See the specific function documentation for details. (staticcheck)
internal/tally/report.go:23:6: S1003: should use strings.Contains(path, "/api/") instead (staticcheck)
internal/tally/report.go:33:5: SA4003: every value of type uint is >= 0 (staticcheck)
internal/tally/report.go:45:10: ST1005: error strings should not end with punctuation or newlines (staticcheck)
internal/tally/report.go:45:10: ST1005: error strings should not be capitalized (staticcheck)
internal/tally/report.go:63:6: func percent is unused (unused)
12 issues:
* errcheck: 1
* govet: 1
* revive: 4
* staticcheck: 5
* unused: 1
1
```

**Doze achados, todos no `report.go`.** O preset tirou as nove linhas do `errcheck` no `main.go` e no
`genlog`, incluindo o discutível `w.Flush`: um preset é uma troca, e esta é feita sabendo disso. O
revive acrescentou os quatro dele, e com `uniq-by-line: false` as duas mensagens de `ST1005` do
staticcheck voltam, ao lado do `error-strings` do revive na mesma linha. **Todo achado desta lista é um
que um revisor ia querer corrigido**, que é para isso que serve a configuração.

## `//nolint`, e o linter que o verifica

A diretiva do golangci-lint é `//nolint:LINTER // motivo`, no fim da linha que ela desculpa ou na linha
acima de uma declaração, onde cobre a declaração inteira. Um `//nolint` sem nome silencia todos os
linters naquela linha, e é a coisa mais fácil do mundo de digitar quando o build está vermelho. Eis
um, digitado na linha do bug real:

```
ana@vm:~/lint$ sed -i 's|0o644)$|& //nolint|' internal/tally/report.go
ana@vm:~/lint$ golangci-lint run ./internal/... | head -6
internal/tally/report.go:59:15: inline: Call of ioutil.ReadFile should be inlined (govet)
	data, err := ioutil.ReadFile(path)
	             ^
internal/tally/report.go:48:42: directive `//nolint` should mention specific linter such as `//nolint:my-linter` (nolintlint)
	os.WriteFile(path, []byte(text), 0o644) //nolint
	                                        ^
ana@vm:~/lint$ sed -i 's| //nolint$||; s|^func percent.*{$|& //nolint:unused // kept for the -percent flag of the next release|' internal/tally/report.go
ana@vm:~/lint$ golangci-lint run --output.text.print-issued-lines=false | tail -8
internal/tally/report.go:33:5: SA4003: every value of type uint is >= 0 (staticcheck)
internal/tally/report.go:45:10: ST1005: error strings should not end with punctuation or newlines (staticcheck)
internal/tally/report.go:45:10: ST1005: error strings should not be capitalized (staticcheck)
11 issues:
* errcheck: 1
* govet: 1
* revive: 4
* staticcheck: 5
```

**O achado do `errcheck` na linha 48 sumiu, e o `nolintlint` relatou a diretiva no lugar.** Sem o
`nolintlint`, o `//nolint` sem nome teria escondido o único achado deste módulo que perde dados, e nada
teria dito isso. Com `require-specific` e `require-explanation`, a única diretiva que passa é a que
nomeia o linter e diz por quê, como a segunda, na função que ninguém chama ainda. O `percent` saiu da
lista, e restam onze achados.

Uma diretiva serve para uma linha com um motivo que pertence ao lado do código. **Um padrão que se
repete pertence a `exclusions.rules`** no YAML, casado por caminho, linter ou texto da mensagem, onde
pode ser revisado como uma decisão em vez de achado como trinta comentários.
