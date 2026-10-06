---
title: Ferramentas que rodam longe do modelo, com limites próprios
version: 1
---

O portão decide quais chamadas rodam. **O isolamento decide o que uma chamada alcança quando roda**, e é
a camada que ainda segura quando o portão tem um bug.

## As credenciais da ferramenta são da ferramenta

Uma ferramenta que reembolsa um trabalho precisa de uma credencial do sistema de pagamentos. Essa
credencial fica com a ferramenta, no servidor, e o modelo nunca a vê: nem no prompt de sistema, nem num
resultado de ferramenta, nem numa mensagem de erro. Um modelo que nunca teve uma chave não consegue
vazá-la, termine o que terminar no contexto dele. O mesmo vale para o escopo: o `lookup_order` roda com
um usuário de banco que lê pedidos e mais nada, então uma consulta que ele nunca deveria fazer falha no
banco também.

## Um orçamento por conversa

Um agente trabalha em laço: propõe uma chamada, lê o resultado, propõe a próxima. Um laço sem fim custa
dinheiro no melhor caso e repete uma ação nociva no pior, e a proteção mais barata é uma contagem:

```
ana@lab:~/guard$ guard gate data/proposed-calls.jsonl --budget 4
session ac-7Q2M, 4 calls allowed
c1  lookup_order   ALLOW  read, within scope
c2  lookup_order   DENY   account ac-0Z5Q is not the session's (ac-7Q2M)
c3  issue_refund   HOLD   issue_refund needs a person to confirm: moves money and cannot be undone
c4  issue_refund   DENY   refund of 900000 is more than the 120000 paid for job 4471
c5  send_message   DENY   budget of 4 calls per conversation is spent
c6  send_message   DENY   budget of 4 calls per conversation is spent
c7  update_contact DENY   budget of 4 calls per conversation is spent
```

Com orçamento de quatro, a quinta proposta é recusada seja ela qual for. O manifesto do laboratório
permite oito, o bastante para uma conversa de suporte e pouco para uma descontrolada. Quando o orçamento
acaba, a conversa vai para uma pessoa, o mesmo destino do laço de novas tentativas da aula 9.

## Tudo deixa registro

Cada proposta, cada decisão e o motivo dela, cada confirmação e quem a deu vão para o log, com o id da
requisição e o identificador de usuário final da aula 7. Os logs da aula 11 valem aqui: os argumentos
de uma chamada são dado pessoal quando nomeiam uma pessoa, e passam por redação e vencem como o resto.

Três camadas, então, e uma ação precisa passar por todas: o manifesto e o escopo dele, a pessoa que
confirma o que importa, e as credenciais e o orçamento que limitam o que uma chamada faz quando roda.
