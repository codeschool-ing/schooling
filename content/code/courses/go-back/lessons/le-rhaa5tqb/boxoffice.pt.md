---
title: O que o boxoffice é agora
version: 1
---

Esta aula mudou o boxoffice em mais lugares que qualquer outra antes dela, e cada mudança apareceu
inteira onde foi feita. Eis onde cada uma foi parar, e o que o serviço faz agora que não fazia antes.

| arquivo | mudou na | o que faz agora |
|---|---|---|
| `migrations/00001_events.sql` | seção 03 | a tabela da aula 6 e seus dois eventos, como versão 1 |
| `migrations/00002_tickets.sql` | seção 03 | o registro de toda venda, como versão 2 |
| `sqlc.yaml`, `queries.sql` | seção 03 | o schema lido das migrações; uma consulta a mais, `InsertTicket` |
| `migrate.go` | seção 04 | aplica as migrações embutidas na inicialização, sob um lock |
| `main.go` | seção 04 | migra, e depois monta um pool de no máximo 10 conexões |
| `store.go` | seção 05 | o `Sell` recebe o e-mail do comprador e devolve um `Sale` |
| `events.go` | seção 05 | o recibo traz o id do ingresso |
| `pgstore.go` | seção 07 | a venda e o ingresso numa transação, toda consulta passando por ela |
| `schema.sql` | seção 03 | apagado |

**Três garantias valem agora e não valiam no fim da aula 8.** Qualquer cópia do banco, vazia ou
atrasada, chega ao mesmo schema pelos mesmos passos numerados, aplicados pelo próprio binário. Nenhuma
venda existe sem o seu ingresso, nem um ingresso sem a sua venda. E vinte compradores ao mesmo tempo
recebem exatamente tantos ingressos quantos lugares há, os outros ouvem isso, e o servidor continua
respondendo a todo o resto.

O que o boxoffice ainda diz sobre tudo isso são as linhas de `log.Printf` da aula 2, que uma pessoa lê e
um programa não consegue pesquisar com facilidade. **A aula 12 torna os logs estruturados.** Antes
disso, as aulas 10 e 11 dão a ele um segundo jeito de ser chamado, por outros serviços em vez de por
navegadores.
