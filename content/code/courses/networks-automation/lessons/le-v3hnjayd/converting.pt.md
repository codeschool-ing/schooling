---
title: Convertendo entre formatos
version: 1
---

Um script muitas vezes tem dados num formato e precisa deles em outro: uma resposta NETCONF para
guardar como JSON, um inventário YAML para enviar a uma API REST. **JSON e YAML se convertem um no
outro sem perdas**, porque os dois descrevem as mesmas coisas: mapeamentos, listas, strings,
números, booleanos e null. Carregue um, grave o outro.

**XML não se converte limpo em nenhum dos dois**, porque descreve coisas diferentes. Um elemento
pode ter atributos e texto ao mesmo tempo, os nomes carregam namespaces e nada marca uma lista.
O `xmltodict` é a ponte de costume, e a última diferença aparece na hora:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Três formatos e as conversões entre eles. JSON e YAML, lado a lado, convertem um no outro de forma limpa, já que os dois guardam mapeamentos, listas, strings, números, booleanos e null; de YAML para JSON só se perdem os comentários. O XML, embaixo, converte em qualquer um com perdas: atributos e namespaces não têm para onde ir, e nada no XML diz que elementos são listas, então uma interface e duas interfaces saem com tipos diferentes. O modelo YANG, à direita, é o que diz que elementos são listas.\"><defs><marker id=\"cv-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"30\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">JSON</text><text x=\"120.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem comentários</text><rect x=\"320\" y=\"30\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">YAML</text><text x=\"400.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">comentários</text><path d=\"M202 58 L316 58\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cv-ah)\"></path><path d=\"M316 76 L202 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cv-ah)\"></path><text x=\"260\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">limpo</text><text x=\"260\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">perde comentários</text><rect x=\"180\" y=\"170\" width=\"160\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">XML</text><text x=\"260.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">atributos, namespaces</text><text x=\"260.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem marca de lista</text><path d=\"M220 168 L130 104\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#cv-ah)\"></path><path d=\"M300 168 L390 104\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#cv-ah)\"></path><text x=\"120\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">com perdas</text><rect x=\"540\" y=\"100\" width=\"160\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"620.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o modelo YANG</text><text x=\"620.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">diz que nós</text><text x=\"620.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">são listas</text><path d=\"M538 160 L344 205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#cv-ah)\"></path></svg>", "caption": "JSON e YAML guardam os mesmos tipos de coisa; o XML guarda mais, e diz menos sobre listas.", "same": ["JSON", "YAML", "XML"]}
```

```schooling-example
{
  "language": "python",
  "file": "single.py",
  "parts": [
    {
      "code": "import json\n\nimport xmltodict\n\nONE = \"<interfaces><interface><name>eth1</name></interface></interfaces>\"\nTWO = \"<interfaces><interface><name>eth1</name></interface><interface><name>eth2</name></interface></interfaces>\"\n"
    },
    {
      "code": "print(json.dumps(xmltodict.parse(ONE)))\nprint(json.dumps(xmltodict.parse(TWO)))",
      "note": "**O XML não diz se um elemento é uma lista.** Um `<interface>` sai como dicionário, dois saem como lista, e um laço escrito para um quebra no outro."
    },
    {
      "code": "print(json.dumps(xmltodict.parse(ONE, force_list=(\"interface\",))))",
      "note": "**`force_list` nomeia os elementos que são listas**, que é o que o modelo YANG teria dito."
    }
  ]
}
```

```
ana@ctl:~$ python single.py
{"interfaces": {"interface": {"name": "eth1"}}}
{"interfaces": {"interface": [{"name": "eth1"}, {"name": "eth2"}]}}
{"interfaces": {"interface": [{"name": "eth1"}]}}
```

Um `<interface>` virou um dicionário; dois viraram uma lista de dicionários. **O mesmo caminho do
código recebe dois tipos diferentes conforme quantas interfaces um equipamento por acaso tem**, e
um `for i in data["interfaces"]["interface"]` escrito para o segundo caso percorre as chaves do
primeiro. Passa em todos os testes num roteador do laboratório com três interfaces e falha naquele
roteador de filial que tem um único uplink.

`force_list` nomeia os elementos que são sempre listas, e aí uma interface volta como uma lista de
um. O que o script realmente precisa saber é quais elementos são listas, e **é exatamente isso que
o modelo YANG diz**: `interface*` na árvore da aula 5. É por isso que os formatos derivados de um
modelo evitam o problema em vez de remendá-lo: o JSON do RESTCONF da aula 3 escreveu `interface`
como uma lista com uma entrada, porque o modelo dizia que era uma lista.

Idas e voltas perdem coisas. De XML para JSON perdem-se os namespaces, a não ser que o conversor os
guarde; de JSON para YAML não se perde nada; e de YAML para JSON perdem-se os comentários, que o
YAML tem e o JSON não. Um arquivo que uma pessoa mantém deve ficar no formato em que ela o mantém,
e as conversões devem acontecer a caminho de um equipamento, não na volta para o repositório.
