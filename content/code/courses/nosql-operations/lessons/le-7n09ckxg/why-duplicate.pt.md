---
title: Por que gravar o mesmo fato duas vezes
version: 1
---

Dado duplicado tem má fama, e num esquema relacional ela é merecida: duas cópias de um fato são dois
lugares que podem discordar, e a normalização existe para tornar isso impossível. **Nos
armazenamentos deste curso a duplicação é uma ferramenta de projeto**, usada de propósito, e a
pergunta nunca é se copiar, mas quais cópias valem o que custam.

## O custo muda de lugar, não some

A aula 3 deixou a loja com perguntas que partem de chaves diferentes. A página do pedido parte do
número do pedido, "meus pedidos" parte do cliente, a cesta parte da sessão. Sem joins, cada uma dessas
respostas é mais rápida quando tudo o que ela mostra já está sob a sua chave, e isso significa que
alguns fatos moram sob mais de uma chave.

Conte o que isso compra. A página do pedido é lida umas 200 vezes por minuto, o que dá 288.000 vezes
por dia. Se ela mostra o nome de cada produto, e o nome mora só em `products`, toda visualização paga
uma segunda leitura por produto, o dia inteiro. Se a linha do pedido carrega uma cópia do nome, a
visualização é uma leitura só, e o custo da cópia é pago **quando o nome muda**, o que para um
produto acontece algumas vezes por ano.

Essa é a troca numa frase: **uma cópia leva o custo de toda leitura para a escrita rara que muda o
fato.** Ela compensa quando as leituras superam essas escritas por uma margem larga, o que para quase
tudo o que uma loja mostra vale por milhares a um. Não compensa para um fato que muda o tempo todo e é
pouco lido, como uma contagem de estoque que anda a cada venda.

## No que o custo se transforma

O lado da escrita na troca não é só tempo. Três coisas passam do banco para você:

- **as escritas extras em si**, toda vez que um fato copiado muda, em todo lugar para onde foi
  copiado;
- **o conhecimento de onde estão as cópias**, que nenhum armazenamento deste curso guarda por você:
  nada no MongoDB sabe que `orders` carrega o nome de um produto;
- **a janela em que as cópias discordam**, entre a primeira escrita e a última, e o caso em que a
  última nunca acontece porque um processo morreu no meio.

O banco relacional pagava as três por você ao não ter cópias. Aqui elas são uma lista que alguém
precisa manter, e o resto desta aula é essa lista para a loja.

## Dois tipos de cópia

Nem toda cópia deve acompanhar a sua origem, e confundir as duas é o erro mais comum num projeto
desnormalizado:

| | um retrato | uma cópia que acompanha |
|---|---|---|
| o que registra | o fato **como era** quando algo aconteceu | o fato **como é agora**, guardado perto por velocidade |
| exemplo na loja | o preço que a Ana pagou pelo mouse | o nome que a página do pedido mostra para a Ana |
| quando a origem muda | **não deve** mudar | precisa mudar, em todo lugar para onde foi copiada |

A próxima seção põe os dois num mesmo documento de pedido. Depois, o Cassandra grava um pedido em
duas tabelas de uma vez, e a última seção confere um conjunto de cópias à procura das que não
acompanharam.
