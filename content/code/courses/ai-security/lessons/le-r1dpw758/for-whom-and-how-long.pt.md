---
title: Um arquivo por cliente, e uma data em cada linha
version: 1
---

Toda memória tem duas propriedades que o código define e o modelo nunca toca: **de quem ela é**, e
**até quando pode ser usada**.

## De quem

O depósito é um arquivo por conta, `data/memory/ACCOUNT.jsonl`, e o assistente que responde a um
cliente lê o arquivo desse cliente e nenhum outro:

```
ana@lab:~/guard$ guard memory show --as ac-7Q2M --now 2026-03-21
ac-7Q2M on 2026-03-21, memories in use: 4
  m1  job        until 2026-05-31  4471
  m2  preference until 2027-03-02  dark blue logo color
  m3  job        until 2026-06-07  always pays by Pix
  m4  preference until 2027-03-20  weekly updates preferred
ana@lab:~/guard$ guard memory show --as ac-0Z5Q --now 2026-03-21
ac-0Z5Q on 2026-03-21, memories in use: 0
```

O `ac-0Z5Q` não tem nada, porque nada no depósito é dele. Parece óbvio, e é a regra quebrada por
acidente com mais frequência: memórias guardadas numa tabela compartilhada e buscadas por semelhança,
do jeito que a busca da aula 15 funcionava antes do `--as`, um dia entregam a preferência de um
cliente a outro. **A conta vem da sessão, como na aula 15**, e o depósito é dividido por ela antes de
qualquer busca.

## Por quanto tempo

Cada linha leva o `until`, calculado a partir do tipo: uma preferência é guardada por um ano, um fato
sobre um trabalho por noventa dias, porque um trabalho termina e uma preferência costuma durar mais
que um. Em 1º de julho, as memórias de trabalho de março já passaram da data:

```
ana@lab:~/guard$ guard memory show --as ac-7Q2M --now 2026-07-01
ac-7Q2M on 2026-07-01, memories in use: 2
  m2  preference until 2027-03-02  dark blue logo color
  m4  preference until 2027-03-20  weekly updates preferred
ana@lab:~/guard$ wc -l < data/memory/ac-7Q2M.jsonl
4
ana@lab:~/guard$ guard memory sweep --now 2026-07-01
ac-7Q2M: 2 deleted, 2 kept
ana@lab:~/guard$ wc -l < data/memory/ac-7Q2M.jsonl
2
```

A ordem desses quatro comandos é o ponto. O `show` parou de usar as duas memórias vencidas, e o arquivo
continuava com as quatro linhas. **Uma memória que o assistente não usa mais continua sendo dado
pessoal que a Tarefa guarda**, e a pergunta da LGPD na aula 12 é sobre o que é guardado, não sobre o
que é usado. O `sweep` apagou as duas, e o arquivo foi de quatro linhas para duas. Em produção a
varredura roda todo dia, como a varredura de logs da aula 11.

A retenção por tipo é uma decisão sem um único número certo, e a equipe anota por que escolheu o que
escolheu. O que não é decisão é existir um limite: **uma memória sem data de validade é guardada para
sempre por padrão**, e isso ninguém escolheu.
