---
title: Um limite por usuário, para uma pessoa não gastar o de todos
version: 1
---

Um fornecedor limita cada chave: tantas requisições por minuto, tantos tokens por minuto, tanto por
mês. Esses limites protegem o fornecedor. **Não protegem os usuários da Tarefa uns dos outros**,
porque o orçamento de uma chave é dividido por todos que a usam, e uma pessoa com um script consegue
gastá-lo por todos.

O `data/api-requests.jsonl` são cinco minutos do tráfego do assistente, escritos pelo laboratório:
seis usuários, cada requisição marcada com o identificador da seção anterior, todas na única chave da
Tarefa. Durante o segundo e o terceiro minuto, um dos seis roda um script.

```
ana@lab:~/guard$ head -3 data/api-requests.jsonl
{"t": 0, "key": "tarefa-prod", "end_user": "eu-b37c05e8d1a294f6c0a3"}
{"t": 2, "key": "tarefa-prod", "end_user": "eu-2b8e41c07d93a5f60e1c"}
{"t": 2, "key": "tarefa-prod", "end_user": "eu-5c0d9f72aa1e48b3c6d2"}
ana@lab:~/guard$ guard ratelimit data/api-requests.jsonl --per-key 60
limits: 60 a minute per key
end user                   sent  allowed  refused
eu-2b8e41c07d93a5f60e1c      19       18        1
eu-5c0d9f72aa1e48b3c6d2      27       26        1
eu-7e3a18b5c90f2d64a1b7      11       10        1
eu-91f4d2a6e07c3b85d1e9      26       21        5
eu-b37c05e8d1a294f6c0a3      19       16        3
eu-e60a7d3c4b19f8e25d07     207       97      110
6 of 6 users had a request refused
```

Sessenta por minuto na chave fazem as vezes do limite do fornecedor. Todos os seis usuários tiveram
requisições recusadas. Os cinco que não fizeram nada de estranho perderam 11 entre eles, e o
`eu-91f4d2a6e07c3b85d1e9` perdeu 5 de 26. O script, `eu-e60a7d3c4b19f8e25d07`, ainda passou 97
requisições, porque um limite compartilhado recusa quem chega quando a janela está cheia, e quem mais
chega é o script. Para os outros cinco, o assistente parou de responder em momentos aleatórios durante
aqueles dois minutos, sem motivo que eles pudessem ver.

Agora o mesmo tráfego com um limite por usuário na frente do da chave, limite que só a Tarefa pode
aplicar, porque só a Tarefa sabe para quem é cada requisição:

```
ana@lab:~/guard$ guard ratelimit data/api-requests.jsonl --per-key 60 --per-user 20
limits: 60 a minute per key, 20 a minute per user
end user                   sent  allowed  refused
eu-2b8e41c07d93a5f60e1c      19       19        0
eu-5c0d9f72aa1e48b3c6d2      27       27        0
eu-7e3a18b5c90f2d64a1b7      11       11        0
eu-91f4d2a6e07c3b85d1e9      26       26        0
eu-b37c05e8d1a294f6c0a3      19       19        0
eu-e60a7d3c4b19f8e25d07     207       47      160
1 of 6 users had a request refused
```

O script fica preso a 20 por minuto e passa 47. Ninguém mais perde uma requisição, e o limite da chave
nunca é atingido. **O limite por usuário fica bem abaixo do da chave**, para que nenhum usuário consiga
sozinho gastar o orçamento da chave: 20 por minuto é um terço dele aqui.

## O que mais depende do identificador

**Uma recusa que o usuário entende.** A requisição recusada recebe um HTTP 429 com um cabeçalho
`Retry-After` e uma mensagem dizendo que o limite é por pessoa, para que um usuário legítimo que o
atinja saiba esperar em vez de tentar de novo em loop, o que só o deixaria recusado por mais tempo.

**Custo, não só contagem.** Uma requisição pode levar algumas centenas de tokens ou cem mil. Um limite
de requisições limita o ritmo; um orçamento diário de tokens por usuário limita a conta. Os dois são
mantidos pelo mesmo identificador, e o segundo é o que impede um usuário de transformar um plano
gratuito no processamento em lote de outra pessoa.

**Um relatório de abuso sobre o qual dá para agir.** Quando um fornecedor escreve dizendo que
requisições marcadas `eu-e60a7d3c4b19f8e25d07` violaram as políticas dele, a Tarefa precisa achar a
conta. Recalcular o identificador de todas as contas funciona e é lento; guardar o identificador ao
lado de cada conta, no banco da própria Tarefa, faz disso uma consulta indexada. Essa tabela é dado
pessoal como a conta em que está, e é eliminada com ela.

**Um limite nunca é a defesa inteira.** Um usuário determinado abre uma segunda conta. Limites por
usuário fazem o abuso custar uma conta por orçamento, e é por isso que a aula 18 trata de quem recebe
uma conta, e de quanto ela pode fazer, antes de merecer mais.
