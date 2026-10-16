---
title: O curso, como um log de decisões
version: 1
---

Aqui está este curso escrito como os registros que a equipe da Quitanda teria guardado, na ordem em que as
aulas chegaram a eles. Cada linha é uma decisão com um contexto que pode mudar, e cada uma delas poderia
ser substituída um dia por uma versão mais bem informada da mesma equipe:

| aula | a decisão |
| --- | --- |
| 1, 2 | um monólito modular primeiro; tirar um módulo só quando uma força da aula 2 exigir |
| 4 | configuração no ambiente, logs na saída padrão, uma base de código por implantável |
| 5 | chamadas síncronas com timeout onde quem chama precisa da resposta agora; mensagens onde não precisa |
| 6, 7 | entrega pelo menos uma vez, consumidores idempotentes, e um outbox onde uma mudança e o evento dela andam juntos |
| 8, 9 | consistência para o estoque tirado no checkout e para dinheiro; disponibilidade, marcada como aproximada, para o que uma página mostra |
| 10 | um PostgreSQL com standby; sharding só quando uma medição disser que uma máquina não basta |
| 11, 12 | timeouts, retries com orçamento, um breaker e um bulkhead por dependência; limites de taxa na porta |
| 13 | event sourcing para pagamentos e o livro de estoque, e em nenhum outro lugar |
| 14 | o checkout como uma saga orquestrada, com reservas como trava |
| 15 | serviços novos tirados com uma fachada strangler, nunca por uma reescrita |
| 16 | nada de `SELECT *` no código da aplicação; caches e modelos de leitura para perguntas que todo visitante faz |
| 17 | busca a partir de uma cópia alimentada por eventos, reconstruída a partir do banco sempre que preciso |
| 18 | Server-Sent Events para o status do pedido, com um backplane a partir da segunda instância |
| 19 | um gateway como a porta da loja; um registro quando a plataforma trouxer um |

Nenhuma delas é a resposta certa em geral, e essa é a única afirmação duradoura do curso: **arquitetura é
escolher que custos pagar, por motivos que podem ser escritos**, e mudar a escolha quando os motivos
mudam. Uma equipe que guarda os motivos consegue fazer essa mudança de propósito.

Quando terminar, o laboratório não tem nada para parar. Apague o diretório dele se quiser:

```sh
rm -rf ~/lab/adr
```
