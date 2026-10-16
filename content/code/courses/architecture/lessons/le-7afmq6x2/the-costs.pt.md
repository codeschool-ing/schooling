---
title: Os custos, e quando pagá-los
version: 1
---

O event sourcing é um dos padrões de que mais gente se arrepende, e o arrependimento raramente é com a
ideia. É com custos que só chegam depois:

| custo | por que chega | o que se faz |
| --- | --- | --- |
| **eventos são para sempre** | um evento gravado em 2024 com um campo chamado `units` ainda tem de ser lido em 2030, depois de o código tê-lo renomeado três vezes | versionar os tipos de evento, e **converter** (*upcast*) versões antigas para as novas ao lê-las |
| **reaplicar fica lento** | um pedido com 5.000 eventos são 5.000 linhas para ler a cada comando | guardar um **snapshot** a cada poucas centenas de eventos e reaplicar só o que vem depois dele |
| **apagar uma pessoa** | um armazenamento só de acréscimos não consegue apagar o que a LGPD manda apagar | manter dados pessoais fora dos eventos, ou cifrá-los por pessoa e apagar a chave (*crypto-shredding*) |
| **todo modelo de leitura atrasa** | projeções são cópias, a aula 9 vale em todo lugar | ler as próprias escritas a partir da resposta do comando; mostrar a idade onde importa |
| **outro jeito de pensar** | a equipe tem de modelar mudanças como fatos, e a maior parte do código e das ferramentas supõe tabelas de estado atual | começar por uma parte do sistema que claramente se beneficia, não por todas |

## Quando vale a pena

CQRS sem event sourcing é um passo modesto, e muitas vezes bom: um modelo de leitura mantido por uma
projeção ou um outbox, onde uma consulta ficou grande demais para o modelo de escrita. **Event sourcing é
um compromisso maior**, e se paga onde o histórico é o próprio produto: dinheiro, movimentos de estoque,
qualquer coisa auditada, qualquer coisa em que "como estava no dia 3" é uma pergunta que alguém faz.

Para a Quitanda, isso aponta para os **pagamentos e o livro de estoque**, que já são só de acréscimos no
espírito. Não aponta para o catálogo, onde ninguém nunca vai perguntar o que a descrição de um produto
dizia em março, e uma tabela comum com uma réplica de leitura é todo o projeto de que ele precisa.

Quando terminar, pare o laboratório:

```sh
docker compose down -v
```
