---
title: Binários, níveis de varredura e relatórios para máquinas
version: 1
---

Uma varredura de código precisa do código, do grafo de módulos e de um Go para carregá-los. **O que
roda em produção é um binário**, compilado no mês passado por um pipeline ou baixado da página de
releases de alguém. Quando ele e o seu checkout se distanciam, "este arquivo no servidor está
afetado?" é uma pergunta diferente de "o meu checkout está afetado?". O `govulncheck` consegue
responder a partir do binário sozinho, com menos precisão, por motivos que vale conhecer antes de
confiar em qualquer uma das respostas.

## O que um binário lembra de si mesmo

Todo binário que o comando go compila carrega um registro de como foi compilado: a versão do Go, o
módulo principal e cada dependência com versão e checksum. `go version -m` imprime esse registro:

```
ana@vm:~/langs$ go build -o accept-bin ./accept && go build -o tag-bin ./tag
ana@vm:~/langs$ go version -m accept-bin | head -n 4
accept-bin: go1.27.1
	path	example.com/langs/accept
	mod	example.com/langs	(devel)	
	dep	golang.org/x/text	v0.3.7	h1:olpwvP2KacW1ZWvsR7uQhoyTYvKAupfQrRGBFM352Gk=
```

**Esse registro e a tabela de símbolos do binário são tudo o que `-mode binary` lê.** O registro dá o
nível de módulo: quais módulos em quais versões, e qual versão da biblioteca padrão. A tabela de
símbolos, a lista de nomes de função que o linker manteve, faz as vezes do grafo de chamadas. O linker
descarta funções que nada chama, então uma função vulnerável que continua no arquivo muito
provavelmente é alcançável:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -mode binary accept-bin; echo $?
=== Symbol Results ===

Vulnerability #1: GO-2022-1059
    Denial of service via crafted Accept-Language header in
    golang.org/x/text/language
  More info: https://pkg.go.dev/vuln/GO-2022-1059
  Module: golang.org/x/text
    Found in: golang.org/x/text@v0.3.7
    Fixed in: golang.org/x/text@v0.3.8
    Vulnerable symbols found:
      #1: language.ParseAcceptLanguage

Your code is affected by 1 vulnerability from 1 module.
This scan also found 0 vulnerabilities in packages you import and 14
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.
3
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -mode binary tag-bin | tail -n 6; echo ${PIPESTATUS[0]}

Your code is affected by 0 vulnerabilities.
This scan also found 1 vulnerability in packages you import and 14
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.
0
```

Os veredictos batem com a seção 03, e duas coisas mudaram. **`Example traces found` virou
`Vulnerable symbols found`**: o binário diz que a função está lá e não consegue dizer quem a chama,
então não há linha do seu código para onde ir. E a contagem de pacotes caiu uma unidade em cada
programa. O binário registra que foi compilado com `GOOS=linux`, então a entrada do `os`, só do
Windows, deixa de se aplicar a ele, enquanto o código-fonte, que poderia ser compilado para qualquer
sistema, a mantém.

As fraquezas vêm do mesmo lugar. **Uma função pode estar ligada no binário e mesmo assim nunca
rodar**, e a documentação diz isso: uma varredura de binário pode relatar código que está no arquivo
mas é inalcançável. A falha oposta é a que merece atenção. Tire a tabela de símbolos, como a lição 17
faz para deixar um binário menor, e não sobra onde procurar nomes:

```
ana@vm:~/langs$ go build -ldflags="-s -w" -o accept-small ./accept && stat -c "%s bytes  %n" accept-bin accept-small
2683796 bytes  accept-bin
1740960 bytes  accept-small
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -mode binary accept-small | tail -n 4; echo ${PIPESTATUS[0]}
Your code is affected by 15 vulnerabilities from 1 module and the Go standard library.
This scan found no other vulnerabilities in packages you import or modules you
require.
Use '-show verbose' for more details.
3
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -mode binary accept-small | grep -c '^Vulnerability #'
15
```

O mesmo programa foi de 1 vulnerabilidade para **15**. Sem nomes para conferir, o `govulncheck` cai
para o nível de módulo e relata todo símbolo vulnerável de todo módulo que o registro lista como
presente. Isso inclui doze no `net/http`, no `crypto/tls` e no `html/template` da biblioteca padrão,
e o `accept` não importa nenhum deles. Nada nessa saída diz que ele chutou. **Varra o binário antes
de tirar os símbolos**, ou varra o código de que o binário foi compilado, que é o que o job de CI da
seção 05 faz.

## Escolhendo o nível

`-scan` define até onde a análise desce: `symbol`, o padrão, `package` ou `module`. **O status de
saída segue o nível pedido**, então o mesmo código pode passar num e falhar noutro. Aqui está o `tag`
no nível de pacote, e uma cópia do `hits` da lição 1, que não tem dependência nenhuma, nos níveis de
símbolo e de módulo:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -scan package ./tag | tail -n 5; echo ${PIPESTATUS[0]}

Your code may be affected by 2 vulnerabilities.
This scan also found 14 vulnerabilities in modules you require.
Use '-scan symbol' for more fine grained vulnerability detection and '-show
verbose' for more details.
3
ana@vm:~/vuln-hits$ govulncheck -db file:///home/ana/vulndb ./... | tail -n 5; echo ${PIPESTATUS[0]}
Your code is affected by 0 vulnerabilities.
This scan also found 1 vulnerability in packages you import and 12
vulnerabilities in modules you require, but your code doesn't appear to call
these vulnerabilities.
Use '-show verbose' for more details.
0
ana@vm:~/vuln-hits$ govulncheck -db file:///home/ana/vulndb -scan module | tail -n 4; echo ${PIPESTATUS[0]}
    Fixed in: stdlib@go1.27.2

Your code may be affected by 13 vulnerabilities.
Use '-scan symbol' for more fine grained vulnerability detection.
3
```

O texto muda com o nível: **"is affected" no nível de símbolo, "may be affected" acima dele**, porque
acima dele nada foi rastreado. O `hits` está limpo no nível de símbolo e falha com 13 no nível de
módulo, todas da biblioteca padrão do Go 1.27.1. O nível de módulo recusa padrão de pacote e julga os
requisitos do módulo como um todo, o que faz dele o nível mais propenso a reprovar um build por causa
de código que ninguém chama. Use o padrão numa barreira.

## Relatórios para um programa

O texto é escrito para uma pessoa. `-format json` grava uma sequência de objetos JSON, um depois do
outro, para um programa ler, e **com qualquer `-format` que não seja `text` o status de saída é 0,
seja o que for que tenha sido achado**:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -format json ./accept > scan.json; echo $?
0
ana@vm:~/langs$ jq -r 'keys[0]' scan.json | sort | uniq -c
      1 SBOM
      1 config
     24 finding
    191 osv
      2 progress
ana@vm:~/langs$ jq -c 'select(.finding.trace[0].function) | .finding | {osv, fixed_version, trace: [.trace[].function]}' scan.json
{"osv":"GO-2022-1059","fixed_version":"v0.3.8","trace":["ParseAcceptLanguage","preferred","main"]}
ana@vm:~/langs$ jq -c 'select(.config) | .config | {scan_level, scan_mode, go_version}' scan.json
{"scan_level":"symbol","scan_mode":"source","go_version":"go1.27.1"}
```

A sequência traz as configurações da varredura, os módulos que ela viu, toda entrada OSV que toca um
deles, 191 aqui, e os achados. **O trace de um achado vai da função vulnerável até o seu ponto de
entrada**, o inverso de `-show traces`, e até onde o primeiro quadro desce diz o nível: um módulo e
uma versão num achado de nível de módulo, também um pacote num de nível de pacote, e uma função com
posição só num de nível de símbolo. É por isso que o filtro `jq` acima, que guarda os achados cujo
primeiro quadro cita uma função, separou exatamente o que o relatório em texto pôs em Symbol Results.

`-format sarif` grava SARIF, o formato que os serviços de análise de código recebem, com um resultado
por vulnerabilidade e o nível convertido numa severidade:

```
ana@vm:~/langs$ govulncheck -db file:///home/ana/vulndb -format sarif ./accept > scan.sarif; echo $?
0
ana@vm:~/langs$ jq -r '.runs[0].results[].level' scan.sarif | sort | uniq -c
      1 error
     14 note
      1 warning
ana@vm:~/langs$ jq '.runs[0].results[] | select(.level == "error") | .message.text' scan.sarif
"Your code calls vulnerable functions in 1 package (golang.org/x/text/language)."
```

`error` para o nível de símbolo, `warning` para o de pacote, `note` para o de módulo: os mesmos 1, 1 e
14 do resumo em texto. Existe também `-format openvex`, para VEX, um formato de declarações sobre
quais vulnerabilidades afetam um produto; ele não foi rodado aqui.

| execução | status de saída |
|---|---|
| texto, e algo achado no nível pedido (`symbol`, a menos que `-scan` diga outro) | 3 |
| texto, e nada achado nesse nível, seja o que for que os níveis mais grossos tenham | 0 |
| `-format json`, `sarif` ou `openvex`, seja o que for que tenha sido achado | 0 |
| um erro na linha de comando, como um padrão com `-scan module` | 2 |

**Um job que grava JSON para um painel precisa decidir a falha por conta própria**, lendo os achados,
ou rodar uma segunda varredura, em texto, pelo status de saída. Esquecer disso dá um pipeline que
nunca falhou e nunca vai falhar.
