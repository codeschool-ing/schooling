---
title: Reporters, a execução como arquivo
version: 1
---

**Um reporter decide o que o Newman faz com os resultados, e uma execução pode ter vários ao mesmo
tempo.** O reporter `cli` é o que você vem lendo. Os outros escrevem arquivos, para programas e não
para pessoas: um pipeline que desenha uma lista de testes, um painel, um script que conta falhas ao
longo de um mês. Dois vêm com o Newman, e o terceiro que as pessoas costumam ter em mente é pacote de
outra pessoa.

| reporter | escreve | para |
|---|---|---|
| `cli` | a saída da seção 03 | uma pessoa num terminal, ou o log de um pipeline |
| `junit` | um arquivo XML no formato JUnit | quase todo sistema de CI, que o lê para mostrar os testes pelo nome |
| `json` | a execução inteira em JSON, com toda requisição e resposta | os seus próprios scripts |
| `htmlextra` | uma página HTML com toda requisição | uma pessoa, num navegador; um pacote de terceiros, `newman-reporter-htmlextra`, instalado à parte |

`--reporters` recebe uma lista, e cada reporter de arquivo recebe um `--reporter-<name>-export` com o
caminho a gravar. Argumentos depois de `--` vão do npm para o script, então o script do projeto cresce
sem ser editado:

```
ana@laptop:~/boxoffice$ npm run test:api -- --reporters cli,junit,json --reporter-junit-export results/newman.xml --reporter-json-export results/newman.json > /dev/null
ana@laptop:~/boxoffice$ ls results
bail.json  newman.json	newman.xml
```

A saída foi para `/dev/null` desta vez, porque o que interessa são os dois arquivos. O próprio Newman
criou o diretório `results/`, o mesmo que o `.gitignore` já exclui.

## JUnit, o formato que um pipeline lê

O JUnit nasceu como o framework de testes do Java, e o relatório XML dele virou o formato em que os
sistemas de CI concordam, do jeito que problem details virou um para erros. Cada requisição com
testes é um `<testsuite>`, cada asserção um `<testcase>`, e uma asserção que falhou traz um
`<failure>` dentro:

```
ana@laptop:~/boxoffice$ grep -c '<testcase' results/newman.xml
18
ana@laptop:~/boxoffice$ grep -B1 -A2 '<failure' results/newman.xml
    <testcase name="HEAD answers like GET" time="0.003" classname="ShowsHeadOneShow">
      <failure type="AssertionFailure" message="expected response to have status code 200 but got 405">
        <![CDATA[Failed 1 times.]]>
        <![CDATA[Collection JSON ID: 9a80d684-c139-45e1-b410-6c84cbd7c8f6.]]>
```

Dezoito casos de teste, um por asserção, e a falha traz a mesma mensagem que o terminal mostrou. Um
sistema de CI que lê o arquivo desenha os dezoito nomes e marca um de vermelho. Ele também consegue
dizer que o mesmo teste falhou em toda execução desde que foi escrito, o que a saída do terminal não
consegue.

## JSON, o formato que os seus scripts leem

O relatório JSON guarda tudo o que o Newman sabia, o que o deixa grande e faz do jq o caminho de
entrada:

```
ana@laptop:~/boxoffice$ jq '.run.stats.assertions' results/newman.json
{
  "total": 18,
  "pending": 0,
  "failed": 1
}
ana@laptop:~/boxoffice$ jq -r '.run.failures[] | .source.name + ": " + .error.message' results/newman.json
HEAD one show: expected response to have status code 200 but got 405
```

A primeira é a mesma contagem que a tabela imprimiu. A segunda lista cada falha por requisição e
mensagem, a forma que um script postaria num canal de chat ou acrescentaria a um arquivo. **Quando
uma pergunta sobre uma execução não é respondida pela tabela, a resposta está neste arquivo**, e dá
para fazê-la sobre a execução de ontem tanto quanto sobre a de hoje.

O `htmlextra` faz uma página que uma pessoa consegue navegar, com cada requisição e resposta
organizadas. Ele não faz parte do Newman: é instalado como qualquer outro pacote, com
`npm install --save-dev`. Não foi usado neste curso. **Um reporter de terceiros é código que lê toda
requisição e resposta da sua execução**, tokens incluídos, então merece a mesma olhada que qualquer
outra dependência antes de entrar.
