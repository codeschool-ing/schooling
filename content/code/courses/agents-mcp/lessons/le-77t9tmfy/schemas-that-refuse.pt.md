---
title: Um esquema que recusa
version: 2
---

A crença errada é que um esquema é documentação para o modelo: ele lista os argumentos e seus tipos, e o modelo os preenche. Os fornecedores o usam assim, sim. **No hospedeiro ele também é uma verificação, e um esquema que não recusa nada não verifica nada.** `{"type": "object", "properties": {"order_id": {"type": "string"}}}` aceita `{"order_id": "the book I bought last week"}`, e `{}`, e `{"order_id": "M-1043", "delete": true}`.

As palavras-chave que transformam uma descrição numa recusa:

| palavra-chave | o que ela recusa | no `tools.py` |
|---|---|---|
| `required` | um argumento faltando | `order_id`; os quatro do `issue_refund` |
| `additionalProperties: false` | um argumento que ninguém declarou | toda ferramenta |
| `type` | uma string onde vai um número | `max_results`, `cents` |
| `pattern` | uma string no formato errado | `^M-[0-9]{4}$` para ids de pedido |
| `enum` | um valor fora de uma lista fechada | os oito gêneros |
| `minimum`, `maximum` | um número fora da faixa | de 1 a 10 resultados; pelo menos 1 centavo |
| `minLength` | uma string vazia ou simbólica | um motivo de pelo menos 3 caracteres |

Rodando direto contra o `run_tool`, antes de qualquer modelo entrar na história:

```
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"get_order\", {\"order_id\": \"1043\"}))"
("invalid arguments: order_id: '1043' does not match '^M-[0-9]{4}$'", True)
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"find_books\", {\"genre\": \"mystery\", \"max_results\": \"five\"}))"
("invalid arguments: max_results: 'five' is not of type 'integer'", True)
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"get_order\", {\"order_id\": \"M-1043\", \"verbose\": True}))"
("invalid arguments: arguments: Additional properties are not allowed ('verbose' was unexpected)", True)
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"get_order\", {\"order_id\": \"M-9999\"}))"
('LookupError: no order M-9999', True)
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"cancel_order\", {\"order_id\": \"M-1045\"}))"
("unknown tool 'cancel_order'; the tools are get_order, find_books, issue_refund", True)
```

Cada recusa nomeia o argumento e a regra que ele quebrou, em palavras com que um modelo consegue agir: `'1043' does not match '^M-[0-9]{4}$'` diz a quem lê exatamente que formato era esperado. A quarta linha passou no esquema e falhou na função, porque o M-9999 tem a forma certa e não existe; **um esquema confere forma, nunca fatos.** A última linha nem chegou a um esquema: `cancel_order` não é ferramenta, e a mensagem lista as que são.

## Quão rígido ser

Rígido onde um erro custa algo, solto onde não custa. Um id de pedido tem uma forma só, então um padrão não custa nada e pega todo erro de digitação. Uma consulta de busca em texto livre não deveria ter padrão: ali ele recusa perguntas legítimas. `additionalProperties: false` vale a pena em todo lugar, porque um argumento que a função não espera é invenção de um modelo ou alguém sondando por um.

Alguns fornecedores também oferecem um modo estrito, que restringe a geração do modelo para que os argumentos sempre batam com o esquema. Ele é útil, e não substitui a verificação do hospedeiro. É uma promessa do fornecedor, aceita um subconjunto do JSON Schema, e o hospedeiro continua sendo o último lugar que pode recusar uma chamada antes de ela rodar. Este curso não o usa: a checagem que vale aprender é a do hospedeiro, que funciona seja qual for a oferta do fornecedor.
