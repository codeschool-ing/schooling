---
title: What to ask a company before sending it your clients' words
version: 1
---

Every prompt Tarefa's assistant builds leaves for a company Tarefa does not run. Lesson 12 decided
what may go in a prompt; lesson 13 drew the flow that crosses into the provider's zone. **This lesson
is about choosing who is on the other side of that flow**, because the provider's practices become
Tarefa's: a provider that keeps prompts for a year means Tarefa's clients' words exist for a year, and
nothing in Tarefa's own code changes that.

The choice starts with a short list of questions written before anybody reads a sales page, so that
the answers are compared against Tarefa's needs rather than against each other. Tarefa's list, written
by the course, each a **MUST**, which rules a provider out, or a **SHOULD**, which counts in its
favour:

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

Each line is there for a reason somebody can state in one sentence:

| question | kind | why |
|---|---|---|
| `training` | MUST | text used to train a model can resurface in replies to other customers, and it is a purpose the clients never agreed to |
| `retention_days` | MUST, at most 30 | whatever the provider keeps can leak from the provider; less kept is less exposed, the argument of lesson 11 |
| `dpa` | MUST | under the LGPD the provider is an operator acting on Tarefa's instructions, and the agreement is where those instructions are written |
| `region` | MUST, one of three | data processed outside Brazil is an international transfer, which lesson 12 said needs a legal basis and safeguards |
| `incident_hours` | MUST, at most 48 | the ANPD's regulation on security incidents gives Tarefa three working days to notify; a provider that tells Tarefa on the fourth leaves no time |
| `subprocessors` | SHOULD | the provider's own suppliers see the data too, and Tarefa can only assess a list it can read |
| `audit` | SHOULD | an independent report, such as SOC 2 Type II or an ISO/IEC 27001 certificate, is somebody other than the provider saying the controls exist |
| `pinning` | SHOULD | a model that changes underneath the assistant changes every behaviour lessons 14 to 16 measured |
| `exit_deletion` | SHOULD | leaving a provider should not leave the clients' data behind |

The split between MUST and SHOULD is the decision that matters most. **A MUST is a line Tarefa will
not cross for a better price or a better model**, and writing it down before the comparison is what
keeps it from being renegotiated in the meeting where one provider is cheaper. Three to six MUSTs is
usual; a list where everything is a MUST rules out every provider and gets quietly ignored.
