---
title: Passar a conversa adiante
version: 2
---

O cliente do M-1046 escreve que o pedido não foi enviado e pergunta o que pode fazer. É uma pergunta inteiramente sobre pedidos, então não há nada a combinar: o desenho certo é entregar a conversa ao agente dono dos pedidos e sair do caminho.

```
ana@lab:~/agents$ rm requests.jsonl
ana@lab:~/agents$ python multi.py "My order M-1046 still has not shipped. What can I do?" --handoff
triage hands the conversation to orders
orders -> search_help({"query": "unshipped order M-1046"})
orders: If your order M-1046 still hasn't shipped after it says "Received", you can try cancelling it and placing a new one. If you're expecting the parcel but it hasn't arrived, you can open a claim with us and we'll work with the carrier to send a replacement or provide a refund.
ana@lab:~/agents$ python tally.py
triage        requests 1   input   210   output   14
orders        requests 2   input   598   output   84
total         requests 3   input   808   output   98
```

O agente de triagem fez um pedido, com duas ferramentas sem argumentos, `transfer_to_orders` e `transfer_to_catalogue`, e chamou a primeira. **A saída inteira dele foi de 14 tokens**, um `{}` vazio e o nome da chamada em volta, porque a decisão é o nome da ferramenta e não há mais nada a dizer. O hospedeiro então rodou o especialista de pedidos sobre a mensagem do cliente, e o especialista respondeu ao cliente ele mesmo. Buscou na central de ajuda sem consultar o pedido, e a resposta dele está meio certa: o artigo sobre mudar um pedido diz que um pedido que ainda está como Received pode ser cancelado e feito de novo; a reclamação que ele oferece em seguida é para uma encomenda marcada como entregue que nunca chegou, e esse não é o problema deste cliente. O `get_order` teria mostrado `received`.

Nada voltou para o agente de triagem. Essa é a propriedade que define uma passagem, e é ao mesmo tempo a força e o risco dela. **A força**: o especialista vê as palavras do próprio cliente em vez de uma paráfrase, e a conversa não paga por um orquestrador lendo respostas. **O risco**: se a próxima mensagem do cliente for sobre livros, o especialista de pedidos não tem ferramenta para isso. Um desenho com passagem precisa então de um caminho de volta: uma ferramenta `transfer_to_triage` em todo especialista, ou um hospedeiro que passa cada nova mensagem pela triagem de novo.

## O que se moveu

A `triage()` passa ao especialista uma conversa nova contendo a mensagem do cliente. Numa conversa mais longa a escolha é real: passar todos os turnos anteriores, inclusive chamadas e resultados de outros agentes, ou passar só o que o cliente disse. Passar tudo preserva o contexto e leva dados (e custo) de outros agentes para um agente que talvez não precise deles. Passar só os turnos do cliente é mais barato e mais limpo, e perde o que agentes anteriores descobriram. **Qualquer que seja a escolha, faça-a no código**, e saiba o que o agente que recebe consegue ver.
