---
title: Ferramentas a partir de funções tipadas
version: 1
---

A aula 4 escreveu o esquema de cada ferramenta à mão, ao lado da função, e manteve os dois em sincronia com cuidado. O `minagent` escreve o esquema a partir da função: os nomes dos parâmetros, as dicas de tipo e a docstring já são uma descrição da ferramenta, então o decorador os lê.

```schooling-example
{
  "language": "python",
  "file": "minagent.py",
  "parts": [
    {
      "code": "# ---------------------------------------------------------------- tools from functions\n\n"
    },
    {
      "code": "TYPES = {str: {\"type\": \"string\"}, int: {\"type\": \"integer\"}, float: {\"type\": \"number\"}, bool: {\"type\": \"boolean\"}}\n\n\ndef schema_for(annotation):\n    \"\"\"The JSON Schema for one parameter's type hint. A type it does not know is refused, not guessed.\"\"\"\n    if isinstance(annotation, type) and annotation in TYPES:\n        return dict(TYPES[annotation])\n    origin, args = typing.get_origin(annotation), typing.get_args(annotation)\n",
      "note": "**Quatro tipos Python têm um JSON Schema óbvio.** Qualquer outro precisa de uma regra abaixo, ou de uma recusa."
    },
    {
      "code": "    if origin is typing.Annotated:\n        return {**schema_for(args[0]), **args[1]}\n",
      "note": "**`Annotated` carrega palavras-chave extras de esquema**: `Annotated[str, {\"pattern\": \"^M-[0-9]{4}$\"}]` é uma string com padrão."
    },
    {
      "code": "    if origin is typing.Literal:\n        return {\"enum\": list(args)}\n    if origin is list and len(args) == 1:\n        return {\"type\": \"array\", \"items\": schema_for(args[0])}\n",
      "note": "**`Literal` vira um enum**, que é como os gêneros são declarados."
    },
    {
      "code": "    raise TypeError(f\"no JSON Schema for {annotation!r}; write this tool's schema by hand\")\n\n\n@dataclass\n",
      "note": "**Um tipo desconhecido é recusado, nunca adivinhado.** Um parâmetro `dict` poderia ser qualquer coisa, e um esquema que aceita qualquer coisa não confere nada (aula 4)."
    },
    {
      "code": "class Tool:\n    name: str\n    description: str\n    schema: dict\n    fn: typing.Callable\n    writes: bool = False\n\n    def definition(self):\n        return {\"name\": self.name, \"description\": self.description, \"input_schema\": self.schema}\n\n\n",
      "note": "**O que é uma ferramenta**: um nome, uma descrição, um esquema, a função, e se ela escreve."
    },
    {
      "code": "def tool(fn=None, *, writes=False):\n    \"\"\"Turn a typed, documented function into a Tool. Its docstring is what the model reads.\"\"\"\n    def make(f):\n",
      "note": "**O decorador.** Funciona puro, `@tool`, ou com argumento, `@tool(writes=True)`."
    },
    {
      "code": "        doc = inspect.getdoc(f)\n        if not doc:\n            raise ValueError(f\"{f.__name__} has no docstring, and the docstring is the tool's description\")\n        hints = typing.get_type_hints(f, include_extras=True)\n        props, required = {}, []\n",
      "note": "**Sem docstring, sem ferramenta.** A docstring é a descrição que o modelo lê, e uma ferramenta sem ela é uma ferramenta sobre a qual o modelo precisa adivinhar."
    },
    {
      "code": "        for name, p in inspect.signature(f).parameters.items():\n            if name not in hints:\n                raise TypeError(f\"{f.__name__}: parameter {name!r} has no type hint\")\n            props[name] = schema_for(hints[name])\n            if p.default is inspect.Parameter.empty:\n                required.append(name)\n        schema = {\"type\": \"object\", \"properties\": props, \"required\": required, \"additionalProperties\": False}\n        return Tool(f.__name__, doc, schema, f, writes)\n    return make(fn) if fn else make\n\n",
      "note": "**Todo parâmetro precisa de dica de tipo**; um com valor padrão é opcional, os demais são obrigatórios."
    }
  ]
}
```

O `marginalia.py` declara as ferramentas da loja com ele. Os tipos fazem o trabalho que os esquemas escritos à mão faziam na aula 4:

```python
"""Marginalia's tools for minagent: the functions of shop.py, typed and documented."""
from typing import Annotated, Literal

import shop
from minagent import tool

OrderId = Annotated[str, {"pattern": "^M-[0-9]{4}$"}]
Genre = Literal["adventure", "children", "horror", "literary", "mystery", "non-fiction", "romance",
                "science fiction"]


@tool
def get_order(order_id: OrderId) -> dict:
    """Look up one Marginalia order by its id, M- and four digits, such as M-1042.
    Returns status, dates, lines and amounts in cents."""
    return shop.get_order(order_id)


@tool
def search_help(query: str) -> list:
    """Search Marginalia's help centre by meaning and return the three closest articles."""
    return [{"id": a["id"], "title": a["title"], "body": a["body"]} for a in shop.search_help(query)]


@tool
def find_books(genre: Genre, max_results: Annotated[int, {"minimum": 1, "maximum": 10}] = 3) -> list:
    """List books in stock in one genre, cheapest first, with prices in cents."""
    import json
    books = [shop.get_book(json.loads(line)["id"]) for line in open(shop.DATA / "books.jsonl")]
    stocked = sorted((b for b in books if b["genre"] == genre and b["stock"] > 0), key=lambda b: b["cents"])
    return [{"title": b["title"], "author": b["author"], "cents": b["cents"]} for b in stocked[:max_results]]


@tool(writes=True)
def refund(order_id: OrderId, cents: int, reason: str) -> dict:
    """Refund part or all of an order to the customer's original payment, in cents."""
    return shop.refund(order_id, cents, reason, approved_by="minagent")


TOOLS = [get_order, search_help, find_books, refund]
```

O que o decorador produziu, e o que ele recusa:

```
ana@lab:~/agents$ python -c "import json; from marginalia import get_order, find_books; print(json.dumps(get_order.definition(), indent=1)); print(json.dumps(find_books.schema))"
{
 "name": "get_order",
 "description": "Look up one Marginalia order by its id, M- and four digits, such as M-1042.\nReturns status, dates, lines and amounts in cents.",
 "input_schema": {
  "type": "object",
  "properties": {
   "order_id": {
    "type": "string",
    "pattern": "^M-[0-9]{4}$"
   }
  },
  "required": [
   "order_id"
  ],
  "additionalProperties": false
 }
}
{"type": "object", "properties": {"genre": {"enum": ["adventure", "children", "horror", "literary", "mystery", "non-fiction", "romance", "science fiction"]}, "max_results": {"type": "integer", "minimum": 1, "maximum": 10}}, "required": ["genre"], "additionalProperties": false}
ana@lab:~/agents$ python -c "from minagent import tool
@tool
def lookup(filters: dict) -> list:
    \"\"\"Look things up.\"\"\"" 2>&1 | tail -n 1
TypeError: no JSON Schema for <class 'dict'>; write this tool's schema by hand
```

A definição do `get_order` está exatamente no formato que a API da Anthropic recebe, montada a partir de uma assinatura e de uma docstring. O esquema do `find_books` traz o enum do `Genre` e os limites do `Annotated`. E uma função com parâmetro `dict` é recusada na importação, com uma mensagem dizendo o que fazer no lugar. **A falha acontece quando o código é escrito, não quando um modelo manda um dicionário que ninguém esperava.**

## A troca

Derivar esquemas dos tipos impede que os dois se desencontrem: mude a assinatura da função e o esquema acompanha. Também limita o que o esquema pode dizer ao que o sistema de tipos expressa, mais o que o `Annotated` acrescenta. Isso basta para a maioria das ferramentas. Para o resto, um `Tool` pode ser montado à mão com qualquer esquema; o decorador é uma conveniência, e o laço não se importa com como um `Tool` foi feito. Todo SDK das aulas 8 a 10 faz a mesma troca, com um decorador próprio: `function_tool`, `tool`, ou uma função comum que o framework inspeciona.
