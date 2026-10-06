---
title: Uma nova tentativa não pode pagar duas vezes
version: 1
---

Leituras podem ser repetidas à vontade. Escritas não, e agentes repetem coisas: um pedido estoura o tempo e o hospedeiro tenta de novo, um modelo pede o mesmo reembolso em dois passos, uma execução é retomada a partir do rastro depois de uma queda. **Uma ferramenta que muda algo precisa ser segura de chamar duas vezes com a mesma intenção.** Essa propriedade se chama idempotência, e o jeito padrão de obtê-la é uma chave.

O `issue_refund` exige uma `idempotency_key`. A primeira chamada com uma chave faz o trabalho e registra o resultado sob a chave; qualquer chamada posterior com a mesma chave devolve o resultado registrado e não faz nada:

```
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"issue_refund\", {\"order_id\": \"M-1042\", \"cents\": 3480, \"reason\": \"damaged copy\", \"idempotency_key\": \"ticket-5521-refund\"}))"
('{"order_id": "M-1042", "refunded": 3480, "left": 0}', False)
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"issue_refund\", {\"order_id\": \"M-1042\", \"cents\": 3480, \"reason\": \"damaged copy\", \"idempotency_key\": \"ticket-5521-refund\"}))"
('{"order_id": "M-1042", "refunded": 3480, "left": 0, "note": "already processed with this key; nothing refunded now"}', False)
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"issue_refund\", {\"order_id\": \"M-1042\", \"cents\": 3480, \"reason\": \"damaged copy\", \"idempotency_key\": \"ticket-5521-again\"}))"
('ValueError: cannot refund 3480 cents on M-1042: 0 left to refund', True)
```

A primeira chamada reembolsou 3480 centavos do M-1042, o pedido inteiro. A segunda, com a mesma chave, devolveu o mesmo resultado mais uma nota, e não reembolsou nada. A terceira usou uma chave nova, então foi tratada como um reembolso novo, e o `shop.refund` o recusou porque não sobrava nada a reembolsar: `0 left to refund`. **Duas defesas independentes, e cada uma pega algo que a outra não pega**: a chave impede repetir a mesma intenção, e a checagem de saldo impede uma segunda intenção que estouraria o pedido.

## De onde vem a chave

A chave precisa identificar a intenção, não a tentativa. Uma boa chave é algo que existe antes de o agente rodar, como o chamado de suporte a que o reembolso pertence (`ticket-5521-refund`). Uma chave que o modelo inventa a cada chamada não protege nada, porque cada nova tentativa inventa outra. Então, num desenho de produção, quem fornece a chave é o hospedeiro, derivada da tarefa, e o modelo nunca a vê; esta aula a deixa no esquema para que o mecanismo fique visível.

A mesma ideia aparece nas APIs dos meios de pagamento, que aceitam um cabeçalho de chave de idempotência exatamente por isso. A ferramenta de escrita de um agente deveria usar o mecanismo do fornecedor ou implementar o seu, como o `issue_refund` faz com um pequeno arquivo JSON.

## E o reembolso continua sem guarda

O `issue_refund` confere os argumentos, recusa estourar o saldo e sobrevive a novas tentativas. Ele não pergunta a ninguém se o reembolso deve acontecer, e o modelo pode chamá-lo sempre que a conversa fizer isso parecer certo. Esse é o assunto da aula 17. Até lá, nenhum agente deste curso recebe o `issue_refund` como ferramenta; esta aula o chamou diretamente.
