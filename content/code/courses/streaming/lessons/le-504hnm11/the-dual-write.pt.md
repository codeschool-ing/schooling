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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois programas que gravam uma venda no banco e no Kafka em dois passos, e falham entre eles. Em cima, o banco é gravado primeiro: o estoque muda e é confirmado, o programa cai, e o evento nunca é enviado, então todo leitor do tópico continua acreditando no estoque antigo. Embaixo, o Kafka é gravado primeiro: o evento é enviado, depois a transação no banco falha e é desfeita, então os leitores ficam sabendo de uma venda que nunca aconteceu.\" data-fig=\"l14-dual-write\"><defs><marker id=\"l14-dual-write-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">banco primeiro</text><line x1=\"130\" y1=\"70\" x2=\"540\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"138\" y=\"55\" width=\"104\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"190\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">UPDATE stock</text><rect x=\"258\" y=\"55\" width=\"104\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">COMMIT</text><line x1=\"392\" y1=\"62\" x2=\"408\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><line x1=\"392\" y1=\"78\" x2=\"408\" y2=\"62\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"400\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">queda</text><rect x=\"433\" y=\"55\" width=\"104\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"485\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nunca enviado</text><text x=\"640\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">a tabela: 2 exemplares</text><text x=\"640\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o tópico: ainda 3</text><text x=\"20\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Kafka primeiro</text><line x1=\"130\" y1=\"165\" x2=\"540\" y2=\"165\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"138\" y=\"150\" width=\"104\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"190\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">enviar evento</text><rect x=\"258\" y=\"150\" width=\"104\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">UPDATE stock</text><line x1=\"392\" y1=\"157\" x2=\"408\" y2=\"173\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><line x1=\"392\" y1=\"173\" x2=\"408\" y2=\"157\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"400\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">queda</text><rect x=\"433\" y=\"150\" width=\"104\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"485\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">desfeita</text><text x=\"640\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o tópico: 2 exemplares</text><text x=\"640\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">a tabela: ainda 3</text><path d=\"M 130 225 L 540 225\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-dual-write-ah-8343)\"></path><text x=\"335\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "Duas escritas, e a queda entre elas. Seja qual for a primeira, um lado acaba dizendo algo que o outro não diz.", "same": ["UPDATE stock", "COMMIT"]}
```

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
banco como o produtor.** Todo `INSERT`, `UPDATE` e `DELETE` confirmado já vai para o write-ahead
log do PostgreSQL antes de o commit retornar. Um programa que lê esse log vê toda mudança, na
ordem dos commits, inclusive as feitas por um script que alguém rodou à meia-noite e por programas
que nunca ouviram falar de Kafka.

Se você fez o curso `pipelines-etl`, já fez isso à mão: a lição 5 dele abre um slot de replicação
com `test_decoding`, lê as mudanças como texto via SQL e as aplica numa tabela do warehouse. Aqui o
leitor é o **Debezium**, um conjunto de conectores do Kafka Connect que fazem a mesma leitura,
guardam a sua posição com segurança e gravam cada mudança num tópico como um evento estruturado.

Um limite vem primeiro. **Os eventos são mudanças de linha,
não fatos de negócio.** A `stock` perdeu um exemplar do `bk-02` no Recife; o evento não diz que foi
uma reserva, nem de quem, nem de qual tela, porque a tabela nunca soube disso. Uma linha de outbox
pode carregar essa informação, e é por isso que as duas técnicas convivem em vez de uma substituir
a outra.
