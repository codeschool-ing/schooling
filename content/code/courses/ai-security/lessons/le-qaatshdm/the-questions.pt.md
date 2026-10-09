---
title: O que perguntar a uma empresa antes de mandar a ela as palavras dos seus clientes
version: 1
---

Todo prompt que o assistente da Tarefa monta sai para uma empresa que a Tarefa não opera. A aula 12
decidiu o que pode entrar num prompt; a aula 13 desenhou o fluxo que cruza para a zona do fornecedor.
**Esta aula é sobre escolher quem está do outro lado desse fluxo**, porque as práticas do fornecedor
viram as da Tarefa: um fornecedor que guarda prompts por um ano significa que as palavras dos clientes
da Tarefa existem por um ano, e nada no código da própria Tarefa muda isso.

A escolha começa com uma lista curta de perguntas escrita antes de alguém ler uma página de vendas,
para que as respostas sejam comparadas com as necessidades da Tarefa, e não umas com as outras. A lista
da Tarefa, escrita pelo curso, cada pergunta um **MUST**, que elimina um fornecedor, ou um **SHOULD**,
que conta a favor dele:

```sh
cat > ~/guard/data/requirements.json <<'EOF'
[
 {"id": "training", "kind": "must", "want": false, "question": "Is customer data used to train the provider's models?"},
 {"id": "retention_days", "kind": "must", "max": 30, "question": "How many days are prompts and replies kept?"},
 {"id": "dpa", "kind": "must", "want": true, "question": "Is a data processing agreement signed?"},
 {"id": "region", "kind": "must", "allowed": ["BR", "EU", "US"], "question": "Where is the data processed?"},
 {"id": "incident_hours", "kind": "must", "max": 48, "question": "Within how many hours is a customer told of an incident?"},
 {"id": "subprocessors", "kind": "should", "want": true, "question": "Is the list of subprocessors published?"},
 {"id": "audit", "kind": "should", "want": true, "question": "Is there an independent audit report?"},
 {"id": "pinning", "kind": "should", "want": true, "question": "Can a model version be pinned, with notice before it is retired?"},
 {"id": "exit_deletion", "kind": "should", "want": true, "question": "Is all data deleted, with confirmation, when the contract ends?"}
]
EOF
```

Cada linha está ali por um motivo que alguém consegue dizer numa frase:

| pergunta | tipo | por quê |
|---|---|---|
| `training` | MUST | texto usado para treinar um modelo pode reaparecer em respostas a outros clientes, e é uma finalidade com que os clientes nunca concordaram |
| `retention_days` | MUST, no máximo 30 | o que o fornecedor guarda pode vazar do fornecedor; menos guardado é menos exposto, o argumento da aula 11 |
| `dpa` | MUST | pela LGPD o fornecedor é um operador agindo sob instruções da Tarefa, e o acordo é onde essas instruções ficam escritas |
| `region` | MUST, uma de três | dados tratados fora do Brasil são uma transferência internacional, que a aula 12 disse precisar de base legal e salvaguardas |
| `incident_hours` | MUST, no máximo 48 | o regulamento da ANPD sobre incidentes de segurança dá à Tarefa três dias úteis para comunicar; um fornecedor que avisa a Tarefa no quarto não deixa tempo |
| `subprocessors` | SHOULD | os fornecedores do próprio fornecedor também veem os dados, e a Tarefa só consegue avaliar uma lista que consegue ler |
| `audit` | SHOULD | um relatório independente, como um SOC 2 Tipo II ou um certificado ISO/IEC 27001, é alguém além do fornecedor dizendo que os controles existem |
| `pinning` | SHOULD | um modelo que muda por baixo do assistente muda cada comportamento que as aulas 14 a 16 mediram |
| `exit_deletion` | SHOULD | sair de um fornecedor não deveria deixar os dados dos clientes para trás |

A divisão entre MUST e SHOULD é a decisão que mais importa. **Um MUST é uma linha que a Tarefa não
cruza por um preço melhor ou um modelo melhor**, e escrevê-la antes da comparação é o que impede que
ela seja renegociada na reunião em que um fornecedor sai mais barato. De três a seis MUSTs é o comum;
uma lista em que tudo é MUST elimina todos os fornecedores e acaba ignorada em silêncio.
