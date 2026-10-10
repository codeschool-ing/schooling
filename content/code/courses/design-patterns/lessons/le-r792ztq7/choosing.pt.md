---
title: Escolher por operação, não por sistema
version: 1
---

**A pergunta útil nunca é "o nosso sistema é consistente ou disponível?". É "nesta operação, o que
custa se duas cópias discordarem por um tempo, e quem paga?"** A mesma biblioteca, no mesmo banco,
responde essa pergunta de jeitos diferentes várias vezes por dia, e um projeto que escolhe uma
resposta para tudo fica lento onde não precisava ou errado onde não podia.

A crença a abandonar é que consistência é uma propriedade que você compra uma vez, junto com um
banco. A seção anterior já mostrou os próprios bancos se recusando a decidir por você: PostgreSQL,
DynamoDB e Cassandra deixam quem chama escolher, consulta a consulta. A decisão passou para o seu
código, e é tomada uma operação de cada vez.

## As operações da biblioteca, uma a uma

| operação | se duas cópias discordarem | a escolha | como, nos termos desta lição |
|---|---|---|---|
| emprestar o último exemplar | dois sócios recebem a promessa de um livro | consistência; recusar na dúvida | só na primária, com o `UPDATE` condicional |
| pagar uma multa | dinheiro cobrado duas vezes, ou não registrado | consistência, e todas as letras do ACID | uma transação na primária, recusada enquanto o link estiver fora |
| fazer uma reserva | duas reservas chegam numa ordem que ninguém viu | disponibilidade | aceitar em qualquer filial; ordenar a fila por horário quando o link voltar |
| mostrar "disponível" no catálogo online | a página diz 1 por alguns segundos depois de o exemplar sair | latência | ler de uma réplica, ou do modelo de leitura da lição 8 |
| contar os "mais procurados da semana" | uma contagem errada por pouco | latência, e nenhuma transação | um incremento disparado sem esperar resposta |

Repare no que decide cada linha. Empréstimos e multas erram de um jeito que uma pessoa precisa
consertar: um telefonema, um estorno. Reservas erram de um jeito que uma regra conserta, porque uma
fila ordenada por horário de chegada dá a mesma resposta seja qual for a filial que ouviu primeiro.
**Quando uma regra resolve o conflito sem uma pessoa, a disponibilidade costuma sair barata; quando
só uma pessoa resolve, pague pela consistência.** A página do catálogo e o contador são os casos
fáceis: ninguém se prejudica com um número de alguns segundos atrás.

O mesmo raciocínio vale numa máquina só, sem rede nenhuma. Em `desks.py`, o `BEGIN IMMEDIATE` fez
cada balcão esperar a vez pelo arquivo inteiro. Isso é certo para emprestar e desperdício para
registrar que alguém abriu uma página, e o SQLite faria a visita à página esperar na fila atrás do
empréstimo se as duas passassem pelo mesmo hábito.

## Escrever a escolha

Uma escolha feita por operação deve ficar visível por operação, ao lado do código que a faz, para a
próxima pessoa ver que foi uma escolha. Algo tão simples quanto isto resolve:

```python
READS = {
    "lend": "primary",             # the last copy must not go out twice
    "pay_fine": "primary",         # money: refuse rather than guess
    "place_hold": "any branch",    # the queue is reordered by time later
    "catalogue_page": "replica",   # a few seconds stale is fine
}
```

A lição 8 separou leituras de escritas para cada lado ter a forma do seu trabalho. Esta lição
acrescenta o outro eixo dessa separação: o lado de escrita de uma biblioteca quer consistência, e
a maior parte do lado de leitura pode trocá-la por velocidade. A lição 12 estreita mais uma vez, até
o menor grupo de dados que precisa mudar numa transação, e dá nome a esse grupo.
