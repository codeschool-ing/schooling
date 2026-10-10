---
title: O que medir primeiro
version: 1
---

Um programa pode emitir milhares de métricas, e a maioria dos painéis falha por mostrar todas. Duas
listas curtas, cada uma para um tipo de coisa, cobrem a maior parte do que importa.

**Para um serviço que responde pedidos, RED**, de Tom Wilkie:

- **Rate**, a taxa: pedidos por segundo.
- **Errors**, os erros: quantos deles falham.
- **Duration**, a duração: quanto tempo levam, como uma distribuição, não uma média.

Isso é a bilheteria do lado dos usuários, e é o que o `load.py` imprimiu em toda aula: pedidos por
segundo, status, quatro pontos de latência. A diferença agora é que a própria bilheteria vai
informá-los, para todo pedido de todo cliente, o tempo todo.

**Para um recurso pelo qual o trabalho espera, USE**, de Brendan Gregg:

- **Utilisation**, a utilização: a fatia do tempo em que ele está ocupado. O processador a 100% da
  aula 1.
- **Saturation**, a saturação: quanto trabalho está esperando por ele. A fila que fez a latência
  dobrar com os trabalhadores, e as quinze conexões esperando uma trava na linha quente da aula 1.
- **Errors**, os erros: com que frequência ele falha.

Recursos são processadores, memória, discos, pools de conexões, travas. **O RED diz que os usuários
estão sofrendo; o USE diz por quê.** O gargalo da aula 1 é, nessas palavras, um recurso cuja
utilização está perto de 100% e cuja saturação não para de crescer.

O livro do Google sobre engenharia de confiabilidade de sites dá uma lista bem parecida de quatro
**sinais de ouro**, latência, tráfego, erros e saturação, que é o RED com a saturação acrescentada.

## A bilheteria, contra as listas

| | o que a bilheteria vai informar | onde nesta aula |
|---|---|---|
| taxa | `tickets_requests_total`, um contador por rota e status | seção 06 |
| erros | o mesmo contador, status 500 | seção 08 |
| duração | `tickets_request_seconds`, um histograma por rota | seção 07 |
| utilização | `process_cpu_seconds_total`, que a biblioteca informa de graça | seção 06 |
| saturação | `tickets_in_flight`, pedidos em andamento | seção 06 |

Cinco séries de números, e com elas toda pergunta feita à bilheteria nas aulas 1 a 6 pode ser
respondida depois do fato.
