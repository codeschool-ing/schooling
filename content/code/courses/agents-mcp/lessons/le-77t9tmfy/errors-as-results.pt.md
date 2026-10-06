---
title: Erros são resultados
version: 1
---

Uma ferramenta que falha tem dois jeitos de falhar: pode derrubar o hospedeiro junto, ou pode dizer ao modelo o que deu errado. Só o segundo dá ao modelo a chance de se recuperar, e só o segundo deixa a execução num estado que alguém consegue explicar.

```
ana@lab:~/agents$ python agent.py "What happened to my order M-9999?"
[1] get_order({"order_id": "M-9999"}) -> ERROR LookupError: no order M-9999
[2] answer: I cannot find an order M-9999. Could you check the number in your confirmation email? It starts with M- and has four digits.
```

O `M-9999` bateu com o padrão, então o esquema o deixou passar, e o `get_order` levantou `LookupError: no order M-9999`. O `run_tool` pegou o erro e devolveu a mensagem como erro. O modelo, roteirizado pelo curso para este caso, fez a coisa útil: disse ao cliente que o pedido não foi encontrado e como é um número de pedido. **Nada caiu, nada foi adivinhado, e o cliente tem o que fazer em seguida.**

## O que vai num erro

- **O que falhou, de forma específica.** `no order M-9999` é melhor que `lookup failed`; `'five' is not of type 'integer'` é melhor que `bad request`.
- **O que daria certo, quando se sabe.** A mensagem de ferramenta desconhecida lista as ferramentas que existem. Um reembolso recusado por passar do saldo diz quanto sobra (`0 left to refund`, seção 09).
- **Nada que o modelo não deva ver.** Nada de stack traces, caminhos de arquivo, SQL, nomes de máquinas internas ou chaves. Uma mensagem de erro é um resultado de ferramenta: vai para o fornecedor, fica na conversa e aparece nos rastros.

## Quais erros pegar

O `run_tool` pega `LookupError` e `ValueError` e deixa todo o resto se propagar. Essa linha é deliberada, e segue a regra deste próprio repositório de que falha silenciosa é proibida. Um pedido inexistente ou um valor alto demais são falhas **esperadas**: o modelo pode fazer algo a respeito, então elas viram resultados. Um arquivo de banco que não abre, ou um bug no `find_books`, não é coisa que um modelo conserte tentando outro argumento; transformar isso num resultado educado esconderia uma pane atrás de uma conversa que parece normal. Esses devem parar a execução com barulho e chegar a quem opera o agente.

## `is_error` é um sinal, não enfeite

A API da Anthropic tem um campo `is_error` no `tool_result`; as mensagens de ferramenta da OpenAI e do Google não têm, e a convenção ali é pôr o erro no conteúdo, muitas vezes como `{"error": "..."}`. De um jeito ou de outro o ponto é o mesmo: o modelo precisa distinguir uma falha de um dado. Um resultado `"no order M-9999"` sem marcação poderia ser lido como um pedido cujo status é essa frase.
