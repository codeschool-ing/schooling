---
title: Acentos: fora da chave, dentro do nome
version: 1
---

**As pessoas digitam o mesmo nome com e sem acentos**, sobretudo em teclados em que acentuar dá
trabalho. `Sao Paulo` é a segunda grafia mais comum de São Paulo neste arquivo. Para uma chave, os
acentos devem sair.

Removê-los usa a decomposição da seção anterior: decompor em NFKD, para cada acento virar um
caractere combinante separado, e depois descartar os combinantes:

```schooling-example
{
  "language": "python",
  "file": "cascade.py",
  "parts": [
    {
      "code": "import unicodedata\n\nfrom cities import city\n\n\n"
    },
    {
      "code": "def fix_mojibake(text):\n    if \"Ã\" in text:\n        return text.encode(\"latin-1\").decode(\"utf-8\")\n    return text\n\n\n",
      "note": "**Reparar mojibake**, só onde aparece a sua assinatura `Ã`; a seção sobre mojibake explica por que o teste importa."
    },
    {
      "code": "def without_accents(text):\n    text = unicodedata.normalize(\"NFKD\", text)\n    return \"\".join(ch for ch in text if not unicodedata.combining(ch))\n\n\n",
      "note": "**Tirar acentos**: decompor, depois descartar todo caractere combinante."
    },
    {
      "code": "steps = [\n    (\"as exported\", lambda s: s),\n",
      "note": "Os passos em ordem, cada um uma função de coluna em coluna."
    },
    {
      "code": "    (\"spaces trimmed\", lambda s: s.str.strip().str.replace(r\"\\s+\", \" \", regex=True)),\n",
      "note": "Aparar as pontas e reduzir toda sequência de espaços a um."
    },
    {
      "code": "    (\"Unicode to NFC\", lambda s: s.str.normalize(\"NFC\")),\n",
      "note": "Toda letra na forma composta."
    },
    {
      "code": "    (\"mojibake repaired\", lambda s: s.map(fix_mojibake)),\n"
    },
    {
      "code": "    (\"lower case\", lambda s: s.str.lower()),\n"
    },
    {
      "code": "    (\"accents removed\", lambda s: s.map(without_accents)),\n"
    },
    {
      "code": "]\n"
    },
    {
      "code": "values = city\nfor label, step in steps:\n    values = step(values)\n    if __name__ == \"__main__\":\n        print(f\"{label:18} {values.nunique():3} distinct\")\nif __name__ == \"__main__\":\n    print(sorted(values.unique()))\n",
      "note": "Aplicar os passos um depois do outro, e imprimir quantos valores distintos sobram depois de cada um."
    }
  ]
}
```

`without_accents` é essa função. No PostgreSQL, a extensão `unaccent` faz o mesmo, com uma tabela de
trocas; a última seção desta aula a usa.

## O que tirar acentos custa

Acentos não são enfeite em português. `país` é um país e `pais` são pai e mãe; `avó` é a avó e `avô`
o avô; `Simões` e `Simoes` são o mesmo sobrenome escrito por duas gerações da mesma família. **Uma
chave sem acentos junta tudo isso**, e para uma cidade ou um sobrenome numa chave de comparação é o
que se quer: o custo de juntar duas grafias de um nome é menor que o de dividir uma pessoa em duas.

Para o valor guardado, a troca é a errada. Um cliente chamado `João` não deve receber carta para
`Joao`. É a mesma regra das maiúsculas, e o motivo de ela voltar sempre: **a chave é para a máquina,
o nome é para a pessoa**, e a limpeza mantém os dois.
