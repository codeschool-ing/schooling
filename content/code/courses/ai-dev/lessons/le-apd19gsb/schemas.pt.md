---
title: O esquema é um contrato
version: 2
---

O modelo preenche os argumentos escrevendo JSON. Nada nessa escrita é conferido pelo próprio modelo,
então **o esquema na definição da ferramenta é o único lugar onde o formato está escrito**, e o
host é o único lugar onde ele pode ser cobrado. Esta seção escreve um esquema que dá para cobrar e
olha o que um verificador diz sobre argumentos ruins.

## Uma ferramenta que muda algo

O `create_return` abre uma devolução. O esquema dele é mais estrito que o do `get_stock`, porque um
argumento errado aqui é uma devolução aberta para a coisa errada:

```python
    {
        "name": "create_return",
        "description": "Open a return for units of one line of a delivered order. "
                       "Use it only when the customer has asked to return something.",
        "input_schema": {
            "type": "object",
            "properties": {
                "order_id": {"type": "string", "pattern": "^[0-9]{4}$", "description": "Such as 1042."},
                "sku": {"type": "string", "description": "The SKU as it appears on the order line."},
                "quantity": {"type": "integer", "minimum": 1},
                "reason": {"type": "string", "enum": REASONS},
            },
            "required": ["order_id", "sku", "quantity", "reason"],
            "additionalProperties": False,
        },
    },
```

Cada palavra-chave fecha uma porta:

- **`type` e `pattern`** dizem como é um número de pedido. Números de pedido são strings nos dados
  da loja, então `1042` como número erraria toda consulta.
- **`minimum`** diz que devolver zero canecas não é devolução.
- **`enum`** transforma o motivo numa de quatro palavras que o depósito entende, em vez de uma frase
  pela qual ninguém consegue ordenar.
- **`required` e `additionalProperties: false`** dizem exatamente que chaves existem. Uma chave que
  o modelo inventa vira erro, em vez de algo ignorado em silêncio.

A descrição faz outro trabalho. **Ela diz quando usar a ferramenta**, e "só quando o cliente pediu"
é dirigido ao modelo, que a lê em toda requisição.

## Conferindo uma chamada contra ele

O esquema é JSON Schema comum, então um validador qualquer o lê. O `check_args.py` lista todos os
problemas, não só o primeiro:

```schooling-example
{
  "language": "python",
  "file": "check_args.py",
  "parts": [
    {
      "code": "\"\"\"Check a tool call's arguments against the tool's own schema, and list every problem.\"\"\"\nimport json\nimport sys\n\nfrom jsonschema import Draft202012Validator\n\nfrom shop_tools import TOOLS\n\n"
    },
    {
      "code": "SCHEMAS = {t[\"name\"]: t[\"input_schema\"] for t in TOOLS}\n\n\n",
      "note": "**Os esquemas são os que o modelo recebe**, lidos de `TOOLS`, então a checagem e a requisição não têm como se separar."
    },
    {
      "code": "def problems(name, args):\n    v = Draft202012Validator(SCHEMAS[name])\n    return [f\"{'.'.join(map(str, e.path)) or '(top)'}: {e.message}\"\n            for e in sorted(v.iter_errors(args), key=lambda e: list(map(str, e.path)))]\n\n\n",
      "note": "**Todo problema, não só o primeiro**, cada um com o caminho do campo de que trata."
    },
    {
      "code": "if __name__ == \"__main__\":\n    for p in problems(sys.argv[1], json.loads(sys.argv[2])) or [\"ok\"]:\n        print(p)\n",
      "note": "**Pela linha de comando**, um nome de ferramenta e os argumentos em JSON."
    }
  ]
}
```

Três conjuntos de argumentos, escritos à mão para cada um mostrar um tipo de falha. O primeiro está
escrito como um modelo plausivelmente escreveria:

```
ana@dev:~/shop$ python check_args.py create_return '{"order_id": 1042, "sku": "MUG-01", "quantity": 1, "reason": "customer changed their mind"}'
order_id: 1042 is not of type 'string'
reason: 'customer changed their mind' is not one of ['changed_mind', 'wrong_item', 'damaged', 'faulty']
ana@dev:~/shop$ python check_args.py create_return '{"order_id": "1042", "sku": "MUG-01", "quantity": 0, "note": "box unopened"}'
(top): 'reason' is a required property
(top): Additional properties are not allowed ('note' was unexpected)
quantity: 0 is less than the minimum of 1
ana@dev:~/shop$ python check_args.py create_return '{"order_id": "1042", "sku": "MUG-01", "quantity": 1, "reason": "changed_mind"}'
ok
```

**A primeira chamada parece certa para uma pessoa.** "Customer changed their mind" é o motivo, 1042
é o pedido. Ela falha duas vezes mesmo assim: o número não é string, e o motivo é uma frase onde o
depósito espera uma palavra. A segunda mostra uma chave que ninguém definiu, uma que falta e um
zero. A terceira é a chamada com que a loja consegue agir.

## O que um esquema não consegue dizer

Um esquema confere formato. Ele não sabe que o pedido 1042 existe, que foi entregue, nem que tinha
duas canecas e não três. **Essas são as regras da loja, e elas moram no código da loja**, que a
aula 8 seção 04 roda depois de o esquema passar. Tentar espremê-las no esquema dá um esquema que
ninguém consegue ler e regras que continuam com buracos.
