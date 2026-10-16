---
title: Desenhando um evento que ainda faça sentido no ano que vem
version: 1
---

**Um evento sobrevive ao código que o escreveu.** O programa do caixa é trocado, o sistema de estoque
é reescrito, e o log continua guardando vendas de três anos atrás que alguém vai reprocessar. Então
um evento é desenhado como uma tabela de banco de dados, para leitores que ninguém conheceu, e as
decisões abaixo são baratas no primeiro dia e caras em qualquer dia depois.

## Dê nome ao que aconteceu, no passado

`book-sold`, `stock-received`, `stock-counted`. Um nome no passado mantém o evento como um fato. Os
nomes que dão problema são os que não são:

- **Um comando disfarçado**: `update-stock`, `send-receipt`. Ele diz ao leitor o que fazer, então tem
  um leitor pretendido, e um segundo leitor não sabe se deve fazer aquilo também.
- **Uma mudança sem significado**: `sale-updated` com a linha nova inteira. O leitor vê que alguma
  coisa mudou e tem de comparar duas linhas para adivinhar o quê. A venda foi estornada, ou um erro
  de digitação na quantidade foi corrigido? São dois fatos diferentes, `sale-refunded` e
  `sale-corrected`, e o sistema de estoque trata cada um de um jeito.

## Dê a ele um id que seja único para sempre

Todo evento carrega um id que nenhum outro evento tem, escrito por quem criou o evento. Os caixas
escrevem `nat-000002`. **Duplicatas não são um acidente a evitar; fazem parte de como streams
funcionam**: um produtor que não recebeu resposta manda de novo, e um leitor que caiu lê de novo. A
lição 7 mostra os dois acontecendo, e a lição 8 usa o id para tornar inofensiva uma segunda cópia.
Um evento sem id não se distingue de outro evento com o mesmo conteúdo, como dois clientes
comprando o mesmo livro na mesma loja no mesmo segundo.

## Ponha dentro a hora em que aconteceu

`at` é o instante da venda, pelo relógio do próprio caixa. O log também vai registrar quando recebeu
o evento, e o leitor sabe quando o leu, e essas duas horas são números diferentes para uma venda
que ficou presa num caixa sem conexão. **A hora dentro do evento é a única que descreve a venda**; a
lição 9 mostra as outras duas dando respostas erradas.

## Escolha a chave de propósito

A chave decide o que fica em ordem. Use como chave a coisa cujo estado o evento muda: a loja, para um
estoque mantido por loja; o cliente, para pontos de fidelidade. Um evento sem chave perde a ordem com
tudo, o que serve para um clique contado num total e não serve para nada que vire estado num fold.

## Diga qual é a forma

Cedo ou tarde um campo é acrescentado, renomeado ou dividido. Um leitor com um evento de antes da
mudança precisa saber qual forma tem nas mãos, e um leitor escrito antes da mudança precisa
sobreviver aos eventos de depois dela. Um número de versão em todo evento é o mínimo que responde à
primeira; um **schema**, guardado num registry que escritores e leitores consultam, responde às duas,
e é o assunto da lição 6.

## Os caixas, conferidos

| regra | a venda dos caixas | veredito |
|---|---|---|
| no passado | sem campo de tipo; o tópico `sales` dá o nome | serve enquanto o tópico só tiver vendas |
| id único | `sale`: `nat-000002` | sim |
| hora dentro | `at`, do caixa | sim |
| chave de propósito | a loja | sim, para estoque por loja |
| forma declarada | nada | falta; a lição 6 acrescenta |

Um evento por tópico, nomeado pelo tópico, é um desenho comum e bom enquanto dura. No dia em que um
estorno precisar entrar no mesmo tópico, porque tem de ficar em ordem com a venda que estorna, todo
evento precisa de um `type`, como o `stock.log` tem. **Decida isso no dia em que criar o tópico, não
no dia em que precisar**, porque os eventos já escritos não vão ganhar um campo.
