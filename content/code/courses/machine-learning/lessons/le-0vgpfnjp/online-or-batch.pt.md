---
title: Um de cada vez, ou todos de uma vez
version: 1
---

As duas primeiras linhas do `compare.py` mediram outra coisa também. Com um assinante por pedido, o servidor levou cerca de 12 milissegundos cada, a maior parte de um minuto para o mês. Com o mês inteiro numa chamada, o mesmo modelo levou 32 milissegundos para os 4.540. **Por assinante, o
lote foi bem mais de mil vezes mais rápido.** O modelo não fica mais lento no servidor. Quase todos esses
12 milissegundos são o caminho: abrir uma conexão, codificar JSON, conferi-lo, montar uma tabela de uma
linha e fazer a viagem inteira de volta.

Isso dá os dois jeitos mais comuns de pôr um modelo para trabalhar:

| | **online** | **em lote** |
|---|---|---|
| perguntado | quando algo acontece, um caso de cada vez | num horário marcado, todos os casos de uma vez |
| responde | em milissegundos, enquanto alguém espera | num arquivo ou numa tabela, antes de alguém precisar |
| serve a | uma decisão tomada na hora: uma compra, uma ligação que acabou de chegar | uma decisão tomada para todos: quem recebe crédito este mês |
| aqui | `app.py` | o `score_2026.py` da aula 15 |

**O crédito da Feira em Casa é uma decisão em lote.** Ele é decidido uma vez por mês, a partir de um
retrato tirado no dia 1º, para todo assinante. Pontuar o mês numa chamada, gravar as chances num arquivo e
deixar a equipe de retenção trabalhar a lista é mais simples, mais barato e mais fácil de conferir que
4.540 pedidos. A API ganha o seu lugar onde a decisão não pode esperar o dia 1º: o atendente ao telefone
com um assinante que acabou de reclamar, perguntando se é alguém a quem oferecer o crédito agora.

A maioria das empresas acaba com os dois, e esse é o argumento mais forte para o arranjo desta aula: **um
modelo gravado, carregado pelos dois caminhos**, com o `compare.py` mantendo os dois honestos. A aula 22
pega o caminho em lote e fica nele por três meses.
