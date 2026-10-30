---
title: O que pertence ao Spot
version: 1
---

Toda carga de trabalho pode ir para o Spot, e a maioria não deveria. **A pergunta não é "ela roda
lá", e sim "quanto uma preempção custa a ela", e a resposta tem de ser "um pouco de tempo", não "uma
queda do serviço" nem "dados perdidos".** Separar o trabalho da loja por essa pergunta dá uma lista
curta de cada lado.

## Bons inquilinos

- **Trabalho em lote dividido em pedaços pequenos**, como redimensionar as fotos da loja: uma máquina
  retomada perde o pedaço em que estava, e outra máquina pega esse pedaço de novo. Os jobs do Cloud Run
  da lição 10 são feitos do mesmo jeito, numa plataforma que repete por você.
- **Workers que leem de uma fila**, onde uma mensagem não terminada é simplesmente entregue de novo a
  outro. O grupo guiado por fila da lição 5 é desse tipo.
- **Máquinas de build e de teste**, onde uma preempção quer dizer que uma execução do pipeline é
  repetida, o que custa minutos e nada mais.
- **A capacidade extra de um serviço web sem estado**, atrás de uma base de máquinas comuns, como a
  seção 04 descreveu.

## Maus inquilinos

- **Qualquer coisa que guarde a única cópia de um estado**: um banco de dados, um cache que ninguém
  reconstrói rápido, uma máquina cujo disco é o registro.
- **Tarefas longas que não salvam progresso**: um job de doze horas sem checkpoint é um job que
  recomeça do zero na hora onze, e um preço Spot não paga por isso.
- **O serviço inteiro que os usuários esperam**, porque uma falta de capacidade leva todas as máquinas
  de uma vez, e não uma por uma.

## O teste

Antes de passar alguma coisa para o Spot, escreva o que acontece quando uma máquina some agora, no
meio do trabalho, com trinta segundos de aviso. Se a resposta for "ela continua de onde outra parou",
ela pertence ao Spot, e cerca de 40% da conta de computação dela vai junto. Se a resposta precisar de
uma pessoa, não pertence, e nenhum desconto paga pela pessoa.
