---
title: Onde quebra
version: 1
---

A linha `registered [csv mean]` da seção 02 é a chave de todas as falhas desta seção. **Depois que
o `plugin.Open` retorna, o hospedeiro e o plugin são um programa só, e cada pacote que os dois
importam existe nele uma vez: a cópia do hospedeiro.** O código do plugin chama o `report` do
hospedeiro, o `tally` do hospedeiro e o runtime do hospedeiro. Por isso o runtime só carrega um
plugin se cada um desses pacotes em comum foi compilado exatamente como o do hospedeiro, e confere
isso no `Open`, pacote por pacote.

## Uma cópia de cada pacote

Quanto os dois têm em comum é uma pergunta que o `go list` responde. O `-deps` imprime um pacote e
tudo o que ele importa:

```
ana@vm:~/plugins$ go list -deps -buildmode=plugin ./plugins/csv | sort > plugin.deps
ana@vm:~/plugins$ go list -deps ./cmd/hits-plugin | sort > host.deps
ana@vm:~/plugins$ comm -12 plugin.deps host.deps | wc -l
66
ana@vm:~/plugins$ comm -23 plugin.deps host.deps
encoding/csv
example.com/hits/plugins/csv
example.com/hits/reporters/csv
ana@vm:~/plugins$ wc -l < plugin.deps; wc -l < host.deps
69
68
ana@vm:~/plugins$ nm -D --defined-only hits-plugin | wc -l
10406
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 362\" role=\"img\" aria-label=\"Dois painéis. O hospedeiro, hits-plugin, tem 68 pacotes: 64 da biblioteca padrão, incluindo o runtime, internal/tally, report, plugin e cmd/hits-plugin. O arquivo do plugin, csv.so, tem 69: suas próprias cópias dos mesmos 64 pacotes da biblioteca padrão, de internal/tally e de report, que as setas ligam às cópias do hospedeiro, e três pacotes que o hospedeiro não tem, encoding/csv, reporters/csv e plugins/csv, carregados do arquivo.\"><defs><marker id=\"pl-arrow\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"300\" height=\"310\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o hospedeiro, um programa</text><text x=\"170\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">hits-plugin</text><rect x=\"420\" y=\"40\" width=\"280\" height=\"310\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"560\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o plugin, um arquivo</text><text x=\"560\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">csv.so</text><rect x=\"40\" y=\"76\" width=\"260\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">64 pacotes da biblioteca padrão,</text><text x=\"170\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o runtime entre eles</text><rect x=\"40\" y=\"132\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">internal/tally</text><rect x=\"40\" y=\"172\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">report</text><rect x=\"40\" y=\"222\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">plugin</text><rect x=\"40\" y=\"262\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cmd/hits-plugin</text><text x=\"170\" y=\"326\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">68 pacotes</text><rect x=\"440\" y=\"76\" width=\"240\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"560\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sua própria cópia dos mesmos 64</text><path d=\"M438 99.0 H304\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pl-arrow)\"></path><rect x=\"440\" y=\"132\" width=\"240\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"560\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sua própria cópia de internal/tally</text><path d=\"M438 147.0 H304\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pl-arrow)\"></path><rect x=\"440\" y=\"172\" width=\"240\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"560\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sua própria cópia de report</text><path d=\"M438 187.0 H304\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pl-arrow)\"></path><rect x=\"440\" y=\"232\" width=\"240\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">encoding/csv</text><rect x=\"440\" y=\"262\" width=\"240\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"275\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">reporters/csv</text><rect x=\"440\" y=\"292\" width=\"240\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">plugins/csv</text><text x=\"560\" y=\"334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">69 pacotes: 66 em comum, 3 novos</text><text x=\"370\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">ligados à cópia</text><text x=\"370\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">do hospedeiro</text><text x=\"560\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">carregados do arquivo</text></svg>", "caption": "Depois do plugin.Open há uma cópia de cada pacote no processo. Os 66 que o csv.so tem em comum com o hospedeiro ficam ligados às cópias do hospedeiro, e os hashes precisam bater, então só três pacotes vêm do arquivo."}
```

**Sessenta e seis dos sessenta e nove pacotes do `csv.so` já estão no hospedeiro**, o runtime entre
eles. Na carga, o ligador dinâmico liga toda referência a eles às definições do hospedeiro, e é por
isso que o hospedeiro exporta 10.406 símbolos para um plugin se ligar. As cópias próprias do plugin
desses 66 são peso morto no arquivo: as chamadas dele vão para as do hospedeiro. Cada pacote leva um
hash do que a compilação produziu, e o runtime compara o hash do plugin com o do hospedeiro para
cada pacote em comum antes de rodar um único `init`. Tudo o que vem abaixo é essa comparação
falhando.

## Um pacote em comum mudou

O jeito comum de quebrar um plugin é melhorar o hospedeiro. Um método novo em `Summary`, num arquivo
próprio, `internal/tally/errors.go`:

```go
package tally

// Errors is the number of requests that ended with a status of 500 or more.
func (s Summary) Errors() int {
	n := 0
	for status, count := range s.ByStatus {
		if status >= 500 {
			n += count
		}
	}
	return n
}
```

O hospedeiro é recompilado e os plugins não, que é o que acontece quando os plugins foram compilados
por outra pessoa, no mês passado:

```
ana@vm:~/plugins$ go build -o hits-plugin ./cmd/hits-plugin
ana@vm:~/plugins$ ./hits-plugin access.log csv.so; echo $?
hits-plugin: plugin.Open("csv"): plugin was built with a different version of package example.com/hits/internal/tally
1
ana@vm:~/plugins$ go build -buildmode=plugin -o csv.so ./plugins/csv && go build -buildmode=plugin -o mean.so ./plugins/mean
ana@vm:~/plugins$ ./hits-plugin access.log csv.so mean.so | tail -1
hits-plugin: registered [csv mean]
20000 requests, mean 200ms
```

**Um método a mais num pacote que o reporter de CSV nunca chama, e o plugin se recusa a carregar.**
A mensagem cita o pacote, `example.com/hits/internal/tally`, e está certa: o `csv.so` foi compilado
contra um `tally` sem `Errors`. Recompilar os dois plugins a partir do mesmo código é a única
correção, e depois dela os dois carregam de novo. É a regra que o `go doc plugin` enuncia sem
rodeios: na prática, a aplicação e seus plugins precisam ser todos compilados juntos, por uma pessoa
ou por uma parte de um sistema.

## O mesmo código, outras flags

O hash cobre o modo como um pacote foi compilado, então o mesmo código compilado de dois jeitos
conta como duas versões. O build de release de um hospedeiro costuma levar `-trimpath`, que as
lições 17 e 18 usam. Um job de CI pode testá-lo com `-race`, da lição 15. E o autor de um plugin
pode simplesmente estar uma versão de correção do Go à frente:

```
ana@vm:~/plugins$ go build -trimpath -o hits-trim ./cmd/hits-plugin && ./hits-trim access.log csv.so
hits-plugin: plugin.Open("csv"): plugin was built with a different version of package internal/goarch
ana@vm:~/plugins$ go build -race -o hits-race ./cmd/hits-plugin && ./hits-race access.log csv.so
hits-plugin: plugin.Open("csv"): plugin was built with a different version of package internal/runtime/sys
ana@vm:~/plugins$ GOTOOLCHAIN=go1.27.2 go version
go version go1.27.2 linux/amd64
ana@vm:~/plugins$ GOTOOLCHAIN=go1.27.2 go build -buildmode=plugin -o csv-next.so ./plugins/csv
ana@vm:~/plugins$ ./hits-plugin access.log csv-next.so
hits-plugin: plugin.Open("csv-next"): plugin was built with a different version of package internal/goarch
```

**Nenhuma das três mensagens cita a causa real.** O primeiro pacote cujo hash difere fica no fundo
do runtime, `internal/goarch` ou `internal/runtime/sys`. Quem lê
`different version of package internal/goarch` depois de atualizar do Go 1.27.1 para o 1.27.2
precisa conhecer esta seção para entender. O detector de corrida é um problema mesmo quando os dois
lados concordam: o `go doc plugin` avisa que ele suporta mal os plugins e pode deixar passar até
corridas simples.

## Nada sai

O `plugin.Plugin` tem `Lookup` e mais nada:

```
ana@vm:~/plugins$ go doc plugin.Plugin
package plugin // import "plugin"

type Plugin struct {
	// Has unexported fields.
}
    Plugin is a loaded Go plugin.

func Open(path string) (*Plugin, error)
func (p *Plugin) Lookup(symName string) (Symbol, error)
ana@vm:~/plugins$ cp csv.so csv-copy.so && cmp csv.so csv-copy.so && echo identical
identical
ana@vm:~/plugins$ ./hits-plugin access.log csv.so csv-copy.so | wc -l
hits-plugin: plugin.Open("csv-copy"): plugin already loaded
11
```

**Não há `Close`, e não haverá descarregamento**: a documentação diz que um plugin não pode ser
fechado. E um segundo arquivo com o mesmo plugin não carrega ao lado do primeiro. O `csv-copy.so` é
uma cópia byte a byte do `csv.so`, e o runtime o recusa porque um plugin é identificado pelo caminho
do pacote, `example.com/hits/plugins/csv`, e esse caminho já está no processo. Um `csv.so`
recompilado com um bug corrigido é recusado do mesmo jeito. **O único jeito de rodar uma versão nova
de um plugin é um processo novo**, que é justamente o que um sistema de plugins costuma existir para
evitar.

## Catorze plataformas, e só com cgo

A carga passa pela biblioteca C, então compilar um plugin exige cgo, e carregar um também:

```
ana@vm:~/plugins$ CGO_ENABLED=0 go build -buildmode=plugin -o x.so ./plugins/csv
-buildmode=plugin requires external (cgo) linking, but cgo is not enabled
ana@vm:~/plugins$ GOOS=windows go build -buildmode=plugin -o x.dll ./plugins/csv
-buildmode=plugin not supported on windows/amd64
ana@vm:~/plugins$ GOOS=darwin GOARCH=arm64 go build -buildmode=plugin -o x.so ./plugins/csv
-buildmode=plugin requires external (cgo) linking, but cgo is not enabled
ana@vm:~/plugins$ CGO_ENABLED=0 go build -o hits-nocgo ./cmd/hits-plugin && ./hits-nocgo access.log csv.so
hits-plugin: plugin: not implemented
ana@vm:~/plugins$ go tool dist list | wc -l
47
```

Quatro recusas de tipos diferentes. Um plugin não pode ser compilado com o cgo desligado, nem para
Windows de forma alguma. A compilação cruzada de um plugin para Mac falha com a mensagem do cgo,
porque o comando go desliga o cgo por padrão quando faz compilação cruzada, e ligá-lo de volta exige
um compilador C para o alvo. A última recusa é a traiçoeira: **um hospedeiro compilado com
`CGO_ENABLED=0` compila sem reclamar, e o `plugin.Open` falha quando ele roda**, com
`plugin: not implemented`. A própria tabela do toolchain de modos de build suportados, em
`src/internal/platform/supported.go`, permite plugins em 14 das 47 plataformas daquela lista: nove
arquiteturas Linux, duas Android, duas macOS e FreeBSD em amd64.
