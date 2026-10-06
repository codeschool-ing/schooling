---
title: O que o SDK põe no fio
version: 1
---

Uma biblioteca que monta pedidos por você está fazendo escolhas que o seu código não mostra. O log do labllm mostra. Aqui está a definição de ferramenta que o SDK mandou para `get_order`, e o começo do resultado de ferramenta que ele mandou de volta depois de rodá-la:

```
ana@lab:~/agents$ tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; r = json.loads(sys.stdin.read()); print(json.dumps(r["request"]["tools"][0], indent=1)); print(r["request"]["messages"][3]["content"][:120])'
{
 "type": "function",
 "function": {
  "name": "get_order",
  "description": "Look up one Marginalia order by its id, M- and four digits. Returns status, dates, lines and amounts in cents.",
  "parameters": {
   "properties": {
    "order_id": {
     "pattern": "^M-[0-9]{4}$",
     "title": "Order Id",
     "type": "string"
    }
   },
   "required": [
    "order_id"
   ],
   "title": "get_order_args",
   "type": "object",
   "additionalProperties": false
  },
  "strict": true
 }
}
{'id': 'M-1043', 'customer_id': 'c-102', 'placed_on': '2026-09-28', 'status': 'shipped', 'delivered_on': None, 'shipping
```

Três coisas nessa saída são decisões do SDK, não suas.

**`"strict": true`.** O SDK pede ao fornecedor que restrinja os argumentos do modelo exatamente ao esquema, que é o modo estrito citado na aula 4, seção 04. Para isso funcionar o esquema precisa seguir as regras estritas do fornecedor, então o SDK acrescenta `"additionalProperties": false` e torna toda propriedade obrigatória. O `strict_mode=True` do decorador é o padrão; o labllm ignora a flag, então neste laboratório a validação que você vê na seção 05 é a do próprio SDK, feita depois que a resposta chega.

**Campos `"title"`.** O Pydantic gera um título para cada propriedade (`"Order Id"`) e para o objeto inteiro (`"get_order_args"`). Eles custam tokens em todo pedido e não dizem ao modelo nada que o nome não diga; inofensivos, e um exemplo do que um esquema gerado carrega e um escrito à mão não carregaria.

**O resultado é Python, não JSON.** A segunda linha começa com `{'id': 'M-1043', ... 'delivered_on': None`: aspas simples e `None`. O `get_order` devolveu um dicionário, e o SDK o transformou em texto com o `str()` do Python. Um modelo lê isso razoavelmente, e as regras da aula 3 para observações continuam valendo: um resultado que deve ser lido como dado fica mais claro em JSON. **Devolva uma string montada com `json.dumps(...)`** se o que o modelo lê importa para você: o SDK passa uma string sem mexer, e transforma quase todo outro valor, um modelo Pydantic incluído, em texto com `str()`.

Nenhuma dessas é um defeito. Cada uma é um padrão que alguém escolheu, e conhecê-lo é a diferença entre um agente que você sabe explicar e um que você só sabe rodar.
