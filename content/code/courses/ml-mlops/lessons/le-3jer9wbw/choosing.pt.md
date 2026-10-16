---
title: Escolhendo, e o que cada escolha custa para continuar rodando
version: 1
---

As três implantações diferem mais no que custam depois de estarem rodando, e o custo não é
principalmente dinheiro.

| | lote | tempo real | borda |
| --- | --- | --- | --- |
| roda | minutos por noite | todo minuto de todo dia | em aparelhos que você não controla |
| precisa estar no ar | durante o job | sempre, ou a página que o chama falha | não |
| atributos vêm de | o armazenamento offline | o armazenamento online, em milissegundos | o aparelho, com código próprio |
| quando falha | uma tabela velha, e a execução de amanhã | erros na frente dos clientes | respostas erradas que ninguém vê |
| trocar a versão | a próxima execução | um reinício | uma atualização do aplicativo, uma hora |
| a evidência guardada | cada nota, numa tabela | cada pedido, se for registrado | o que os aparelhos mandam de volta |

**Comece pelo lote e só mude quando uma decisão precisar de respostas mais frescas que uma noite.**
A decisão do modelo de afastamento, uma lista mensal de cupons, não precisa de mais nada. A página
do
membro que quer uma nota ao vivo é mais bem servida lendo a linha de ontem à noite em `lapse_scores`
do que por um serviço. É uma busca indexada e mostra o mesmo número que o marketing usou. E a nota
não pode ser mais fresca que os atributos por trás dela de qualquer jeito, e esses mudam quando o
membro compra um livro, não quando ele abre uma página.

**Um serviço vale a pena quando a resposta depende do próprio pedido**: a cesta agora, o pagamento
agora, a busca digitada agora. Aí o armazenamento online, o processo sempre no ar e o monitoramento
da lição 9 se pagam.

É nesse último ponto que a maioria das equipes erra numa direção. Um serviço em tempo real
construído
para um modelo cujas entradas mudam toda noite é um serviço que dá a mesma resposta que a tabela de
ontem, com um risco de queda que a tabela nunca teve.
