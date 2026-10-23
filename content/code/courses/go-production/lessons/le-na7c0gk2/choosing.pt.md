---
title: Escolhendo, com os números
version: 1
---

Três jeitos de acrescentar um reporter, e cada um foi descrito com o seu custo. Esta seção põe
números nos custos que dá para medir, a velocidade de uma chamada e o que precisa ser distribuído, e
depois coloca os três lado a lado. **A única vantagem real do plugin é a velocidade, e ele a divide
com o reporter compilado dentro**: os dois são uma chamada comum por uma interface, no mesmo
processo.

## O custo de uma chamada

Um benchmark de uma chamada ao reporter da média, feita dos três jeitos. Ele carrega o `mean.so` e
roda o `mean-exec` a partir do diretório raiz do módulo, então os dois precisam estar compilados
antes, como ficaram nas seções 03 e 04. O arquivo é `bench/bench_test.go`:

```go
// Package bench measures one call to the mean reporter, made three ways.
package bench

import (
	"bytes"
	"encoding/json"
	"io"
	"os/exec"
	"plugin"
	"testing"
	"time"

	"example.com/hits/internal/tally"
	"example.com/hits/report"
	"example.com/hits/reporters/mean"
)

var s = tally.Summary{
	Lines:    2,
	ByStatus: map[int]int{200: 1, 404: 1},
	ByPath:   map[string]int{"/": 1, "/login": 1},
	Total:    12 * time.Millisecond,
}

// A reporter compiled into the program, called through the interface.
func BenchmarkCompiledIn(b *testing.B) {
	var r report.Reporter = mean.Reporter{}
	for b.Loop() {
		r.Report(s, io.Discard)
	}
}

// The same reporter, loaded from mean.so.
func BenchmarkPlugin(b *testing.B) {
	p, err := plugin.Open("../mean.so")
	if err != nil {
		b.Fatal(err)
	}
	sym, err := p.Lookup("Reporter")
	if err != nil {
		b.Fatal(err)
	}
	r := sym.(func() report.Reporter)()
	for b.Loop() {
		r.Report(s, io.Discard)
	}
}

// The same reporter as a program: one process per call.
func BenchmarkProcess(b *testing.B) {
	in, err := json.Marshal(map[string]any{"protocol": 1, "summary": s})
	if err != nil {
		b.Fatal(err)
	}
	for b.Loop() {
		cmd := exec.Command("../mean-exec")
		cmd.Stdin = bytes.NewReader(in)
		cmd.Stdout = io.Discard
		if err := cmd.Run(); err != nil {
			b.Fatal(err)
		}
	}
}
```

```
ana@vm:~/plugins$ go test -bench . -benchmem ./bench
goos: linux
goarch: amd64
pkg: example.com/hits/bench
cpu: Intel(R) Xeon(R) Processor
BenchmarkCompiledIn-4   	 9036969	       132.0 ns/op	      16 B/op	       2 allocs/op
BenchmarkPlugin-4       	 8842059	       136.1 ns/op	      16 B/op	       2 allocs/op
BenchmarkProcess-4      	     710	   1581082 ns/op	    5633 B/op	      53 allocs/op
PASS
ok  	example.com/hits/bench	3.528s
```

**O plugin custa o que o reporter compilado dentro custa**: 136,1 nanossegundos contra 132,0, uma
diferença de três por cento que outra execução pode zerar ou inverter. Depois do `Lookup`, o
`Report` de um plugin é uma chamada de método por interface como qualquer outra. O processo custa
cerca de **1,6 milissegundo por chamada, umas doze mil vezes mais**, e quase nada disso é o
reporter. É o `fork` e o `exec`, um runtime Go iniciando num processo novo e o JSON passando por um
pipe, com 53 alocações só do lado do hospedeiro. A regra que sai disso é sobre a frequência com que
um reporter é chamado. O `hits` chama um por execução, depois de contar 20.000 linhas, e 1,6 ms não
é nada perto disso. Um reporter chamado uma vez por linha de log transformaria 20.000 linhas em
cerca de 30 segundos de processos iniciando, e ali só serve uma chamada dentro do processo, ou um
processo filho mantido rodando.

## O que precisa ser distribuído

```
ana@vm:~/plugins$ stat -c "%s bytes  %n" hits-static hits-plugin csv.so mean.so hits-exec mean-exec
2689276 bytes  hits-static
4901728 bytes  hits-plugin
3725312 bytes  csv.so
4678960 bytes  mean.so
4316716 bytes  hits-exec
3897476 bytes  mean-exec
ana@vm:~/plugins$ readelf -d hits-static | grep -c NEEDED
0
```

O hospedeiro com os reporters compilados dentro, os dois, tem **2.689.276 bytes e não precisa de
nada do sistema**. O hospedeiro de plugins tem 4.901.728 bytes antes de um único reporter, mais 3,7
e 4,7 MB de arquivos `.so` que só funcionam ao lado do hospedeiro exato com que foram compilados. E
a lição 18 pôs o `hits` em `gcr.io/distroless/static-debian12`, uma imagem sem biblioteca C, que é a
imagem feita para um binário Go estático:

```
ana@vm:~/plugins$ podman run --rm --network=none -v "$PWD":/w -w /w gcr.io/distroless/static-debian12:nonroot ./hits-plugin access.log csv.so; echo $?
exec ./hits-plugin: no such file or directory
255
ana@vm:~/plugins$ readelf -l hits-plugin | grep interpreter
      [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
ana@vm:~/plugins$ podman run --rm -i --network=none -v "$PWD":/w -w /w gcr.io/distroless/static-debian12:nonroot ./hits-static -r mean < access.log
20000 requests, mean 200ms
```

`no such file or directory` cita um arquivo que está lá. O que falta é o interpretador do programa,
`/lib64/ld-linux-x86-64.so.2`, o carregador que um programa ligado dinamicamente pede ao kernel para
rodar primeiro, e a imagem estática não tem nenhum. **Um hospedeiro que carrega plugins precisa de
uma imagem base com biblioteca C**, que é uma imagem maior, com mais coisa para corrigir. O
hospedeiro estático rodou na imagem que a lição 18 escolheu, sem mudança. O contêiner rodou com
`--network=none` porque este laboratório não tem dispositivo de rede para contêineres; nenhum destes
programas usa rede.

## Lado a lado

| | plugin Go | programa separado | compilado dentro |
|---|---|---|---|
| uma chamada | cerca de 130 ns, uma chamada por interface | cerca de 1,6 ms, um processo iniciando | cerca de 130 ns, uma chamada por interface |
| o que é distribuído | um hospedeiro ligado dinamicamente e um `.so` por reporter, do mesmo build | o hospedeiro, e cada reporter como programa em qualquer linguagem | um binário estático |
| um reporter novo | recompilar o plugin com o toolchain, as flags e os pacotes em comum exatos do hospedeiro | instalar o programa; nada é recompilado | acrescentar um import e recompilar |
| uma falha num reporter | derruba o hospedeiro | custa um relatório e um código de saída | derruba o hospedeiro |
| versionamento | cada pacote em comum precisa bater, conferido no `Open` | o número do protocolo, conferido pelo reporter | o compilador confere tudo, no build |
| uma versão nova com o programa rodando | recusada, `plugin already loaded` | a próxima chamada inicia o programa novo | impossível; reiniciar |
| plataformas | 14 de 47, cgo obrigatório | todas em que o `os/exec` roda | todas para as quais o Go compila |

**Leia a tabela pela exigência, não pela coluna.** Se os reporters vêm de desconhecidos, são
escritos em outras linguagens ou precisam ser trocados com o hospedeiro rodando, só o programa separado
atende à exigência, e a primeira linha é o preço. Se a equipe que compila o
hospedeiro também compila os reporters, a coluna do compilado dentro é tão rápida quanto o plugin e
melhor em todas as outras linhas. A coluna do plugin não é a melhor em linha nenhuma. É a única que
é rápida, carregada em tempo de execução e escrita em Go ao mesmo tempo. É um caso estreito:
uma equipe, um build, um toolchain e um motivo para manter um reporter fora do binário que
sobreviva à seção 03.

## O fim do curso

O `hits` começou na lição 1 como um CLI só com a biblioteca padrão, com dois subcomandos, duas
saídas e um código de saída, e ganhou três outras linhas de comando nas lições 2 a 4. As lições 5 a
11 puseram o toolchain em volta dele: formatação, `vet`, linters, uma varredura de vulnerabilidades,
código gerado e build tags. Nas lições 12 a 14 o `Parse` dele foi perfilado, lido num flame graph e
visto num trace, para que o que era lento fosse medido antes de qualquer mudança. As lições 16 a 18
o compilaram para outras máquinas, o deixaram menor e o distribuíram como imagem assinada. As lições
19 a 24 olharam por baixo da linguagem: a memória que ele usa, onde as variáveis dele moram, e as
quatro saídas de emergência, reflexão, `unsafe`, cgo e plugins, cada uma ensinada com a conta que
vem junto.
