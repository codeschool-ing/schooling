---
title: Uma ferramenta é um contrato
version: 2
---

Um modelo decide que ferramenta chamar a partir de três coisas, e as três são texto que você
escreve: o **nome** da ferramenta, a **descrição** e o **esquema** dos argumentos. É assim que o
servidor da loja descreve a primeira ferramenta no fio, cortado na largura da página:

```
ana@dev:~/shop$ ( printf "%s\n" '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"by-hand","version":"0"}}}' '{"jsonrpc":"2.0","method":"notifications/initialized"}' '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_order","arguments":{"order_id":"1043"}}}'; sleep 2 ) | python mcp_shop.py | cut -c1-160
{"jsonrpc":"2.0","id":1,"result":{"capabilities":{"experimental":{},"prompts":{"listChanged":false},"resources":{"listChanged":false,"subscribe":false},"tools":
{"jsonrpc":"2.0","id":2,"result":{"tools":[{"annotations":{"readOnlyHint":true},"description":"Look up an order by its number: status, dates, lines and shipping
{"jsonrpc":"2.0","id":3,"result":{"content":[{"text":"{\n  \"status\": \"shipped\",\n  \"shipped_on\": \"2026-09-30\",\n  \"tracking\": \"BR123456789\",\n  \"li
```

A segunda linha é a lista de ferramentas. Depois do corte, o `get_order` tem uma descrição (*Look up
an order by its number: status, dates, lines and shipping, in cents*) e um esquema dizendo que recebe
uma string, `order_id`, obrigatória. **É tudo o que o modelo sabe da função.** Ele nunca viu o código,
então uma descrição que diz menos que o código é um contrato que o modelo vai quebrar de boa-fé.

## Escrevendo ferramentas que um modelo usa bem

- **Estreitas, com um trabalho cada.** `get_order` e `issue_refund`, não `manage_order(action, ...)`.
  Uma ferramenta estreita é mais fácil de descrever, de permitir (aula 7 seção 08) e de testar.
- **Diga as unidades e os formatos.** O "in cents" na descrição do `get_order` é o que deixa o modelo
  escrever 79,80 e não 7980,00 na resposta. Datas, moedas, ids: a descrição é o único lugar onde o
  modelo os aprende.
- **Argumentos tipados, obrigatórios onde são obrigatórios.** O esquema é imposto pelo servidor (a
  aula 8 mostra o mesmo para chamada de funções), então um argumento faltando ou com tipo errado é
  recusado antes de o seu código rodar.
- **Resultados que o modelo consegue usar.** Simples, curtos, com os nomes de campo que lhe disseram.
  Uma ferramenta que devolve um log de 5.000 linhas enche o contexto e custa a entrada do passo
  seguinte.
- **Erros que dizem o que fazer.** `'../../.env' is not a page of the handbook` diz ao modelo que
  escolha um nome de página; um stack trace não diz nada e custa tokens.
- **Só leitura quando for.** Uma ferramenta que não muda nada diz isso nas anotações, e o host pode
  então chamá-la sem perguntar (aula 7 seção 08).

O número de ferramentas também importa. Toda definição vai em toda requisição (a aula 2 seção 03
contou 128 tokens para uma), e um modelo escolhendo entre quarenta ferramentas parecidas escolhe pior
que um escolhendo entre cinco. Dê a um agente as ferramentas de que a tarefa dele precisa.
