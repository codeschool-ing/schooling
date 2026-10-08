---
title: Erros são resultados
version: 2
---

Uma ferramenta que falha tem dois jeitos de falhar: pode derrubar o hospedeiro junto, ou pode dizer ao modelo o que deu errado. Só o segundo dá ao modelo a chance de se recuperar, e só o segundo deixa a execução num estado que alguém consegue explicar.

```
ana@lab:~/agents$ python agent.py "What happened to my order M-9999?"
[1] get_order({"order_id": "M-9999"}) -> ERROR LookupError: no order M-9999
[2] answer: It appears that the order M-9999 does not exist in our database. I couldn't find any information about an order with that specific ID. If you could provide more context or details about the order, such as the date or time it was placed, I may be able to help you better.

Alternatively, you can also try checking the order status by contacting our customer service team directly. They will be able to look up the order and provide you with the most up-to-date information.
```

O `M-9999` bateu com o padrão, então o esquema o deixou passar, e o `get_order` levantou `LookupError: no order M-9999`. O `run_tool` pegou o erro e devolveu a mensagem como erro. O modelo leu a mensagem e fez a coisa útil: disse ao cliente que o pedido não existe e pediu algo pelo qual encontrá-lo. **Nada caiu, e o cliente tem o que fazer em seguida.** Ele também mandou o cliente para "our customer service team", que é justamente o que este agente é; um erro dá os fatos ao modelo, e o que ele faz com eles continua sendo dele.

## O que vai num erro

- **O que falhou, de forma específica.** `no order M-9999` é melhor que `lookup failed`; `'five' is not of type 'integer'` é melhor que `bad request`.
- **O que daria certo, quando se sabe.** A mensagem de ferramenta desconhecida lista as ferramentas que existem. Um reembolso recusado por passar do saldo diz quanto sobra (`0 left to refund`, seção 09).
- **Nada que o modelo não deva ver.** Nada de stack traces, caminhos de arquivo, SQL, nomes de máquinas internas ou chaves. Uma mensagem de erro é um resultado de ferramenta: vai para o fornecedor, fica na conversa e aparece nos rastros.

## Quais erros pegar

O `run_tool` pega `LookupError` e `ValueError` e deixa todo o resto se propagar. Essa linha é deliberada, e segue a regra deste próprio repositório de que falha silenciosa é proibida. Um pedido inexistente ou um valor alto demais são falhas **esperadas**: o modelo pode fazer algo a respeito, então elas viram resultados. Um arquivo de banco que não abre, ou um bug no `find_books`, não é coisa que um modelo conserte tentando outro argumento; transformar isso num resultado educado esconderia uma pane atrás de uma conversa que parece normal. Esses devem parar a execução com barulho e chegar a quem opera o agente.

## `is_error` é um sinal, não enfeite

A API da Anthropic tem um campo `is_error` no `tool_result`; as mensagens de ferramenta da OpenAI e do Google não têm esse campo, nem as do próprio Ollama, e a convenção ali é pôr o erro no conteúdo, muitas vezes como `{"error": "..."}`. De um jeito ou de outro o ponto é o mesmo: o modelo precisa distinguir uma falha de um dado. Um resultado `"no order M-9999"` sem marcação poderia ser lido como um pedido cujo status é essa frase.
