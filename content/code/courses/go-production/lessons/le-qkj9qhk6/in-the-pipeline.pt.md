---
title: O detector no pipeline
version: 1
---

As seções 02 a 04 dão ao pipeline seus três fatos. Uma corrida passa por todas as checagens menos o
`-race`; o detector só acusa o que a execução exercitou; e ele custa várias vezes o tempo e a memória
de um build comum. **Então ele roda em toda mudança, sobre testes escritos para fazer goroutines se
encontrarem, e nunca no binário que você entrega.** Entre os dois cabe mais um lugar que vale ter,
uma execução de homologação de um build com detector, porque o tráfego real passa por caminhos em
que nenhum teste pensou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Quatro etapas de um pipeline. Um, pull request: go test -race -count=1 -cpu 1,4 em toda mudança, antes do merge. Dois, push na main: os mesmos testes no resultado do merge, e go build -race para o binário de homologação. Três, homologação: o pcount com detector roda tráfego real com o log_path do GORACE apontando para um diretório, porque o tráfego real passa por caminhos que nenhum teste percorreu. Quatro, release: um go build comum, então o que o usuário roda nunca leva o detector.\"><defs><marker id=\"l15pipe-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"100.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1 pull request</text><rect x=\"20\" y=\"38\" width=\"160\" height=\"78\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">go test -race</text><text x=\"100.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">-count=1 -cpu 1,4 ./...</text><text x=\"100.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">com -race</text><text x=\"100.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">toda mudança, antes</text><text x=\"100.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">do merge</text><path d=\"M182 77 H194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15pipe-paper-dim)\"></path><text x=\"276.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2 push na main</text><rect x=\"196\" y=\"38\" width=\"160\" height=\"78\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">go test -race ...</text><text x=\"276.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">go build -race</text><text x=\"276.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">com -race</text><text x=\"276.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o resultado do merge e</text><text x=\"276.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o binário de homologação</text><path d=\"M358 77 H370\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15pipe-paper-dim)\"></path><text x=\"452.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3 homologação</text><rect x=\"372\" y=\"38\" width=\"160\" height=\"78\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"452.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">./pcount-race</text><text x=\"452.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GORACE=log_path=dir/race</text><text x=\"452.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">com -race</text><text x=\"452.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tráfego real passa por</text><text x=\"452.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">caminhos sem teste</text><path d=\"M534 77 H546\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15pipe-paper-dim)\"></path><text x=\"628.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4 release</text><rect x=\"548\" y=\"38\" width=\"160\" height=\"78\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"628.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">go build</text><text x=\"628.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">-o pcount ./tools/pcount</text><text x=\"628.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">comum</text><text x=\"628.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que o usuário roda</text><text x=\"628.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nunca leva o detector</text></svg>", "caption": "Onde o detector roda: em toda mudança, no resultado do merge e na homologação. O build de release é o único lugar onde ele não entra.", "same": ["1 pull request", "4 release"]}
```

## O workflow

No GitHub Actions o job começa com os mesmos dois passos da checagem de formatação da lição 6,
baixando o código e instalando o Go que o `go.mod` cita, e roda os dois comandos do detector depois
deles. `.github/workflows/race.yml`:

```yaml
name: race
on:
  push:
    branches: [main]
  pull_request:
jobs:
  race:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-go@v7
        with:
          go-version-file: go.mod
      - name: every test, with the race detector
        env:
          CGO_ENABLED: "1"
        run: go test -race -count=1 -cpu 1,4 ./...
      - name: pcount with the race detector, for the staging run
        env:
          CGO_ENABLED: "1"
        run: go build -race -o pcount-race ./tools/pcount
```

**Este arquivo não foi executado**: o laboratório não tem GitHub. As duas linhas `run:` foram, com o
mesmo ambiente, no fim desta seção. As duas actions são as que as lições 6 e 9 usam, nas mesmas
versões. Cada linha do arquivo está lá por um motivo que esta lição mediu:

| linha | por quê |
|---|---|
| `pull_request:` | uma corrida achada antes do merge é um check vermelho numa mudança; depois do merge, é o teste instável de outra pessoa |
| `push:` na `main` | o resultado do merge, que nenhum pull request testou exatamente, ganha uma execução própria |
| `CGO_ENABLED: "1"` | seção 04: um job que define `CGO_ENABLED=0` para builds estáticos de release recusaria o `-race` |
| `-count=1` | roda todos os testes mesmo quando uma execução idêntica já passou, como a próxima transcrição mostra |
| `-cpu 1,4` | seção 03: código que se dimensiona pelo `GOMAXPROCS` passa pelo caminho concorrente em qualquer máquina em que o job caia |
| `go build -race` | o binário da execução de homologação, compilado pelo mesmo job que o testou |

O preço do passo é a conta da seção 04: a suíte de testes inteira várias vezes mais lenta, mais um
segundo por pacote na saída, e o `-cpu 1,4` roda cada teste duas vezes. Numa suíte que leva um
minuto sem detector, isso dá minutos, não segundos, o que é um motivo para dar a ele um job próprio,
rodando ao lado dos testes comuns em vez de depois deles. **O que ninguém deve fazer é rodá-lo só de
madrugada**: uma corrida achada com um dia de atraso chega misturada com todas as mudanças daquele
dia.

## Por que `-count=1`

O `go test` guarda em cache o resultado de um pacote cujo binário de teste e cujas flags ele já viu
passar. A execução de laboratório abaixo usa um cache de build vazio, para que o primeiro comando
rode de verdade:

```
ana@vm:~/race-hits$ go test -race ./...; go test -race ./...
ok  	example.com/hits	1.018s
ok  	example.com/hits/internal/tally	1.011s
?   	example.com/hits/tools/genlog	[no test files]
?   	example.com/hits/tools/pcount	[no test files]
ok  	example.com/hits	(cached)
ok  	example.com/hits/internal/tally	(cached)
?   	example.com/hits/tools/genlog	[no test files]
?   	example.com/hits/tools/pcount	[no test files]
```

As linhas do segundo comando dizem `(cached)`: nada rodou, e a aprovação antiga foi impressa de novo.
**O `actions/setup-go` restaura o cache de build do Go entre execuções por padrão**, segundo o README
dele, e o cache de build é onde esses resultados ficam. Rodar de novo um job num commit que já passou
poderia então responder com uma execução em que a corrida não aconteceu, o que é um "rodar até ficar
verde" que ninguém nem pediu. O `go help test` chama o `-count=1` de "the idiomatic way to disable
test caching explicitly".

## Quatro opções para as execuções que importam

As opções de execução do detector chegam pelo `GORACE`, e `GORACE=help=1` faz um binário com detector
imprimir todas elas, com os valores atuais, antes de fazer seu trabalho. Pergunte ao `pcount-race`, o
binário compilado na seção 02. **Um binário não muda quando o código-fonte muda**, então este ainda
tem a corrida que a correção removeu:

```
ana@vm:~/race-hits$ GORACE=help=1 ./pcount-race < /dev/null 2>&1 | grep -A1 -E "^\s(halt_on_error|history_size|log_path|exitcode)$"
	halt_on_error
		- Exit after first reported error. (Current Value: false)
--
	history_size
		- Per-thread history size, controls how many extra previous memory accesses are remembered per thread. (Current Value: 0x0)
--
	log_path
		- Write logs to "log_path.pid". The special values are "stdout" and "stderr". If unspecified, defaults to "stderr". (Current Value: <null>)
--
	exitcode
		- Override the program exit status if the tool found an error (Current Value: 66)
```

Cada uma responde a uma pergunta que um pipeline faz:

| opção | padrão | para que serve |
|---|---|---|
| `halt_on_error` | desligada | parar no primeiro relatório: saída mais curta para ler à mão, como a seção 02 fez, e todas as corridas seguintes da mesma execução escondidas |
| `exitcode` | 66 | o status com que sai uma execução que teve corrida, para que um script distinga "uma corrida" de "uma falha" |
| `log_path` | saída de erro | gravar os relatórios num arquivo chamado `log_path.PID`, onde um processo de longa duração os guarda |
| `history_size` | 0 | quantos acessos anteriores extras cada goroutine lembra, nas palavras do texto de ajuda; deixe em 0, a menos que um processo de homologação de longa duração precise de uma memória mais longa |

Numa execução de testes, deixe `halt_on_error` desligada: um binário de teste que para no primeiro
relatório perde o resultado de todos os testes depois dele, e o CI deve mostrar todas as corridas numa
execução. O `exitcode` importa quando 66 já significa outra coisa para um script. Um binário de teste o ignora. Um que acha uma corrida falha com status 1 mesmo sob `GORACE=exitcode=0`, porque o pacote
`testing` percebe o relatório por conta própria e reprova o teste, com a linha `race detected during
execution of test` que a seção 03 mostrou. As outras duas são para a homologação:

```
ana@vm:~/race-hits$ GORACE=exitcode=3 ./pcount-race < access.log > /dev/null 2>&1; echo $?
3
ana@vm:~/race-hits$ mkdir -p racelogs && GORACE=log_path=racelogs/race ./pcount-race < access.log; echo $?
20000 lines, 1h6m37.778s in total
66
ana@vm:~/race-hits$ ls racelogs && grep -c "WARNING: DATA RACE" racelogs/race.*
race.17789
4
```

O `exitcode=3` trocou 66 por 3. Com `log_path`, a saída padrão continuou levando a resposta do
programa enquanto os quatro relatórios iam para `racelogs/race.17789`, com o nome do id do processo,
para que vários processos dividam um diretório sem sobrescrever uns aos outros. E dessa vez a
resposta estava certa, 20.000 linhas e `1h6m37.778s`: **uma execução que por acaso imprime o número
certo ainda teve corrida, ainda gravou quatro relatórios e ainda saiu com 66.** O detector julga o que
aconteceu na execução, não se a saída saiu correta.

## Uma execução de homologação

Um build com detector atendendo tráfego de homologação vê o que os testes não viram: entradas reais,
concorrência real, os caminhos da seção 03 por onde nenhum teste passou. Ele roda várias vezes mais
devagar e com várias vezes a memória, então seu lugar é numa máquina de homologação ou numa pequena
parte das instâncias, nunca no release. Aqui estão as duas linhas `run:` do workflow sobre o código
corrigido, com o `CGO_ENABLED` do job, e depois a execução de homologação do que elas compilaram:

```
ana@vm:~/race-hits$ CGO_ENABLED=1 go test -race -count=1 -cpu 1,4 ./...
ok  	example.com/hits	1.012s
ok  	example.com/hits/internal/tally	1.013s
?   	example.com/hits/tools/genlog	[no test files]
?   	example.com/hits/tools/pcount	[no test files]
ana@vm:~/race-hits$ CGO_ENABLED=1 go build -race -o pcount-race ./tools/pcount
ana@vm:~/race-hits$ mkdir -p racelogs && GORACE=log_path=racelogs/race ./pcount-race < access.log; echo $?; ls racelogs | wc -l
20000 lines, 1h6m37.778s in total
0
0
```

Os testes rodaram duas vezes cada, uma por valor de `-cpu`, sem nada em cache e sem nada acusado.
**Uma execução limpa é uma execução que não deixa arquivo**: 20.000 linhas, status 0 e `racelogs`
vazio. Numa máquina de homologação de verdade, o `log_path` apontaria para um diretório que o coletor
de logs recolhe, e um alerta para qualquer arquivo novo ali é todo o monitoramento de que um build com
detector precisa.

## O que fazer com um relatório

Um relatório não é um palpite. São dois acessos que o detector viu acontecer, com suas linhas, e nada
que os ordenasse. Três regras saem disso e da seção 03.

**Nunca rode o job de novo até ficar verde.** Uma reexecução verde é uma execução que não passou pelo
caminho com corrida, ou não passou por ele com duas goroutines, e a seção 03 mostrou com que
facilidade isso acontece; ela não diz nada sobre o código. Pelo mesmo motivo, o job não deve ter nova
tentativa automática.

Também nunca marque o teste como instável e siga em frente. O teste é a única coisa no pipeline que
fez as goroutines se encontrarem, e desligá-lo remove a única testemunha.

**Corrija, ou reverta a mudança que trouxe a corrida.** O relatório cita as duas linhas, como a seção
02 o leu, e a lição 16 de `go-concurrency` tem os quatro tipos de correção. Depois o código corrigido
passa pelo mesmo passo, com `-count` e `-cpu`, e sai limpo.

Uma corrida numa dependência continua sendo uma corrida no seu programa, porque roda no seu processo.
Atualize para uma versão sem ela se a correção existir, informe o projeto se não existir, e mantenha o
teste que a encontrou.
