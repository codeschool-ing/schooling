---
title: Para onde vai o inesperado
version: 1
---

A última linha da tabela, *algo que ninguém esperava*, não tem frase para o usuário. Tem uma linha no log do
servidor, e o log é parte do produto tanto quanto a página.

O loanbook escreve uma linha por requisição, com o método, o caminho e o status com que respondeu:

```
ana@laptop:~/loanbook$ cat app.log
loanbook on http://127.0.0.1:8000
GET /api/nothing 404
POST /api/items/1/loan 400
POST /api/items/9/loan 404
POST /api/items/1/loan 400
POST /api/items/1/loan 201
POST /api/items/1/loan 409
POST /api/items/1/return 200
POST /api/items/1/return 409
```

São oito requisições e oito linhas, e uma pessoa lendo isso depois de uma reclamação vê exatamente o que
aconteceu: duas requisições ruins, um item desconhecido, um empréstimo, uma recusa, uma devolução, e uma
devolução recusada. A linha é escrita por `log_message`, que o loanbook sobrescreve para cada requisição
virar uma linha com o status no fim, em vez do padrão da biblioteca com a data e o endereço do cliente.

Três regras para o que o log de um projeto de portfólio diz:

- **Uma linha por evento, sempre no mesmo formato**, para dar para procurar com `grep` e para uma
  ferramenta ler depois, aula 15.
- **O bastante para encontrar a requisição, e não mais.** O caminho e o status, sim. O corpo da requisição,
  não: ele tem nomes de pessoas, e um log é guardado por mais tempo e lido por mais gente que um banco.
- **Traceback para o inesperado, nunca para o esperado.** O log do passo 7 tinha um traceback para um corpo
  ruim, que era um erro do usuário fantasiado de pane. Depois do passo 8, um traceback no log quer dizer um
  bug, e um log em que traceback quer dizer bug é um log que alguém de fato vai ler.
