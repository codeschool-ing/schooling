---
title: Passar a conversa adiante
version: 1
---

O cliente do M-1046 escreve que o pedido não foi enviado e pergunta o que pode fazer. É uma pergunta inteiramente sobre pedidos, então não há nada a combinar: o desenho certo é entregar a conversa ao agente dono dos pedidos e sair do caminho.

```
ana@lab:~/agents$ python multi.py "My order M-1046 still has not shipped. What can I do?" --handoff
triage hands the conversation to orders
orders -> get_order({"order_id": "M-1046"})
orders -> search_help({"query": "change an order before it is packed"})
orders: M-1046 still says Received, so it has not been packed yet. Until it says Packed you can still change the delivery address or remove an item from it.
ana@lab:~/agents$ python tally.py
triage        requests 1   input   110   output    1
orders        requests 3   input  1087   output   56
total         requests 4   input  1197   output   57
```

O agente de triagem fez um pedido, com duas ferramentas sem argumentos, `transfer_to_orders` e `transfer_to_catalogue`, e chamou a primeira. **A saída inteira dele foi um token**, um `{}` vazio, porque a decisão é o nome da ferramenta e não há mais nada a dizer. O hospedeiro então rodou o especialista de pedidos sobre a mensagem do cliente, e o especialista respondeu ao cliente ele mesmo: consultou o pedido, viu `received`, buscou na central de ajuda o que ainda dá para mudar antes da embalagem, e respondeu a partir do artigo `h01`.

Nada voltou para o agente de triagem. Essa é a propriedade que define uma passagem, e é ao mesmo tempo a força e o risco dela. **A força**: o especialista vê as palavras do próprio cliente em vez de uma paráfrase, e a conversa não paga por um orquestrador lendo respostas. **O risco**: se a próxima mensagem do cliente for sobre livros, o especialista de pedidos não tem ferramenta para isso. Um desenho com passagem precisa então de um caminho de volta: uma ferramenta `transfer_to_triage` em todo especialista, ou um hospedeiro que passa cada nova mensagem pela triagem de novo.

## O que se moveu

A `triage()` passa ao especialista uma conversa nova contendo a mensagem do cliente. Numa conversa mais longa a escolha é real: passar todos os turnos anteriores, inclusive chamadas e resultados de outros agentes, ou passar só o que o cliente disse. Passar tudo preserva o contexto e leva dados (e custo) de outros agentes para um agente que talvez não precise deles. Passar só os turnos do cliente é mais barato e mais limpo, e perde o que agentes anteriores descobriram. **Qualquer que seja a escolha, faça-a no código**, e saiba o que o agente que recebe consegue ver.
