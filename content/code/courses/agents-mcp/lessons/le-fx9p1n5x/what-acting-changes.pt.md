---
title: O que muda quando o programa age
version: 1
---

Entregar o caminho a um modelo não sai de graça, e os custos são fáceis de dizer agora que o `agent.py` rodou.

**O caminho é desconhecido até ter acontecido.** Três passos para a Bia, dois para a pergunta de pagamento, e com um modelo real poderiam ser quatro na terça e três na quinta para as mesmas palavras. Código que depende de um número fixo de passos, de um custo fixo ou de uma ordem fixa de chamadas é código escrito para automação.

**O custo de uma resposta só é conhecido depois.** Cada passo reenvia a conversa, e o número de passos é escolha do modelo. Um orçamento precisa então ser imposto enquanto o agente roda, em tokens, passos ou segundos, e a aula 5 escreve esses limites.

**Argumentos que ninguém escreveu chegam às suas funções.** O `get_order` foi chamado com `M-1042` porque o modelo pôs isso lá. Um modelo que lê mal uma mensagem chama a ferramenta certa com o pedido errado, e a função não tem como saber. A aula 4 é sobre conferir argumentos antes de qualquer coisa rodar.

**Os erros se acumulam.** Num assistente, um rascunho errado é lido por alguém que pode jogá-lo fora. Num agente, um passo errado vira a entrada do seguinte: consulte o pedido errado, e a próxima busca é sobre o problema errado, e a resposta fala com toda a confiança da encomenda de outra pessoa. **Ninguém lê nada até o fim**, e às vezes nem no fim.

**Alguns passos não têm volta.** Ler um pedido pode ser repetido quantas vezes se quiser. Um reembolso, um e-mail ou um arquivo apagado acontecem uma vez. O `agent.py` não tem ferramenta assim, de propósito; a aula 17 acrescenta uma e põe uma pessoa na frente dela.

## O teste também muda

Um teste que roda a pergunta da Bia uma vez e compara a resposta prova que um caminho funciona. Neste laboratório é exatamente isso que ele prova, porque o modelo substituto sempre responde do mesmo jeito. **Um modelo real pode escolher outro caminho na execução seguinte**, então um agente é testado com muitas entradas e muitas execuções, contra propriedades e não contra strings exatas: a resposta cita a data real do pedido; nenhum reembolso foi emitido; a execução parou dentro do limite. A aula 7 escreve testes assim, e a aula 18 mede uma taxa de sucesso.
