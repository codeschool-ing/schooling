---
title: Formatos de saída, e pedir um campo só
version: 1
---

**Todo comando da CLI do Azure que responde com dados responde com JSON, e todo o resto é uma visão
desse JSON.** O `--output` escolhe a visão e o `--query` escolhe a parte, e os dois são aplicados pela
CLI no seu computador depois que a resposta chegou. Neste laboratório, a resposta mais rica que não
precisa de conta é a lista de nuvens que a lição 1 apresentou, então ela serve de dado para esta seção.

## A mesma resposta, de quatro jeitos

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l24-pipeline\" aria-label=\"O que acontece com uma resposta dentro da CLI do Azure, da esquerda para a direita. A resposta chega como JSON. A consulta, escrita em JMESPath, fica com a parte pedida. O formato de saída então a imprime como json, table, tsv ou yaml. Os dois passos rodam no seu computador, depois que a resposta chegou.\"><defs><marker id=\"l24-pipeline-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"680.0\" height=\"170.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"36.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o seu computador</text><rect x=\"50.0\" y=\"70.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a resposta</text><text x=\"130.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">JSON</text><rect x=\"280.0\" y=\"70.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a consulta</text><text x=\"360.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">--query</text><rect x=\"510.0\" y=\"70.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a visão</text><text x=\"590.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">--output</text><path d=\"M211.0 105.0 L279.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l24-pipeline-af-ah-paper-dim)\"></path><path d=\"M441.0 105.0 L509.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l24-pipeline-af-ah-paper-dim)\"></path><text x=\"360.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[?name=='AzureCloud'] .endpoints  | [0]</text><text x=\"130.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[ {...}, {...}, ... ]</text><text x=\"590.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">json  table  tsv  yaml</text><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">nada nos dois passos é mandado ao Azure: os dois recortam o que já voltou</text></svg>", "caption": "A consulta escolhe a parte, a saída escolhe como imprimi-la, as duas depois que a resposta chegou."}
```

```
ana@laptop:~/azure/cli$ az cloud list --query "[].name" --output tsv
AzureCloud
AzureChinaCloud
AzureUSGovernment
AzureBleuCloud
ana@laptop:~/azure/cli$ az cloud list --query "[].{name: name, active: isActive}" --output table
Name               Active
-----------------  --------
AzureCloud         True
AzureChinaCloud    False
AzureUSGovernment  False
AzureBleuCloud     False
ana@laptop:~/azure/cli$ az cloud show --query "{resourceManager: endpoints.resourceManager}" --output yaml
resourceManager: https://management.azure.com/
ana@laptop:~/azure/cli$ az cloud show --query endpoints.resourceManager --output json
"https://management.azure.com/"
```

As visões que vale conhecer:

| `--output` | o que imprime | para |
|---|---|---|
| `json` | a resposta inteira, indentada; o padrão | ler a olho, e o `jq` |
| `jsonc` | o mesmo, em cores | só ler a olho: os códigos de cor quebram um pipe |
| `table` | colunas, com cabeçalhos, para os campos de primeiro nível | uma olhada rápida numa lista |
| `tsv` | valores separados por tabulação, sem chaves, sem aspas | scripts de shell |
| `yaml` | a resposta como YAML | arquivos de configuração |
| `none` | nada | comandos rodados pelo efeito |

**O `tsv` é o dos scripts, e ele descarta as chaves**, então as colunas saem na ordem em que o JSON as
tinha, o que não é uma promessa que a CLI faz. Peça exatamente os campos que quer com `--query`, e a
ordem fica sendo sua.

## O `--query` é JMESPath

A linguagem por trás do `--query` é o **JMESPath**, uma linguagem de consulta para JSON com
especificação publicada. Quatro peças dela cobrem quase tudo de que um dia de trabalho precisa:

```
ana@laptop:~/azure/cli$ az cloud list --query "[?name=='AzureCloud'].endpoints.resourceManager | [0]" --output tsv
https://management.azure.com/
ana@laptop:~/azure/cli$ az cloud list --query "length([])"
4
ana@laptop:~/azure/cli$ az cloud list --query "sort_by([], &name)[].{name: name, active: isActive}"
[
  {
    "active": false,
    "name": "AzureBleuCloud"
  },
  {
    "active": false,
    "name": "AzureChinaCloud"
  },
  {
    "active": true,
    "name": "AzureCloud"
  },
  {
    "active": false,
    "name": "AzureUSGovernment"
  }
]
```

Leia a primeira da esquerda para a direita: `[?name=='AzureCloud']` fica com as entradas cujo `name` é
`AzureCloud`, `.endpoints.resourceManager` pega um campo de cada, e `| [0]` transforma a lista de um
elemento no próprio valor, e é por isso que o `tsv` imprimiu um endereço puro, sem colchetes. A segunda
conta a lista com `length`. A terceira ordena por nome e monta um objeto novo por entrada com
`{name: name, active: isActive}`, renomeando um campo no caminho. Dentro do `sort_by`, `&name` é uma
referência ao campo, e não o seu valor.

| peça | quer dizer |
|---|---|
| `[]` | toda entrada de uma lista |
| `[?expr]` | as entradas em que `expr` é verdadeira; textos vão entre aspas simples |
| `.field` | um campo |
| `{a: x, b: y}` | um objeto novo feito dos campos escolhidos |
| `\| [0]` | parar de tratar como lista, e pegar o primeiro |
| `length()`, `sort_by()`, `contains()`, `starts_with()` | funções |

**Ponha a consulta inteira entre aspas duplas e os textos dentro dela entre aspas simples.** O shell
então deixa as aspas simples em paz e o JMESPath as recebe; do jeito contrário, o shell as come, e a
consulta falha com um erro sobre um campo que não existe.

## Uma resposta vazia não é um erro

O comando que um script mais roda para conferir onde está, e o que ele diz aqui:

```
ana@laptop:~/azure/cli$ az account list; echo "exit code $?"
WARNING: Please run "az login" to access your accounts.
[]
exit code 0
```

**Um aviso, uma lista vazia, e código de saída 0.** A CLI trata *você não tem assinaturas* como uma
resposta correta, o que ela é, e um script que só confere o código de saída segue como se estivesse
tudo bem, para falhar três comandos depois em algo que não tem nada a ver com a causa. Confira o que
voltou: o `az account show` falha com código de saída quando ninguém fez login, e uma lista pode ser
contada com `--query "length([])"`.

## Quando usar o `jq` no lugar

O `--query` basta para qualquer coisa que a própria CLI respondeu. As lições deste curso também usam o
`jq`, porque um template Bicep compilado é um arquivo, não uma resposta da CLI, e o `--query` só
funciona na resposta do comando a que é dado. A regra é curta: **`--query` para uma resposta do `az`,
`jq` para todo o resto**, e nunca analise uma `table` com `grep` e `awk`, porque a largura das colunas
depende do valor mais comprido nela.
