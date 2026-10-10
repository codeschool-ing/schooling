---
title: Ordem por chave basta, e é ela que escala
version: 1
---

**Só eventos sobre a mesma coisa precisam ficar em ordem entre si.** A contagem do Recife precisa
vir antes das vendas do Recife. Se a contagem do Recife vem antes ou depois de uma venda de Olinda
não muda nada, porque nenhum evento sobre Olinda toca a linha do Recife. Aquilo de que um evento
trata é a sua **chave**, e manter a ordem *por chave* é uma promessa muito mais fraca do que mantê-la
no log inteiro.

Teste. Rearranje o `stock.log` para que todo evento de Olinda venha primeiro e todos os outros
depois, cada grupo ainda na sua própria ordem. Isso move sete das oito linhas e muda completamente a
ordem entre as lojas:

@@fence@@

A mesma resposta do original, 3 e 6. A ordem total do log foi destruída e o resultado não se mexeu,
porque **a ordem dentro de cada chave foi mantida**. Compare com a seção anterior, em que uma única
linha se moveu, dentro de uma chave, e a resposta ficou errada.

## Quanto custa uma ordem total

Uma ordem única para todos os eventos exige um lugar único onde os eventos são postos em ordem: um
arquivo, um processo, uma máquina por onde todo escritor tem de passar. É isso que o `minilog.py` é,
e ele tem um teto: o log só aceita tantos eventos por segundo quanto esse lugar consegue anexar. Pôr
uma segunda máquina não ajuda, a menos que as duas concordem, para cada evento, sobre qual veio
primeiro, e esse acordo é uma ida e volta entre elas a cada escrita.

A ordem por chave tira o teto. Se todo evento sobre o Recife vai para um log e todo evento sobre
Olinda para outro, cada log só precisa manter a própria ordem, e os dois logs podem morar em duas
máquinas que nunca conversam. Cinco lojas podem usar cinco logs; quinhentas lojas podem dividir
cinquenta, desde que **uma loja nunca use mais de um**.

@@fig:l2-per-key@@

## Do hash da chave a um lugar

A regra que manda cada chave para um log tem de dar sempre a mesma resposta, em toda máquina, sem
tabela para consultar. A regra de costume é um hash: calcular um número a partir dos bytes da chave
e tirar o resto da divisão pelo número de logs. `recife` sempre dá o mesmo hash, então cai sempre no
mesmo log, e o mesmo vale para toda outra chave, cada uma no seu log ou dividindo um com outras.

O Kafka chama esses logs de **partições**. Um tópico é um conjunto de partições, o produtor faz o
hash da chave de cada mensagem para escolher uma, e a promessa do Kafka sobre ordem é exatamente a
desta seção: **dentro de uma partição, na ordem em que foi escrito; entre partições, nenhuma**. A
lição 3 mostra o hash funcionando, e uma surpresa nele: dois clientes do Kafka podem mandar a mesma
chave para partições diferentes.

## A chave é uma decisão

Escolher a chave é escolher quais eventos mantêm a ordem entre si, e não existe chave que mantenha
toda ordem que alguém possa querer:

| chave | mantidos em ordem | sem ordem entre si |
|---|---|---|
| loja | todos os eventos de uma loja, seja qual for o livro | duas lojas vendendo o mesmo livro |
| livro | toda venda de um livro, em todas as lojas | as vendas de livros diferentes numa loja |
| nenhuma (sem chave) | nada | tudo; o produtor espalha as mensagens pelas partições |

Os caixas usam a loja, o que serve a um estoque mantido por loja. O caso difícil é um evento sobre
**duas** chaves: uma transferência de cinco exemplares do Recife para Olinda tira de uma linha e põe
em outra, e com a loja como chave ela só fica em ordem com uma das duas. A resposta de costume são
dois eventos, um por loja, cada um com a chave da sua loja, e a lição 8 deixa isso seguro quando um
dos dois chega duas vezes.
