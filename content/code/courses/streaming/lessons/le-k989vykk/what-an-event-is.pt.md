---
title: O que é um evento, e o que não é
version: 1
---

**Um evento é o registro de que algo aconteceu.** Ele é escrito no passado porque fala do passado:
um livro foi vendido, uma entrega foi recebida, uma contagem de estoque foi feita. Ninguém pode
recusá-lo, porque já aconteceu, e ninguém o edita depois, porque o que aconteceu não muda. Todo o
resto desta lição se apoia nessas duas propriedades.

A imagem errada mais comum é a de que um evento é uma mensagem mandando outro sistema fazer alguma
coisa. Isso é outra coisa, com outro nome, e vale manter as três formas separadas, porque sistemas
que as misturam são difíceis de mudar.

| | exemplo | para quem é | pode ser recusado? |
|---|---|---|---|
| **comando** | *reserve um exemplar do bk-03 para este cliente* | um sistema, o que precisa agir | sim, e quem mandou precisa ficar sabendo |
| **evento** | *um exemplar do bk-03 foi vendido no Recife às 09:00:41* | quem quiser saber, inclusive leitores que ainda não existem | não, já aconteceu |
| **estado** | *o Recife tem 6 exemplares do bk-03* | quem perguntar, agora | não, mas é sobrescrito no instante em que muda |

Um **comando** tem destinatário: quem o manda sabe quem precisa executá-lo e espera saber se deu
certo. Um **evento** não tem destinatário nenhum. O caixa que registra uma venda não sabe, e não
deveria saber, se o sistema de estoque, o programa de fidelidade ou o warehouse vão lê-la. Um
**estado** é uma fotografia: responde *quantos agora* e esquece *como chegamos aqui*. O resto desta
lição mostra que o estado sempre pode ser reconstruído a partir dos eventos, e que os eventos nunca
podem ser reconstruídos a partir do estado.

## O que vai dentro de um

Esta é uma venda como os caixas da lição 1 a enviam:

```json
{"sale": "nat-000002", "shop": "natal", "book": "bk-08", "qty": 2, "cents": 17980, "at": "2026-03-02T09:00:09-03:00"}
```

Quatro tipos de campo aparecem em quase todo evento bem feito, e este tem três deles:

- **Uma identidade.** `sale` dá nome a este evento e a nenhum outro. Quando o mesmo evento chega
  duas vezes, e a lição 7 mostra que vai chegar, o id é como um leitor reconhece a segunda cópia.
- **A hora em que aconteceu.** `at` é o instante em que o caixa registrou a venda, escrito pelo
  caixa. Não é quando o evento foi enviado, guardado ou lido; a lição 9 trata de manter essas horas
  separadas.
- **Do que ele trata.** `shop` diz de quem é a venda, e é também a **chave** que o Kafka usa para
  decidir onde o evento é guardado. Escolher a chave é escolher quais eventos mantêm a ordem entre
  si, que é a última ideia desta lição.
- **Uma versão.** Esta falta. Quando a forma de uma venda muda, o leitor precisa saber qual forma
  tem nas mãos, e a lição 6 acrescenta uma, com um schema.

## Magro e gordo

A venda acima é **gorda**: carrega o livro, a quantidade e o preço, então um leitor faz o trabalho
dele sem perguntar nada a ninguém. Um evento **magro** carregaria só `{"sale": "nat-000002"}` e
esperaria que o leitor buscasse o resto no banco de dados da loja.

O magro parece mais arrumado e custa mais do que aparenta. Todo leitor passa a consultar a origem,
então a origem precisa ficar no ar e responder por eles; e quando o leitor pergunta, a linha pode
ter mudado. Um leitor tratando uma venda de duas horas atrás veria o preço de agora, não o que foi
cobrado. Eventos gordos custam bytes e transformam a forma do evento numa promessa a todo leitor, e
é por isso que a lição 6 põe essa forma sob um schema. **Os eventos deste curso são gordos**, porque
um processador de stream lê milhões deles e não pode pagar uma consulta ao banco por evento.
