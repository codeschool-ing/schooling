---
title: Uma linha de log é dado
version: 1
---

Desde a aula 2, o boxoffice registra uma linha por requisição:

```
2026/10/16 19:29:24 GET /events/9 404 14B 19µs
```

Uma pessoa lê com facilidade. **Um programa que lê dez milhões delas tem de adivinhar**: que a quarta
palavra é o status, que `14B` é um tamanho, que `19µs` é uma duração numa unidade que vira `ms` quando
cresce. No dia em que alguém acrescentar um campo no meio, todo script que dividia essas linhas por espaço
lê a coluna errada, em silêncio.

**Um log estruturado escreve cada linha como campos com nome**, num formato que uma máquina interpreta sem
adivinhar, quase sempre JSON com um objeto por linha. A mesma requisição vira:

```json
{"time":"2026-10-22T19:20:06.575241195-03:00","level":"INFO","msg":"request","request_id":"875cefab9e03dc1c","method":"GET","path":"/events/9","status":404,"bytes":90,"duration_ms":0.3}
```

Mais longa, e **cada valor agora tem nome e tipo**: `status` é o número 404, `duration_ms` é sempre em
milissegundos. Os sistemas que coletam logs de servidores, de qualquer fornecedor, indexam campos como
esses, e então "todo 5xx em `/events` na última hora, do mais lento ao mais rápido" é uma consulta e não um
script.

Três ideias vêm com a estrutura, e esta aula usa as três:

- **Níveis.** Cada linha diz o quanto importa, em geral `DEBUG`, `INFO`, `WARN` e `ERROR`, e um serviço
  pode ser instruído a descartar as que ficam abaixo de um nível.
- **Campos de contexto.** Um id de requisição anexado uma vez, no começo, aparece em toda linha escrita
  enquanto aquela requisição é atendida, e assim todas as linhas de uma requisição são encontradas juntas.
- **Uma mensagem que é constante.** `"request"` ou `"ticket sold"`, o mesmo texto toda vez, com as partes
  variáveis em campos. Uma mensagem montada com `Printf` é uma string diferente a cada linha, e não dá para
  contá-la nem agrupá-la.

A biblioteca padrão do Go tem um logger estruturado desde o Go 1.21, em `log/slog`. Duas bibliotecas eram
muito usadas antes de ele existir, o zerolog e o zap, e continuam em muitas bases de código. Esta aula usa
as três nas mesmas linhas, e dá ao boxoffice a primeira.
