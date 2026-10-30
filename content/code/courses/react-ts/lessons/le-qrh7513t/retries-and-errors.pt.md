---
title: Quando o servidor não responde
version: 1
---

**Uma query que falha é tentada de novo antes de ser relatada.** A maioria das falhas é momentânea,
uma conexão que caiu ou um servidor reiniciando, e uma segunda tentativa logo depois dá certo. Pare o
servidor da API e carregue a página, dando a ela nove segundos:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network --do 'wait 9000' | grep -E 'api|alert|error'
net  GET /api/planner  502
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
net  GET /api/planner  502
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
net  GET /api/planner  502
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
net  GET /api/planner  502
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
- alert: The planner could not be loaded.
```

Quatro requisições a `/api/planner`, cada uma respondida com **502 Bad Gateway** pelo proxy do Vite,
que não tinha para onde encaminhá-las. A biblioteca tentou uma vez, depois mais três, esperando mais
antes de cada uma, cerca de um, dois e quatro segundos; só depois da quarta falha o `isError` virou
true e o planejador desenhou o alerta. O console tem a linha do navegador para cada falha, as mesmas
mensagens que um usuário veria nas próprias ferramentas de desenvolvedor.

Três coisas nessa transcrição são decisões que você pode mudar, por query ou para o cliente inteiro:

| padrão | o que significa | quando mudar |
|---|---|---|
| `retry: 3` | três novas tentativas depois da primeira falha | `0` para uma requisição que não pode ser repetida, ou em testes, para as falhas serem rápidas |
| uma espera que dobra, até 30 segundos | o servidor ganha tempo para se recuperar | raramente |
| erros do `queryFn` são relatados quando as tentativas acabam | `isError`, e o erro em `error` | nunca: uma falha precisa chegar à tela |

**Mutações não são tentadas de novo por padrão**, e por um bom motivo: um `POST` que chegou ao
servidor e perdeu a resposta na volta acrescentaria a sessão duas vezes se repetido. Uma query só lê,
então ler duas vezes não faz mal.

O alerta é o que a aula 5 desenhava, agora movido pela biblioteca. Ele diz ao usuário que algo falhou e
não oferece nada a fazer, e recarregar não é algo em que um usuário deva ter de pensar. A aula 12 dá à
falha uma tela com uma saída, e usa o `refetch` da biblioteca para isso.
