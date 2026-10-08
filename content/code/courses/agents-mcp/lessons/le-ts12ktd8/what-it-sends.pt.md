---
title: O que o SDK põe no fio
version: 2
---

Uma biblioteca que monta pedidos por você está fazendo escolhas que o seu código não mostra. O log do gravador mostra. Aqui está o caminho para onde o SDK mandou, a definição de ferramenta que ele mandou para `get_order` e os tipos de item no `input` do pedido depois que ele rodou a ferramenta:

```
ana@lab:~/agents$ tail -n 1 requests.jsonl | python -c 'import json, sys; r = json.loads(sys.stdin.read()); print(r["path"]); print(json.dumps(r["request"]["tools"][0], indent=1)); print([i.get("type", i.get("role")) for i in r["request"]["input"]])'
/v1/responses
{
 "name": "get_order",
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
 "strict": true,
 "type": "function",
 "description": "Look up one Marginalia order by its id, M- and four digits. Returns status, dates, lines and amounts in cents."
}
['user', 'function_call', 'function_call_output']
```

O caminho é `/v1/responses`, e o formato é o da Responses API: os campos da ferramenta ficam no nível de cima (`name`, `parameters`, `description`), e não dentro de um objeto `function` como no Chat Completions da aula 4, e a conversa é uma lista chamada `input` de itens tipados, `user`, `function_call` e `function_call_output`, e não de mensagens com papéis. Mais três coisas nessa saída são decisões do SDK, não suas.

**`"strict": true`.** O SDK pede ao fornecedor que restrinja os argumentos do modelo exatamente ao esquema, que é o modo estrito citado na aula 4, seção 04. Para isso funcionar o esquema precisa seguir as regras estritas do fornecedor, então o SDK acrescenta `"additionalProperties": false` e torna toda propriedade obrigatória. O `strict_mode=True` do decorador é o padrão. Se o Ollama restringe o `llama3.2:3b` por ele, o pedido não tem como dizer; a validação que você vê na seção 05 é a do próprio SDK, feita depois que a resposta chega.

**Campos `"title"`.** O Pydantic gera um título para cada propriedade (`"Order Id"`) e para o objeto inteiro (`"get_order_args"`). Eles custam tokens em todo pedido e não dizem ao modelo nada que o nome não diga; inofensivos, e um exemplo do que um esquema gerado carrega e um escrito à mão não carregaria.

**O resultado é Python, não JSON.** Os itens da primeira execução mostram o resultado como `{'id': 'M-1043', 'customer_id'...`: aspas simples, e `None` onde o JSON diria `null`. O `get_order` devolveu um dicionário, e o SDK o transformou em texto com o `str()` do Python. Um modelo lê isso razoavelmente, e as regras da aula 3 para observações continuam valendo: um resultado que deve ser lido como dado fica mais claro em JSON. **Devolva uma string montada com `json.dumps(...)`** se o que o modelo lê importa para você: o SDK passa uma string sem mexer, e transforma quase todo outro valor, um modelo Pydantic incluído, em texto com `str()`.

Nenhuma dessas é um defeito. Cada uma é um padrão que alguém escolheu, e conhecê-lo é a diferença entre um agente que você sabe explicar e um que você só sabe rodar.
