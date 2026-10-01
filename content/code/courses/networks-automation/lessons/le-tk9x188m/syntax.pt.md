---
title: Valores, loops e filtros
version: 1
---

O Jinja2 tem três tipos de marcação dentro de texto comum. **`{{ ... }}` imprime o valor de uma
expressão.** **`{% ... %}` é uma instrução**, um loop ou uma condição, e não imprime nada por si.
`{# ... #}` é um comentário e desaparece. Todo o resto é copiado para a saída como está.

```schooling-example
{
  "language": "python",
  "file": "first.py",
  "parts": [
    {
      "code": "from jinja2 import Environment\n"
    },
    {
      "code": "TEMPLATE = \"\"\"hostname {{ hostname }}\n{% for i in interfaces %}\ninterface {{ i.name }}\n description {{ i.description | upper }}\nexit\n{% endfor %}\"\"\"\n",
      "note": "**Um template é texto com buracos.** `{{ ... }}` imprime um valor e `{% ... %}` é lógica: aqui um laço, fechado por `endfor`."
    },
    {
      "code": "data = {\n    \"hostname\": \"edge1\",\n    \"interfaces\": [\n        {\"name\": \"eth1\", \"description\": \"uplink to core1\"},\n        {\"name\": \"eth2\", \"description\": \"branch LAN\"},\n    ],\n}\n\ntemplate = Environment().from_string(TEMPLATE)\nprint(template.render(data))",
      "note": "**Os dados são Python comum**: uma string e uma lista de dicionários, a forma que um arquivo YAML entrega."
    }
  ],
  "output": "hostname edge1\n\ninterface eth1\n description UPLINK TO CORE1\nexit\n\ninterface eth2\n description BRANCH LAN\nexit"
}
```

O loop rodou uma vez por interface, e dentro dele `i.name` acessou o dicionário: o Jinja2 deixa um
ponto valer por uma chave, então `i.name` e `i["name"]` são a mesma coisa. O `|` passa um valor por
um **filtro**, uma função que o transforma; `upper` é um dos cerca de cinquenta que vêm com o
Jinja2, ao lado de `default`, `join`, `replace`, `int` e `length`.

A saída tem um problema fácil de deixar passar numa tela e impossível de deixar passar num diff:
**linhas em branco que ninguém escreveu.** Elas vêm das linhas que continham só uma tag `{% %}`. A
tag não imprimiu nada, mas a quebra de linha depois dela era texto comum, e o Jinja2 a copiou. A
próxima seção trata de onde elas vêm e de como evitá-las.

Condições se parecem com as do Python, com `{% if %}`, `{% elif %}`, `{% else %}` e um `{%
endif %}` de fechamento. Testes usam `is`: `{% if i.description is defined %}` pergunta se a chave
existe. O template que esta aula constrói usa os dois.
