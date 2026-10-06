---
title: Um prompt
version: 1
---

A terceira primitiva é a que uma **pessoa** escolhe. Um hospedeiro mostra os prompts do servidor como algo parecido com comandos de barra; a pessoa escolhe um e preenche os argumentos, e o hospedeiro põe as mensagens resultantes na conversa.

```
ana@lab:~/agents$ python try_server.py prompt 2> server.log
prompt: reply_to_customer [('order_id', True), ('question', True)]
user: A customer asks about order M-1042: Can I still return it?
Look the order up with get_order, check the help centre if a policy applies, and draft a short reply. Quote dates and amounts exactly as the tools return them.
```

O `reply_to_customer` tem dois argumentos obrigatórios, e o `prompts/get` devolveu uma mensagem de usuário com os dois preenchidos. O texto diz ao modelo como trabalhar: consultar o pedido, conferir a central de ajuda, citar datas e valores exatamente.

Dois pontos sobre ele. **Um prompt é o texto do servidor entrando na conversa**, como a descrição de uma ferramenta, mas desta vez como mensagem de usuário, escolhida por uma pessoa que pode não lê-la antes. Vale o mesmo juízo: conecte servidores cujas palavras você aceitaria no seu prompt. E **um prompt não é uma permissão**. Ele diz *look the order up with get_order*; se o `get_order` pode rodar, e se um reembolso precisaria de uma pessoa, continua sendo decidido pelo hospedeiro quando o modelo pede.
