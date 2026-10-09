---
title: Recusas que ajudam, e confirmações que dá para ler
version: 1
---

As outras duas falhas do rascunho são sobre momentos em que o assistente para: uma recusa, e uma
confirmação antes de uma ação.

## Uma recusa diz por quê e o que fazer

A `refusal-budget` é a tela que o cliente vê quando o orçamento da aula 18 acaba. Ela diz *algo deu
errado, tente de novo* e oferece um botão, `retry`. Cada metade está errada de um jeito:

- **"algo deu errado" esconde uma decisão atrás de um erro.** Nada deu errado; um limite que a Tarefa
  definiu foi atingido. Um cliente a quem dizem que é uma falha espera que ela seja corrigida, ou
  denuncia um bug.
- **"tente de novo" contra um limite é o laço da aula 18**, agora movido por uma pessoa apertando um
  botão. A nova tentativa não pode dar certo antes de amanhã, e cada clique custa uma recusa.

A `refusal-scope`, ao contrário, passou: diz o que o assistente pode fazer, que outra coisa está fora
disso, quem pode ajudar no lugar e em quanto tempo. **Uma recusa que nomeia o próximo passo transforma
um beco sem saída numa rota.** Ela não precisa dar o motivo em detalhe, e uma recusa disparada por um
filtro de segurança não deveria descrever o filtro, mas sempre diz o que o cliente pode fazer agora.

## Uma confirmação mostra a ação

A `confirm-refund` diz *o assistente quer emitir um reembolso. Permitir?* A aula 10 reteve o reembolso
para uma pessoa justamente para que alguém o conferisse, e **uma pessoa só confere o que a tela
mostra**. Sem a conta, o trabalho e o valor, "Permitir?" pede confiança, e quem confirma é um clique no
caminho, não uma verificação. A regra pega os argumentos da ferramenta e recusa uma confirmação que
mostre menos.

## O rascunho, corrigido

Uma segunda versão das mesmas seis telas, também escrita pelo curso, com cada tela reprovada reescrita:
as boas-vindas dizem que é automatizado, toda resposta pode ser denunciada, a recusa de orçamento diz
que o assistente não consegue responder mais hoje e oferece uma pessoa, e a confirmação mostra a conta,
o trabalho e o valor. Cole:

```sh
cat > ~/guard/data/ui-copy-fixed.json <<'EOF'
[
 {"id": "chat-welcome", "kind": "chat",
  "text": "Hi! I'm Tarefa's automated assistant. I can help with your jobs, payments and account, and a person on our team is one click away.",
  "actions": ["talk-to-a-person"]},
 {"id": "reply", "kind": "reply",
  "text": "{reply}",
  "actions": ["copy", "report"]},
 {"id": "refusal-budget", "kind": "refusal",
  "text": "I cannot answer more questions today. A person on our team can help now, or I will be back tomorrow at 00:00.",
  "actions": ["talk-to-a-person"]},
 {"id": "refusal-scope", "kind": "refusal",
  "text": "I can only help with jobs, payments and accounts on Tarefa. For anything else, a person on our team can help: they reply within one business day.",
  "actions": ["talk-to-a-person"]},
 {"id": "confirm-refund", "kind": "confirm", "tool": "issue_refund",
  "text": "Refund {cents} to account {account} for job {job}, the amount paid. This cannot be undone.",
  "shows": ["account", "job", "cents"],
  "actions": ["allow", "cancel"]},
 {"id": "memory-panel", "kind": "memory",
  "text": "What the assistant remembers about you, and until when.",
  "actions": ["delete-one", "delete-all"]}
]
EOF
```

```
ana@lab:~/guard$ guard uxcheck data/ui-copy-fixed.json; echo "exit status $?"
chat-welcome    chat     ok
reply           reply    ok
refusal-budget  refusal  ok
refusal-scope   refusal  ok
confirm-refund  confirm  ok
memory-panel    memory   ok
6 screens, 0 breaking a rule
exit status 0
```

Todas as telas passam e o status de saída é 0, então a mesma verificação pode rodar no build e reprovar
o pull request que tirar a palavra *automated* das boas-vindas. O que ela não consegue julgar é se as
palavras são gentis, claras e na língua do cliente; essa revisão é de uma pessoa, com a tela na frente.
