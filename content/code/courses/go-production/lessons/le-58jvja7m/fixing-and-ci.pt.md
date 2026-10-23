---
title: Corrigindo um achado, e rodando a verificação para sempre
version: 1
---

Um achado tem uma de três correções, e o relatório diz qual. **Um módulo que você exige ganha uma
versão mais nova com `go get`. A biblioteca padrão ganha um Go mais novo. E um módulo que chega por
outro módulo aceita qualquer das duas.** Nenhuma delas é uma edição no seu próprio código, e é por
isso que uma varredura de vulnerabilidades é barata de atender: a maioria dos achados fecha com um
número de versão e uma nova rodada dos testes.

## Quem trouxe o módulo

Num módulo real, a dependência ruim pode ser uma que você nunca pediu. `go mod why -m` imprime a
cadeia mais curta de imports dos seus pacotes até o módulo, e `go list -m -u` diz que versões mais
novas existem:

```
ana@vm:~/langs$ go mod why -m golang.org/x/text
# golang.org/x/text
example.com/langs/accept
golang.org/x/text/language
```

```
ana@vm:~/langs$ go list -m -u golang.org/x/text
golang.org/x/text v0.3.7 [v0.43.0]
```

Aqui a cadeia tem duas linhas: o `accept` importa `language` diretamente. **Quando a cadeia passa por
outro módulo, foi esse módulo que escolheu a versão**, e você tem dois movimentos. Atualizá-lo, se as
versões mais novas dele pedem uma versão corrigida. Ou exigir você mesmo a versão corrigida com
`go get`, o que funciona num módulo que você só usa indiretamente: a seleção de versão mínima do Go
escolhe a maior versão que alguém no build pede. O colchete da segunda linha é a versão mais nova no
proxy de módulos, v0.43.0, quarenta versões menores adiante.

## A correção mínima, e a sensata

`Fixed in` citou a v0.3.8. Essa é a menor mudança que libera a barreira:

```
ana@vm:~/langs$ go get golang.org/x/text@v0.3.8
go: upgraded golang.org/x/text v0.3.7 => v0.3.8
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb ./...; echo $?
=== Symbol Results ===

No vulnerabilities found.

Your code is affected by 0 vulnerabilities.
This scan also found 1 vulnerability in packages you import and 14
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.
0
```

Os dois programas passam agora, já que `./...` cobre os dois, e o status de saída é 0. As 14 do nível
de módulo continuam lá, e duas delas são do próprio `golang.org/x/text`, corrigidas só na v0.39.0 e
na v0.41.0. **A correção mínima é a certa para um hotfix que precisa sair hoje à noite com o mínimo de
mudança para revisar.** No caso comum, pegue a versão mais nova e deixe os testes dizerem se algo
quebrou:

```
ana@vm:~/langs$ go get golang.org/x/text@latest && go mod tidy && cat go.mod
go: upgraded golang.org/x/text v0.3.8 => v0.43.0
module example.com/langs

go 1.27.1

require golang.org/x/text v0.43.0
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb ./...; echo $?
=== Symbol Results ===

No vulnerabilities found.

Your code is affected by 0 vulnerabilities.
This scan also found 1 vulnerability in packages you import and 12
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.
0
```

Catorze viraram 12, e **todas as 12 são da biblioteca padrão**. As duas correções de
`golang.org/x/text` saíram na v0.39.0 e na v0.41.0, não na velha linha v0.3, e cada mês de espera
deixa o salto final maior. Estes dois programas não têm testes para rodar; os seus rodariam
`go test ./...`, como as lições 25 e 26 do `go-concurrency` os escreveram, antes de a mudança ir para
qualquer lugar.

**Uma correção no `go.mod` não corrige nada que já esteja rodando.** O binário compilado na seção 04
ainda carrega o módulo antigo, e a varredura do binário diz isso até ele ser recompilado:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -mode binary accept-bin | grep -E 'Found in|Your code'; echo ${PIPESTATUS[0]}
    Found in: golang.org/x/text@v0.3.7
Your code is affected by 1 vulnerability from 1 module.
3
ana@vm:~/langs$ go build -o accept-bin ./accept
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -mode binary accept-bin | grep 'Your code'; echo ${PIPESTATUS[0]}
Your code is affected by 0 vulnerabilities.
0
```

O achado fecha quando o binário novo substitui o antigo em todo lugar onde ele roda. As lições 16 a
18 tratam de compilar e distribuir esse binário.

## A biblioteca padrão se corrige com um Go mais novo

O `hits` da lição 1 não tem dependências, e mesmo assim tinha 13 entradas nos níveis de módulo e de
pacote na seção 04. Todas citam a mesma correção:

```
ana@vm:~/vuln-hits$ govulncheck -db file:///home/ana/vulndb -show verbose ./... | grep 'Fixed in' | sort | uniq -c
      1     Fixed in: os@go1.27.2
     12     Fixed in: stdlib@go1.27.2
```

**A biblioteca padrão tem a versão do toolchain**, então não existe `go get` para ela: a correção é o
Go 1.27.2, a próxima versão de patch. As versões de patch do Go trazem correções de segurança e de
bugs graves, sem mudança na linguagem, o que as torna baratas de adotar. O comando go consegue buscar
uma versão no proxy de módulos e rodá-la para um único comando, com `GOTOOLCHAIN`, o que basta para
ver o resultado sem trocar o Go do laboratório:

```
ana@vm:~/vuln-hits$ GOTOOLCHAIN=go1.27.2 go version
go version go1.27.2 linux/amd64
ana@vm:~/vuln-hits$ GOTOOLCHAIN=go1.27.2 govulncheck -db file:///home/ana/vulndb ./...; echo $?
No vulnerabilities found.
0
ana@vm:~/langs$ GOTOOLCHAIN=go1.27.2 govulncheck -db file:///home/ana/vulndb ./...; echo $?
No vulnerabilities found.
0
```

Nem uma linha de contexto desta vez: toda entrada era sobre o Go 1.27.1, e com o 1.27.2 não sobra
nada em nível nenhum. Isso funciona porque o `govulncheck` pergunta ao comando go do `PATH` qual é a
versão dele, a primeira linha de `-version` na seção 02, e a variável muda a resposta. **Para adotar
de fato a correção, instale a nova versão do jeito que a lição 3 do `go` instalou esta e recompile
todos os binários**; num job de CI, suba a versão que o job instala. Este curso fica na 1.27.1 para
que toda transcrição dele venha do mesmo compilador.

## No pipeline, e com agendamento

A verificação tem lugar no CI, ao lado da verificação de formatação da lição 6 e dos linters da lição
8. Um job do GitHub Actions, `.github/workflows/vuln.yml`:

```yaml
name: vuln
on:
  push:
  pull_request:
  schedule:
    - cron: "17 6 * * *"
jobs:
  govulncheck:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-go@v7
        with:
          go-version-file: go.mod
      - run: go run golang.org/x/vuln/cmd/govulncheck@v1.9.0 ./...
```

**Este arquivo não foi rodado**: o laboratório não tem GitHub. A última linha dele foi rodada, contra
o banco do laboratório, em `~/langs` depois da atualização:

```
ana@vm:~/langs$ go run golang.org/x/vuln/cmd/govulncheck@v1.9.0 -db file:///home/ana/vulndb ./... | tail -n 5; echo ${PIPESTATUS[0]}
Your code is affected by 0 vulnerabilities.
This scan also found 1 vulnerability in packages you import and 12
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.
0
```

`go run` com uma versão compila a versão fixada e a roda, sem passo de `go install` e sem `PATH` para
arrumar, e o job falha exatamente quando o relatório em texto sai com 3. `go-version-file` tira a
versão do Go do `go.mod`, então o job julga a biblioteca padrão com que você compila. As duas actions
são as que o job de formatação da lição 6 usa, nas mesmas versões.

Os gatilhos `push` e `pull_request` pegam a mudança que acrescenta uma chamada vulnerável. **O
gatilho `schedule` pega a outra metade: o banco muda enquanto o seu código não muda.** Um commit que
passou na segunda pode falhar na quinta sem que ninguém mexa nele, porque na quarta alguém publicou
uma entrada para uma função que ele sempre chamou. Sem o agendamento, esse achado espera o próximo
pull request sem relação, que então falha por um motivo que o autor não causou. A linha cron roda o
job uma vez por dia, às 06:17 UTC; o GitHub lê agendamentos em UTC e documenta o começo de cada hora
como o momento em que execuções agendadas mais atrasam.

Uma coisa que o `govulncheck` não tem é um jeito de marcar um achado como aceito. A documentação dele
lista essa falta entre as limitações. **Um achado de nível de símbolo fica vermelho até a versão
mudar**, que é a pressão certa para algo que um estranho consegue disparar. Se você decidir que um
achado não pode ser alcançado no seu ambiente, essa decisão mora fora da ferramenta: numa execução com
`-format json` lida por um script seu, com o motivo escrito ao lado do id.
