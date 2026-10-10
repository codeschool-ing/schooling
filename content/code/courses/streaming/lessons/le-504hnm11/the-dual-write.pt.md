---
title: A escrita dupla, e o instante entre duas escritas
version: 1
---

**Um programa que grava uma mudança no banco e depois a anuncia no Kafka faz duas escritas sem
nenhuma transação em volta delas.** O site da Ponto Final guarda o estoque no PostgreSQL: uma
tabela com uma linha por loja e livro. Quando o site aceita uma reserva, ele diminui a contagem
nessa tabela. Todo outro sistema que se importa com estoque — as telas dos caixas, o warehouse, o
relatório de reposição — gostaria de saber disso, e o jeito óbvio é o mesmo programa mandar um
evento para um tópico logo depois do `UPDATE`.

Esse jeito óbvio se chama **escrita dupla** (*dual write*), e ele falha no intervalo entre as duas
escritas. As duas ordens têm a sua versão da falha:

@@fig:l14-dual-write@@

- **Banco primeiro.** O `UPDATE` é confirmado, e o programa morre antes de chamar `produce` — um
  deploy, um processo morto por falta de memória, um broker que não responde dentro do timeout. A
  tabela diz dois exemplares; o tópico, e tudo o que o lê, continua dizendo três. Nada tenta de
  novo, porque nada lembra que havia um envio pendente.
- **Kafka primeiro.** O evento sai, e então o `UPDATE` falha: uma restrição, um deadlock, uma
  transação desfeita por causa do lock de outra pessoa. O tópico anunciou uma reserva que o banco
  nunca fez, e um leitor já agiu com base nela.

A resposta errada mais comum é colocar o envio *dentro* da transação do banco, antes do `COMMIT`.
Isso estreita o intervalo e não o fecha, porque o Kafka não participa da transação do PostgreSQL:
o envio pode dar certo e o commit falhar, que é o segundo caso de novo. As transações do Kafka da
lição 7 também não ajudam. **Elas tornam atômicas entre si as escritas em vários tópicos, e um
banco de dados não é um tópico.**

## Duas saídas

O intervalo só fecha quando existe **uma escrita**, e alguma coisa deriva a segunda a partir dela.
Essa escrita pode ir para dois lugares.

| | a escrita única | o que deriva o evento |
|---|---|---|
| **a outbox** (lição 8) | a mudança *e* uma linha de evento, numa transação do banco | um relay que lê a tabela outbox e envia as linhas dela |
| **captura de mudanças (CDC)** | a mudança, e nada mais | um leitor do próprio log de mudanças do banco |

Esta lição é sobre a segunda. **A captura de dados de mudança (CDC, *change data capture*) trata o
banco como o produtor**: todo `INSERT`, `UPDATE` e `DELETE` confirmado já vai para o write-ahead
log do PostgreSQL antes de o commit retornar, então um programa que lê esse log vê toda mudança, na
ordem dos commits, inclusive as feitas por um script que alguém rodou à meia-noite e por programas
que nunca ouviram falar de Kafka.

Se você fez o curso `pipelines-etl`, já fez isso à mão: a lição 5 dele abre um slot de replicação
com `test_decoding`, lê as mudanças como texto via SQL e as aplica numa tabela do warehouse. Aqui o
leitor é o **Debezium**, um conjunto de conectores do Kafka Connect que fazem a mesma leitura,
guardam a sua posição com segurança e gravam cada mudança num tópico como um evento estruturado.

Vale dizer o que a CDC não dá antes de ela dar qualquer coisa. **Os eventos são mudanças de linha,
não fatos de negócio.** A `stock` perdeu um exemplar do `bk-02` no Recife; o evento não diz que foi
uma reserva, nem de quem, nem de qual tela, porque a tabela nunca soube disso. Uma linha de outbox
pode carregar essa informação, e é por isso que as duas técnicas convivem em vez de uma substituir
a outra.
