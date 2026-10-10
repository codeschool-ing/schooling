---
title: Os três suspeitos, um de cada vez
version: 1
---

"O banco está lento" é uma frase sobre um prédio. Dentro dele há três suspeitos, e o primeiro
hábito que este curso ensina é dizer qual deles você quer dizer antes de mudar qualquer coisa:

| suspeito | o que está errado | o que conserta |
|---|---|---|
| **a consulta** | pede mais trabalho do que a resposta precisa | reescrever a consulta |
| **o esquema** | falta a estrutura que tornaria o trabalho pequeno | um índice, outro arranjo de tabela |
| **a máquina** | falta algo de que o trabalho precisa: memória, disco, processadores | configuração, ou uma máquina maior |

Os consertos não se transferem. Um índice não faz nada por um servidor sem memória, e uma máquina
maior não faz nada por uma consulta que lê dois milhões de linhas para contar duas mil. Por isso
dar nome ao suspeito vem primeiro: um conserto aplicado ao suspeito errado custa tempo e não muda
nada, e às vezes esconde o conserto certo.

Os três abaixo são lentos, cada um por um motivo, no banco que você acabou de carregar. Você ainda
não precisa entender *por que* o servidor fez o que fez — as aulas 3 a 5 ensinam a ler isso. O que
importa agora é que as três lentidões se parecem vistas de fora, e não são iguais.

## A consulta

Dois jeitos de perguntar quantos pedidos foram feitos em 1º de junho de 2025:

```
market=# SELECT count(*) FROM orders WHERE date(placed_at) = '2025-06-01';
 count 
-------
  2801
(1 row)

Time: 118.968 ms

market=# SELECT count(*) FROM orders WHERE placed_at >= '2025-06-01' AND placed_at < '2025-06-02';
 count 
-------
  2801
(1 row)

Time: 1.295 ms
```

Mesma resposta, mesma tabela, mesmo servidor: **119 milissegundos contra 1,3**, umas noventa
vezes. A primeira consulta embrulha a coluna numa função, `date(placed_at)`, e o índice em
`placed_at` é uma lista de valores de `placed_at` em ordem, não de valores de `date(placed_at)`.
Então o servidor não consegue usá-lo, e calcula a data de cada um dos dois milhões de pedidos para
achar os 2801 que batem. A segunda faz a mesma pergunta nos termos em que o índice está escrito,
uma faixa de `placed_at`, e o índice entrega exatamente essas linhas.

Nada no esquema ou na máquina mudou. **O suspeito era a consulta, e reescrevê-la foi o conserto.**
A aula 9 mostra a outra saída, um índice construído sobre a própria expressão, e quando cada uma
é a certa.

## O esquema

Quantos pedidos tem o vendedor 42?

```
market=# SELECT count(*) FROM orders WHERE seller_id = 42;
 count 
-------
  1532
(1 row)

Time: 55.253 ms

market=# CREATE INDEX orders_seller_id_idx ON orders (seller_id);
CREATE INDEX
Time: 1154.341 ms (00:01.154)

market=# SELECT count(*) FROM orders WHERE seller_id = 42;
 count 
-------
  1532
(1 row)

Time: 0.816 ms

market=# DROP INDEX orders_seller_id_idx;
DROP INDEX
Time: 12.035 ms
```

**55 milissegundos, depois 0,8.** Desta vez a consulta estava boa: pede exatamente o que quer, nos
termos mais simples. O que faltava era estrutura. Sem índice em `seller_id`, o único jeito de achar
os pedidos do vendedor 42 é ler todos eles, e um índice transformou dois milhões de linhas lidas em
1532.

O índice foi apagado de novo no fim. É de propósito: a aula 2 encontra esse mesmo índice que falta
de fora, do jeito que você encontraria no trabalho, a partir do que a aplicação está fazendo com o
servidor, e não de alguém que já sabe a resposta.

Repare também no terceiro número. **Construir o índice levou 1154 milissegundos**, e cada pedido
gravado dali em diante pagaria um pouco mais para mantê-lo em dia. Um índice não é de graça, e a
aula 11 trata dos que custam mais do que economizam.

## A máquina

O terceiro suspeito é o que nenhuma consulta e nenhum índice consertam. A mesma contagem sobre as
cinco milhões de linhas de pedido leva **435 milissegundos** quando a tabela tem de vir do disco e
cerca de **170** quando já está na memória — mesma consulta, mesmo plano, mesmas linhas, no mesmo
computador. Nada no banco mudou entre as duas; só onde os bytes estavam. A próxima seção desmonta
essa medida, porque ela é também o motivo de um tempo sozinho não provar nada.

## O que os três têm em comum

Vistos de fora, os três eram "uma consulta lenta". Por dentro, eram uma pergunta feita nos termos
errados, uma estrutura que faltava e dados que não estavam na memória, e **cada conserto não teria
feito nada pelos outros dois**. O resto deste curso é, em grande parte, sobre distinguir os três
depressa, e a primeira ferramenta para isso não é um conserto — é a lista da próxima aula de quais
consultas custam mais ao servidor.
