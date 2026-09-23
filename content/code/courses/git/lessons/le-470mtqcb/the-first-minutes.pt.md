---
title: Os primeiros cinco minutos
version: 1
---

A aula 13 foi o lado da Ana no pull request #31. Esta é a do Bruno. Quatro comentários chegaram na
mudança dele:

- `blocking:` com o campo vazio, o *Order* ainda envia. Pôr `required` evitaria isso.
- `question:` dá para escolher 03:00, quando estamos fechados?
- `nit:` *Place order* diz mais que *Order*.
- A mudança de cor do título afeta todas as páginas. Ela pode ir num pull request próprio?

## Não responda ainda

As piores respostas a uma revisão são escritas nos primeiros cinco minutos. **Leia todos os comentários
antes de responder a qualquer um.** Uma observação que incomoda sozinha muitas vezes faz sentido ao lado
das outras, e o segundo comentário às vezes responde à pergunta que o primeiro levantou.

Depois ordene como quem revisou deveria ter rotulado, e aqui a Ana rotulou: primeiro o que bloqueia,
depois a pergunta, e o nit por último. Se quem revisou não disse quão grave é um comentário, pergunte, ou
trate como bloqueio até a pessoa dizer o contrário.

## É sobre o código

A sensação de que um comentário é sobre você é normal, e quase sempre está errada. A Ana não escreveu *"o
Bruno esqueceu a validação"*; escreveu que um campo vazio envia. Duas coisas ajudam isso a assentar:

- **O comentário achou um bug antes de um cliente achar.** Esse era o motivo de pedir revisão. Um pedido
  vazio descoberto pela Ana custa uma linha; descoberto pela padaria às seis da manhã custa um cliente.
- **Todo código recebe comentários**, inclusive o de quem revisa. Gente experiente recebe menos
  comentários que bloqueiam, não zero, e recebe muitas perguntas.

Se um comentário é mesmo sobre você (*"você sempre faz isso"*), o problema é do comentário, e é justo
dizer isso, com calma e fora do pull request, à pessoa ou a quem cuida da equipe. É raro. Muito mais
comum é um comentário curto, escrito com pressa, soar mais duro do que a intenção.

## Escolha a melhor leitura

Texto perde o tom. *"Por que isto está aqui?"* pode ser curiosidade ou acusação, e quem lê escolhe qual
ouvir. **Escolha a leitura generosa, e responda como pergunta.** Se você estava errado, não perdeu nada; se
estava certo, respondeu ao que foi perguntado.
