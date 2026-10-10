---
title: Uma confirmação que quer dizer algo
version: 2
---

A execução do agente de reembolsos perguntou duas vezes a uma pessoa: o hospedeiro, porque `refunds__refund` está em `CONFIRM`, e o servidor, porque o `refund_mcp.py` não reembolsa sem uma aprovação própria (aula 15, seção 06). A pessoa disse sim as duas vezes, a um reembolso de 0 centavos. Uma confirmação só é fronteira se a pessoa consegue de fato decidir, e quatro hábitos fazem a diferença.

- **Mostre exatamente o que vai acontecer.** A pergunta do hospedeiro levava a ferramenta e todos os argumentos: pedido `M-1047`, `"0"` centavos, o motivo. Essa é a pergunta que dá para ler, e ela foi respondida sem ser lida, o que nenhuma redação resolve. Uma pergunta como *"permitir a ferramenta de reembolso?"* pede à pessoa que aprove uma categoria, o que ela vai fazer, toda vez. As aulas 8 e 9 fizeram o mesmo ponto: aprove esta chamada, com estes argumentos.
- **Pergunte só onde a resposta importa.** Ler um pedido não precisou de ninguém. Um hospedeiro que pergunta antes de toda chamada ensina as pessoas a apertar `y` sem ler, que é o estado em que a única pergunta que importava é respondida como as outras.
- **Ponha as regras com resposta certa em código, antes da pessoa.** O hook da aula 9 recusou reembolsos acima de 50,00 sem perguntar a ninguém. Uma pessoa deve ser chamada para julgar, não para impor um limite que um programa consegue impor.
- **Deixe a recusa ser segura.** Quando a pessoa disse não na aula 15, o modelo ficou sabendo com clareza que nada foi feito, e mandou o cliente ao atendimento em vez de fingir. Um hospedeiro cujas recusas quebram a conversa ensina as pessoas a aprovar para as coisas andarem.

A pergunta do próprio servidor é a outra metade. Ele não sabe nem se importa com o que o hospedeiro perguntou: o dono dele decidiu que este sistema não reembolsa sem aprovação, e ele pergunta a todo hospedeiro do mesmo jeito. **Nenhum dono precisa confiar que o outro perguntou**, e é isso que torna os dois juntos mais fortes que qualquer um sozinho.
