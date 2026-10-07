---
title: Estreitar o que entra
version: 2
---

Uma imagem comum do tratamento de entrada para um modelo é que não há nada a tratar: o modelo lê
texto, então o que o usuário digitou segue adiante, e a verificação acontece na resposta. **Todo campo
que chega a um prompt é algo sobre o que o modelo vai tentar agir**, e quanto menos houver, e quanto
mais tiver formato conhecido, menos há para dar errado. Texto livre num prompt é o que alguém que tenta vai usar; esta aula trata da metade mais barata da defesa, que é decidir o que
pode entrar.

A entrada de trabalhos da Tarefa recebe o pedido de um cliente e pede a um modelo que o classifique e
sugira um preço. O pedido não é uma caixa de texto. Ele tem quatro campos, e cada um tem uma regra. Cole as regras:

```sh
cat > ~/guard/data/input-rules.json <<'EOF'
{
 "fields": {
  "title": {
   "type": "string",
   "required": true,
   "maxLength": 80
  },
  "description": {
   "type": "string",
   "required": true,
   "maxLength": 2000
  },
  "category": {
   "type": "string",
   "required": true,
   "enum": [
    "design",
    "development",
    "writing",
    "translation",
    "marketing"
   ]
  },
  "budget_cents": {
   "type": "integer",
   "required": true,
   "minimum": 5000,
   "maximum": 5000000
  }
 }
}
EOF
```

Seis requisições, escritas pelo curso, vêm de um programa e não de uma colagem, porque um deles tem cinco
mil caracteres e outro esconde caracteres que ninguém vê. Salve-o como `~/guard/tools/inputs.py`:

```python
# inputs.py: write the six job requests of lesson 9, one JSON object per line.
#
#   guard inputs > FILE
#
# WRITTEN BY THE COURSE: one good request and five that each break a rule.
# The long one and the one with invisible characters are built here rather
# than typed, because nobody can paste a 5,000-character line or see a
# zero-width space.
import json

GOOD = ("We are opening a bakery in Recife and need a logo that works on the "
        "shop sign, the packaging and Instagram.")
PASTED = "We need a logo. " + " ".join(
    ["Here is our whole brand history, pasted from a document."] * 90)
HIDDEN = ("Logo for a bakery​​​ in Recife, "
          "colours as in ‮the brief‬.")

base = {"title": "Logo for a bakery", "description": GOOD,
        "category": "design", "budget_cents": 120000}
requests = [
    {},
    {"description": PASTED},
    {"priority": "urgent"},
    {"category": "photography"},
    {"description": HIDDEN},
    {"budget_cents": "1.200,00"},
]
for n, change in enumerate(requests, 1):
    print(json.dumps(dict({"id": "in-%d" % n}, **dict(base, **change))))
```

```
ana@lab:~/guard$ guard inputs > data/inputs.jsonl
ana@lab:~/guard$ cat data/input-rules.json
{
 "fields": {
  "title": {
   "type": "string",
   "required": true,
   "maxLength": 80
  },
  "description": {
   "type": "string",
   "required": true,
   "maxLength": 2000
  },
  "category": {
   "type": "string",
   "required": true,
   "enum": [
    "design",
    "development",
    "writing",
    "translation",
    "marketing"
   ]
  },
  "budget_cents": {
   "type": "integer",
   "required": true,
   "minimum": 5000,
   "maximum": 5000000
  }
 }
}
ana@lab:~/guard$ head -1 data/inputs.jsonl
{"id": "in-1", "title": "Logo for a bakery", "description": "We are opening a bakery in Recife and need a logo that works on the shop sign, the packaging and Instagram.", "category": "design", "budget_cents": 120000}
```

As regras, e o schema da próxima seção, são conferidos por um módulo de Python simples. Salve-o como
`~/guard/tools/shapes.py`:

```python
# shapes.py: what goes into a model call, and what comes out of it, checked.
#
# check_input() holds a request to data/input-rules.json: which fields may be
# present, their types, lengths and closed values, and no invisible characters.
# validate() holds a reply to a JSON Schema, a small subset of it written out
# so that every rule can be read: type, required, properties,
# additionalProperties, enum, maxLength, minimum, maximum, pattern, items and
# maxItems. check_output() adds two rules a schema cannot express: links must
# point at an allowed host, and a price may not exceed twice the budget.
import json
import re
from urllib.parse import urlsplit

INVISIBLE = {0x200B: "zero width space", 0x200C: "zero width non-joiner",
             0x200D: "zero width joiner", 0x200E: "left-to-right mark",
             0x200F: "right-to-left mark", 0x202A: "left-to-right embedding",
             0x202B: "right-to-left embedding", 0x202C: "pop directional formatting",
             0x202D: "left-to-right override", 0x202E: "right-to-left override",
             0x2066: "left-to-right isolate", 0x2067: "right-to-left isolate",
             0x2068: "first strong isolate", 0x2069: "pop directional isolate",
             0xFEFF: "zero width no-break space"}
TYPES = {"string": str, "integer": int, "array": list, "object": dict}


def check_input(req, rules):
    problems = ["field %r is not accepted" % n for n in req if n not in rules["fields"]]
    for name, rule in rules["fields"].items():
        if name not in req:
            if rule.get("required"):
                problems.append("field %r is missing" % name)
            continue
        value = req[name]
        if not isinstance(value, TYPES[rule["type"]]) or isinstance(value, bool):
            problems.append("%s: expected %s, got %s" % (name, rule["type"], type(value).__name__))
            continue
        if "enum" in rule and value not in rule["enum"]:
            problems.append("%s: %r is not one of %s" % (name, value, ", ".join(rule["enum"])))
        if "maxLength" in rule and len(value) > rule["maxLength"]:
            problems.append("%s: %d characters, limit %d" % (name, len(value), rule["maxLength"]))
        if "minimum" in rule and value < rule["minimum"]:
            problems.append("%s: %d is below %d" % (name, value, rule["minimum"]))
        if "maximum" in rule and value > rule["maximum"]:
            problems.append("%s: %d is above %d" % (name, value, rule["maximum"]))
        if isinstance(value, str):
            seen = {}
            for ch in value:
                if ord(ch) in INVISIBLE or (ord(ch) < 32 and ch not in "\n\t"):
                    seen[ord(ch)] = seen.get(ord(ch), 0) + 1
            for cp, n in sorted(seen.items()):
                problems.append("%s: U+%04X %s x%d" % (
                    name, cp, INVISIBLE.get(cp, "control character"), n))
    return problems


def validate(value, schema, path="$"):
    """Every way value breaks schema, as a list. It keeps going after the first
    problem, so that a retry can be told everything that was wrong at once."""
    out = []
    t = schema.get("type")
    if t and (not isinstance(value, TYPES[t]) or isinstance(value, bool)):
        return ["%s: expected %s, got %s" % (path, t, type(value).__name__)]
    if "enum" in schema and value not in schema["enum"]:
        out.append("%s: %r is not one of %s" % (path, value, ", ".join(schema["enum"])))
    if isinstance(value, str):
        if "maxLength" in schema and len(value) > schema["maxLength"]:
            out.append("%s: %d characters, limit %d" % (path, len(value), schema["maxLength"]))
        if "pattern" in schema and not re.search(schema["pattern"], value):
            out.append("%s: %r does not match %s" % (path, value, schema["pattern"]))
    if isinstance(value, int) and not isinstance(value, bool):
        if "minimum" in schema and value < schema["minimum"]:
            out.append("%s: %d is below %d" % (path, value, schema["minimum"]))
        if "maximum" in schema and value > schema["maximum"]:
            out.append("%s: %d is above %d" % (path, value, schema["maximum"]))
    if isinstance(value, list):
        if "maxItems" in schema and len(value) > schema["maxItems"]:
            out.append("%s: %d items, limit %d" % (path, len(value), schema["maxItems"]))
        for i, item in enumerate(value):
            out += validate(item, schema.get("items", {}), "%s[%d]" % (path, i))
    if isinstance(value, dict):
        props = schema.get("properties", {})
        for name in schema.get("required", []):
            if name not in value:
                out.append("%s: %r is required" % (path, name))
        for name, v in value.items():
            if name in props:
                out += validate(v, props[name], path + "." + name)
            elif schema.get("additionalProperties") is False:
                out.append("%s: %r is not allowed" % (path, name))
    return out


def check_output(text, schema, hosts, budget):
    try:
        value = json.loads(text)
    except json.JSONDecodeError as e:
        return ["not JSON: %s at character %d" % (e.msg, e.pos)]
    problems = validate(value, schema)
    if isinstance(value, dict):
        links = value.get("links", [])
        for i, link in enumerate(links if isinstance(links, list) else []):
            host = urlsplit(link).hostname if isinstance(link, str) else None
            if host and host not in hosts:
                problems.append("$.links[%d]: host %s is not on the allowlist" % (i, host))
        price = value.get("price_suggestion_cents")
        if isinstance(price, int) and budget and price > 2 * budget:
            problems.append("$.price_suggestion_cents: %d is more than twice the budget of %d"
                            % (price, budget))
    return problems
```

O `guard check-in` roda a metade de entrada dele sobre um arquivo de requisições, o
`~/guard/tools/check-in.py`:

```python
# check-in.py: job requests against the input rules, before any model sees them.
#
#   guard check-in FILE
#
# FILE has one request per line. Exit status 1 if any request is rejected.
import json
import os
import sys

from shapes import check_input

with open(os.path.expanduser("~/guard/data/input-rules.json")) as f:
    rules = json.load(f)
bad = 0
with open(sys.argv[1], encoding="utf-8") as f:
    for line in f:
        req = json.loads(line)
        ident = req.pop("id")
        problems = check_input(req, rules)
        bad += bool(problems)
        if not problems:
            print("%-6s ok" % ident)
        for i, p in enumerate(problems):
            print("%-6s %-7s %s" % (ident if i == 0 else "", "REJECT" if i == 0 else "", p))
sys.exit(1 if bad else 0)
```

Cada uma das seis requisições quebra uma regra diferente, menos a primeira:

```
ana@lab:~/guard$ guard check-in data/inputs.jsonl; echo "exit $?"
in-1   ok
in-2   REJECT  description: 5145 characters, limit 2000
in-3   REJECT  field 'priority' is not accepted
in-4   REJECT  category: 'photography' is not one of design, development, writing, translation, marketing
in-5   REJECT  description: U+200B zero width space x3
               description: U+202C pop directional formatting x1
               description: U+202E right-to-left override x1
in-6   REJECT  budget_cents: expected integer, got str
exit 1
```

## O que cada regra compra

**Uma lista de campos aceitos.** O `in-3` traz um campo `priority` que o formulário nunca ofereceu. Um
montador de requisição que copia para o prompt todo campo que recebe transforma qualquer campo extra
numa instrução que o desenvolvedor nunca escreveu; aceitar só os campos nomeados fecha esse caminho
sem custo. É o mesmo movimento da lista de finalidade da aula 12, aplicado na outra direção.

**Listas fechadas onde a resposta é fechada.** `category` aceita um de cinco valores. *Photography*
pode ser uma ótima categoria para a Tarefa acrescentar um dia. Até lá é um valor que o resto do
sistema não sabe tratar, então é recusado na porta, com uma mensagem que diz quais valores existem.

**Tipos, e dinheiro como centavos inteiros.** O `in-6` manda o orçamento como o texto `"1.200,00"`, que
é como um brasileiro escreve e que um parser pode ler como um vírgula dois, como mil e duzentos, ou não
ler. A regra exige um número inteiro de centavos, que só tem uma leitura.

**Um tamanho.** O `in-2` tem 5.145 caracteres, a maioria um histórico da empresa colado de um documento.
Dois mil caracteres é a escolha do curso para uma descrição de trabalho. O limite protege a conta, já
que cada caractere é pago como token de entrada em cada chamada, e também limita quanto material pode
distrair o modelo.

**Nenhum caractere invisível.** O `in-5` parece, na maioria das telas, uma frase comum sobre uma
padaria em Recife. Ele contém três espaços de largura zero e um override da direita para a esquerda,
que inverte como o texto depois dele é desenhado. O modelo lê os caracteres na ordem em que estão
gravados, e uma pessoa revisando a requisição os vê na ordem em que são desenhados. **Texto que se lê
diferente para a pessoa e para o modelo** não tem lugar legítimo numa descrição de trabalho, então a
regra lista esses caracteres pelo código e os recusa.

## Recusar ou limpar

Toda regra aqui recusa a requisição e diz por quê, e a alternativa, consertar em silêncio, tenta:
cortar a descrição em 2.000 caracteres, descartar o campo desconhecido, tirar os caracteres
invisíveis. Limpar é certo quando o conserto é certo e inofensivo, como aparar espaços nas pontas de
um título. É errado quando muda o que a pessoa quis dizer sem avisá-la. Uma descrição cortada em 2.000
caracteres pode perder a única frase que importava, e um cliente que conhece o limite pode escolher o
que cortar.
