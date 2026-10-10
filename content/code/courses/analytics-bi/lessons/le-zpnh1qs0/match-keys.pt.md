---
title: A chave que reconhece um cliente
version: 1
---

A sincronização manda `PUT /contacts/lantern-1500`, e o CRM atualiza o registro com essa chave ou o
cria. Esse padrão se chama **upsert**, e depende inteiramente de os dois lados concordarem sobre a
chave. O que acontece sem uma é fácil de mostrar. Muitas integrações com CRM são escritas com `POST`,
que quer dizer "crie um contato", e rodam mais de uma vez — depois de uma falha, ou porque duas pessoas
agendaram o mesmo trabalho. Salve isto como `post-twice.sh` e rode:

```sh
curl -s -X POST localhost:8000/contacts -H 'Content-Type: application/json' \
  -d '{"external_id": "lantern-10", "segment": "home", "health": "lapsed"}'; echo
curl -s -X POST localhost:8000/contacts -H 'Content-Type: application/json' \
  -d '{"external_id": "lantern-10", "segment": "home", "health": "lapsed"}'; echo
```

```
ana@vm:~/reverse$ bash post-twice.sh
{"status": "created", "crm_id": 2650}
{"status": "created", "crm_id": 2651}
ana@vm:~/reverse$ curl -s -w '\n' 'localhost:8000/contacts?external_id=lantern-10'
[{"external_id": "lantern-10", "segment": "home", "region": "South", "orders": 1, "net_revenue": 41.31, "last_order": "2025-06-11", "health": "lapsed", "crm_id": 1}, {"external_id": "lantern-10", "segment": "home", "health": "lapsed", "crm_id": 2650}, {"external_id": "lantern-10", "segment": "home", "health": "lapsed", "crm_id": 2651}]
```

As duas requisições deram certo, e o `curl` depois do script pergunta ao CRM o que ele guarda para essa
chave: três registros para um cliente, o que a sincronização fez com `PUT` e duas cópias feitas com
`POST`. Cada um vai aparecer para um vendedor, cada um pode ser editado separadamente, e um relatório de
contatos conta o cliente três vezes. **Duplicatas são a falha que define as sincronizações para
ferramentas de operação**, e o CRM não fez nada errado: `POST` quer dizer criar, então ele criou.

## Qual chave

A chave de casamento precisa ser algo que identifique o cliente, nunca mude e exista dos dois lados:

| candidata | problema |
|---|---|
| o id do próprio CRM (`crm_id`) | a loja não o conhece até o CRM ter criado o registro |
| o endereço de e-mail | as pessoas o trocam, o compartilham e o digitam com maiúsculas; dois registros para uma pessoa, ou um para duas |
| o id de cliente da loja (`lantern-1500`) | nenhum desses: é atribuído uma vez, pelo sistema dono do cliente |

A maioria dos CRMs deixa você acrescentar um campo personalizado marcado como **id externo**, único e
indexado, justamente para que um upsert possa casar por ele. A sincronização usa o id da loja como esse
campo desde a primeira requisição, e por isso nunca precisa saber o número do CRM.
