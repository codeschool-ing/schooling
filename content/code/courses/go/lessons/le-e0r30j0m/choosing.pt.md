---
title: Escolher um módulo antes de depender dele
version: 1
---

O jeito comum de escolher uma dependência é buscar, pegar o primeiro resultado que compila e seguir
em frente. Parece seguro porque a escolha se desfaz com um `go get …@none`. Ela se desfaz menos do
que isso sugere: **todo módulo que você adiciona é código que roda dentro do seu programa, com tudo
o que o seu programa tem permissão de fazer**, e três anos depois ele continua lá, na versão que você
pediu por último. A decisão merece os cinco minutos que esta seção gasta com ela.

A lição 8 deixou uma pergunta em aberto. Quem lê vê um caractere onde Go vê duas runas, e a
biblioteca padrão para nas runas, então contar o que um leitor chama de caracteres pede um módulo de
fora. Dois candidatos aparecem para isso, e o resto da seção é a comparação, feita no lab.

## pkg.go.dev, a primeira página a ler

O **pkg.go.dev** é onde a lição 4 mandou você procurar a documentação de qualquer módulo público, e o
topo da página de um pacote responde metade das perguntas antes de você ler qualquer código. No dia
em que o lab rodou, as duas páginas diziam:

| | `github.com/rivo/uniseg` | `github.com/clipperhouse/uax29/v2/graphemes` |
|---|---|---|
| versão | v0.4.7 | v2.7.0 |
| publicada em | 8 de fevereiro de 2024 | 16 de fevereiro de 2026 |
| licença | MIT | MIT |
| importado por | 546 | 10 |

"Importado por" é o número de pacotes conhecidos pelo pkg.go.dev que importam este, e só por esse
número o primeiro candidato ganha com folga. **Popularidade mede o passado**, porém: ela conta os
programas que escolheram um módulo, não se o módulo ainda merece a escolha. O resto das evidências
está nos próprios módulos, e o comando go as busca sem navegador.

## Cinco perguntas, respondidas no terminal

`go list -m` imprime qualquer campo das informações de um módulo com `-f`, inclusive a hora em que a
versão foi publicada:

```
ana@vm:~/thirdparty-width$ go list -m -f "{{.Path}} {{.Version}} {{.Time}}" github.com/rivo/uniseg@latest github.com/clipperhouse/uax29/v2@latest
github.com/rivo/uniseg v0.4.7 2024-02-08 13:16:15 +0000 UTC
github.com/clipperhouse/uax29/v2 v2.7.0 2026-02-16 15:57:44 +0000 UTC
```

A última release de um módulo ser antiga não é um veredito por si só; uma biblioteca pequena e
acabada pode não ter mais nada a mudar. O que faz disso um veredito aqui é o assunto. Caracteres são
definidos pelo Unicode, que continua publicando edições novas com caracteres novos, e a lição 8
mostrou o pacote `unicode` deste Go em 17.0.0. O código de cada módulo diz de que edição vêm as suas
tabelas, junto com a licença e as exigências dele:

```
ana@vm:~/thirdparty-width$ cd $(go env GOMODCACHE)/github.com/rivo/uniseg@v0.4.7 && head -1 LICENSE.txt && grep -n "Unicode version" graphemerules.go && cat go.mod
MIT License
40:// Unicode version 15.0.0.
module github.com/rivo/uniseg

go 1.18
ana@vm:~/thirdparty-width$ cd $(go env GOMODCACHE)/github.com/clipperhouse/uax29/v2@v2.7.0 && head -1 LICENSE && grep -n "Public/" graphemes/trie.go && cat go.mod
MIT License
4:// from https://www.unicode.org/Public/17.0.0/ucd/auxiliary/GraphemeBreakProperty.txt
module github.com/clipperhouse/uax29/v2

go 1.18

// Surprising allocations in this release, do not use.
retract v2.1.0

// This release was effectively identical to v2.0.1, and
// only exists to revert the regression introduced in v2.1.0.
retract v2.1.1
```

O `uniseg` foi feito a partir do Unicode 15.0.0 e o `uax29` a partir do 17.0.0. A seção 02 viu na
tela como ficam tabelas desatualizadas: o `go-runewidth` antigo deu uma coluna a um emoji recente, e
o novo deu duas. Nenhum dos dois `go.mod` tem linha `require`, então nenhum traz outro módulo junto.
E o segundo carrega duas linhas `retract`, que a seção 05 explica: o autor retirou duas releases
ruins, com uma frase dizendo por quê, e é assim que se parece um módulo mantido.

Há mais uma testemunha. O `go-runewidth` da seção 02 é importado por 3.302 pacotes no pkg.go.dev, e
o autor dele enfrentou a mesma escolha. O proxy guarda o `go.mod` de toda versão, então dá para ler o momento da
decisão:

```
ana@vm:~/thirdparty-width$ curl -s https://proxy.golang.org/github.com/mattn/go-runewidth/@v/v0.0.17.mod
module github.com/mattn/go-runewidth

go 1.9

require github.com/rivo/uniseg v0.2.0
ana@vm:~/thirdparty-width$ curl -s https://proxy.golang.org/github.com/mattn/go-runewidth/@v/v0.0.18.mod
module github.com/mattn/go-runewidth

go 1.20

require github.com/clipperhouse/uax29/v2 v2.2.0
```

Então um dos dez que importam o `uax29/v2/graphemes` é um módulo de que milhares de pacotes
dependem, e isso também ensina algo sobre o "importado por": ele conta só quem importa diretamente.
Com essas evidências, o segundo candidato é a aposta melhor para código novo hoje. **Guarde as
perguntas, não o veredito**, porque o veredito muda no dia em que qualquer um dos dois lançar uma
versão:

| pergunta | onde está a resposta |
|---|---|
| posso usar? | a licença: o arquivo `LICENSE`, e a linha de licença do pkg.go.dev |
| é mantido? | a data da última release, e se ele acompanha aquilo de que depende |
| o que ele traz junto? | o `go.mod` dele, e `go list -m all` depois de um `go get` |
| quem mais confia nele? | o "importado por" do pkg.go.dev, e quais módulos conhecidos o exigem |
| tem vulnerabilidades conhecidas? | o `govulncheck`, abaixo |

A licença decide se você pode distribuir o módulo, para começo de conversa. MIT, BSD e Apache 2.0
deixam você usar o código em quase qualquer programa, inclusive um que você vende; outras impõem
condições ao programa que as inclui. O pkg.go.dev marca "Redistributable license" nos detalhes quando
reconhece a licença como uma que permite redistribuir. Se a licença for desconhecida para você,
pergunte antes do `go get`, não depois de entregar.

## Quanto ele traz junto

Os dois candidatos chegam sozinhos. Um framework web é a outra ponta da escala, e um `go get` de um
dos populares, num módulo vazio, mostra isso:

```
ana@vm:~/thirdparty-gin$ go get github.com/gin-gonic/gin@v1.12.0 2>&1 | grep -c "^go: added"
30
ana@vm:~/thirdparty-gin$ go list -m all | wc -l
56
ana@vm:~/thirdparty-gin$ go list -m all | grep golang.org/x/
golang.org/x/arch v0.22.0
golang.org/x/crypto v0.48.0
golang.org/x/mod v0.32.0
golang.org/x/net v0.51.0
golang.org/x/sync v0.19.0
golang.org/x/sys v0.41.0
golang.org/x/term v0.40.0
golang.org/x/text v0.34.0
golang.org/x/tools v0.41.0
```

Um comando adicionou 30 exigências ao `go.mod`, e o grafo do build tem 55 módulos além do seu. A
maioria é código bom de gente cuidadosa, e a questão não é essa. **Cada um é código que você entrega,
uma licença que você aceitou e mais um lugar onde uma vulnerabilidade pode aparecer.** Um framework
pode muito bem valer a pena; para uma rota, o `net/http` da biblioteca padrão merece um olhar antes.

## govulncheck: falhas conhecidas no que você chama

A última pergunta tem uma ferramenta própria. O **`govulncheck`**, do módulo `golang.org/x/vuln`,
compara as dependências do seu módulo, e a biblioteca padrão do Go que o compila, com o banco de
vulnerabilidades do Go, e informa as vulnerabilidades conhecidas que o seu código consegue alcançar.
Você o instala como qualquer comando, com `go install golang.org/x/vuln/cmd/govulncheck@latest`; o
lab tem a v1.8.0. Por padrão ele lê o banco em vuln.go.dev, que o lab não alcança, então toda
varredura abaixo aponta para uma cópia do mesmo banco, montada a partir do código-fonte dele de 5 de
outubro de 2026, com `-db file:///home/ana/thirdparty-vulndb`. Na sua máquina, deixe essa flag de
fora.

Para haver o que encontrar, este módulo pede de propósito uma versão do `golang.org/x/text` de 2021:

```go
// Command locale reads a language tag such as pt-BR.
package main

import (
	"fmt"
	"os"

	"golang.org/x/text/language"
)

func main() {
	tag, err := language.Parse(os.Args[1])
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	base, _ := tag.Base()
	region, _ := tag.Region()
	fmt.Println(tag, base, region)
}
```

```
ana@vm:~/thirdparty-locale$ go get golang.org/x/text@v0.3.6
go: added golang.org/x/text v0.3.6
ana@vm:~/thirdparty-locale$ go run . pt-BR
pt-BR pt BR
```

O programa funciona, e é exatamente por isso que ninguém perceberia. Depois, a varredura:

```
ana@vm:~/thirdparty-locale$ govulncheck -db file:///home/ana/thirdparty-vulndb ./...; echo $?
=== Symbol Results ===

Vulnerability #1: GO-2021-0113
    Out-of-bounds read in golang.org/x/text/language
  More info: https://pkg.go.dev/vuln/GO-2021-0113
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.6
    Fixed in: golang.org/x/text@v0.3.7
    Example traces found:
      #1: main.go:12:28: locale.main calls language.Parse

Your code is affected by 1 vulnerability from 1 module.
This scan also found 1 vulnerability in packages you import and 1 vulnerability
in modules you require, but your code doesn't appear to call these
vulnerabilities.
Use '-show verbose' for more details.
3
```

Leia o relatório como três fatos. A vulnerabilidade tem um identificador, `GO-2021-0113`, e uma
página própria. Ela está no `golang.org/x/text` na versão que você tem, e foi corrigida da v0.3.7 em
diante. E **o seu código chega até ela**: a linha 12 do `main.go` chama `language.Parse`, que é a
função afetada. Esse rastro é o que separa o govulncheck de uma simples lista de alertas. Ele segue
as chamadas, então uma falha numa função que o seu programa nunca chama aparece separada e não muda o
status de saída, que é 3 quando o seu código é afetado e 0 quando não é.

`-show verbose` imprime o que o relatório curto resumiu, começando pelo que foi varrido:

```
ana@vm:~/thirdparty-locale$ govulncheck -db file:///home/ana/thirdparty-vulndb -show verbose ./... | head -9
Fetching vulnerabilities from the database...

Checking the code against the vulnerabilities...

The package pattern matched the following root package:
  example.com/locale
Govulncheck scanned the following 2 modules and the go1.27.1 standard library:
  example.com/locale
  golang.org/x/text@v0.3.6
ana@vm:~/thirdparty-locale$ govulncheck -db file:///home/ana/thirdparty-vulndb -show verbose ./... | sed -n "/Package Results/,\$p"
=== Package Results ===

Vulnerability #1: GO-2022-1059
    Denial of service via crafted Accept-Language header in
    golang.org/x/text/language
  More info: https://pkg.go.dev/vuln/GO-2022-1059
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.6
    Fixed in: golang.org/x/text@v0.3.8

=== Module Results ===

Vulnerability #1: GO-2026-5970
    Infinite loop on invalid input in golang.org/x/text
  More info: https://pkg.go.dev/vuln/GO-2026-5970
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.6
    Fixed in: golang.org/x/text@v0.39.0

Your code is affected by 1 vulnerability from 1 module.
This scan also found 1 vulnerability in packages you import and 1 vulnerability
in modules you require, but your code doesn't appear to call these
vulnerabilities.
```

O resultado de pacote está em `language`, o pacote que você importa, em funções que este programa
não chama; o resultado de módulo está em outro pacote do mesmo módulo, que você nem importa. Nenhum
dos dois é alcançável hoje, e os dois podem ser no dia em que alguém acrescentar uma linha. É por
isso que a correção não é a versão que o primeiro relatório citou. A v0.3.7 acabaria com o primeiro
achado e manteria os outros dois, e as três linhas "Fixed in" juntas apontam para depois da v0.39.0.
**Atualize para a release mais nova e varra de novo**:

```
ana@vm:~/thirdparty-locale$ go get golang.org/x/text@latest
go: upgraded golang.org/x/text v0.3.6 => v0.42.0
ana@vm:~/thirdparty-locale$ govulncheck -db file:///home/ana/thirdparty-vulndb ./...; echo $?
No vulnerabilities found.
0
ana@vm:~/thirdparty-locale$ go run . pt-BR
pt-BR pt BR
```

"No vulnerabilities found" quer dizer que nada no banco corresponde ao que o seu código chama, nas
versões que ele usa, no dia em que você perguntou. O banco continua crescendo e o seu `go.mod` não
se move sozinho, então **uma varredura é uma leitura, não um certificado**: rode de novo antes de
cada release, e sempre que uma dependência mudar.
