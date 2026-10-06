---
title: O que volta para o modelo
version: 1
---

A observação é o único jeito de o mundo chegar ao modelo, então o que uma ferramenta devolve molda todos os passos depois dela. Ela também viaja em todo pedido seguinte, o que faz do tamanho dela um custo pago de novo a cada passo.

```
ana@lab:~/agents$ python -c 'import json, shop, tiktoken; enc = tiktoken.get_encoding("o200k_base"); o = shop.get_order("M-1047"); small = {k: o[k] for k in ("status", "delivered_on", "total")}; print(len(enc.encode(json.dumps(o))), len(enc.encode(json.dumps(small))))'
105 27
ana@lab:~/agents$ python -c 'import json, shop, tiktoken; enc = tiktoken.get_encoding("o200k_base"); print(len(enc.encode(json.dumps(shop.search_help("refund after a return")))))'
228
```

O M-1047 inteiro, como o `get_order` o devolve, tem 105 tokens. Os três campos de que a pergunta de reembolso precisa (`status`, `delivered_on`, `total`) têm 27. Os três artigos de ajuda que o `search_help` devolve têm 228. Numa execução de três passos, uma observação devolvida no passo 1 é mandada também nos passos 2 e 3, então cortá-la economiza os tokens dela duas vezes; numa execução de vinte passos, dezenove. **Devolva o que o modelo precisa para decidir o próximo passo, e nada que ele tenha de atravessar.**

Cortar também tem custo: um campo deixado de fora é um campo que o modelo não pode usar. O `customer_id` parece irrelevante para uma pergunta de reembolso, e é exatamente o que a aula 17 precisa para conferir que quem pergunta é dono do pedido. O meio-termo comum é uma ferramenta por finalidade (um resumo do pedido para o agente, o registro completo para o código que precisa dele) em vez de uma ferramenta que devolve tudo.

## Quatro regras para observações

- **Estruturadas, e rotuladas.** `{"status": "delivered", "delivered_on": "2026-09-18"}` é melhor que `delivered 2026-09-18`, porque o modelo não precisa adivinhar qual data é qual.
- **Unidades no nome do campo ou no valor.** O `get_order` devolve centavos, e o modelo da seção 03 precisou transformar 7780 em 77,80. Um `total_cents` diria isso; uma ferramenta que devolve dinheiro sem unidade convida a um reembolso cem vezes maior.
- **Erros também são observações.** Uma consulta que falha deve voltar como uma mensagem curta e específica (*"no order M-9999"*) marcada como erro, para que o modelo corrija o id ou pergunte ao cliente. A aula 4 constrói isso, e é o que impede um erro de digitação de virar uma queda do programa.
- **Limitadas.** Uma busca que poderia devolver mil linhas devolve as primeiras e diz quantas eram. Uma observação que não cabe na janela de contexto encerra a execução, e uma que quase cabe não deixa espaço para a resposta.

## Observações não são instruções

Tudo o que uma ferramenta devolve é texto que o modelo lê, e parte dele foi escrita por pessoas que não são o usuário: um artigo de ajuda, uma resenha de produto, uma mensagem anterior de um cliente. **Um modelo pode confundir texto dentro de uma observação com uma instrução**, e é assim que funciona a injeção de prompt indireta (aula 7 do `prompt-engineering`). A aula 17 constrói a defesa no hospedeiro, que é onde ela fica; por ora, o hábito a formar é tratar uma observação como dado que chegou de fora, diga o que disser.
