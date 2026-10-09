---
title: A tela também é um controle de segurança
version: 1
---

Toda defesa até aqui rodou nos servidores da Tarefa. O cliente nunca viu o `guard gate` nem o
`memory.py`; viu uma janela de chat, uma resposta, uma recusa, uma confirmação. **O que essas telas
dizem decide no que o cliente acredita e o que ele faz em seguida**, e um cliente que acredita na coisa
errada é uma falha do sistema tão real quanto uma chave vazada: uma resposta tomada como promessa da
equipe da Tarefa, uma recusa tentada de novo quarenta vezes, um reembolso confirmado sem ser lido.

Então as telas também ganham regras, escritas e conferidas como todo o resto. O assistente da Tarefa
tem seis telas, cada uma com seu texto e as ações que oferece; o curso as escreveu como seria escrito
um primeiro rascunho. Cole:

```sh
cat > ~/guard/data/ui-copy.json <<'EOF'
[
 {"id": "chat-welcome", "kind": "chat",
  "text": "Hi! I'm here to help with your jobs, payments and account.",
  "actions": ["talk-to-a-person"]},
 {"id": "reply", "kind": "reply",
  "text": "{reply}",
  "actions": ["copy"]},
 {"id": "refusal-budget", "kind": "refusal",
  "text": "Something went wrong. Please try again.",
  "actions": ["retry"]},
 {"id": "refusal-scope", "kind": "refusal",
  "text": "I can only help with jobs, payments and accounts on Tarefa. For anything else, a person on our team can help: they reply within one business day.",
  "actions": ["talk-to-a-person"]},
 {"id": "confirm-refund", "kind": "confirm", "tool": "issue_refund",
  "text": "The assistant wants to issue a refund. Allow?",
  "shows": [],
  "actions": ["allow", "cancel"]},
 {"id": "memory-panel", "kind": "memory",
  "text": "What the assistant remembers about you, and until when.",
  "actions": ["delete-one", "delete-all"]}
]
EOF
```

O verificador sabe o que cada tipo de tela deve ao cliente. Salve-o como `~/guard/tools/uxcheck.py`:

```python
# uxcheck.py: what the assistant's screens say, against rules a person sets.
#
#   guard uxcheck FILE
#
# FILE lists every screen of the assistant with its text and the actions it
# offers. Each kind of screen has rules of its own:
#
#   chat     says the client is talking to an automated assistant, and
#            offers a person
#   reply    can be reported
#   refusal  says why, names the next step, and offers a person; never only
#            "try again", which turns a limit into a loop
#   confirm  shows every argument of the tool call, as lesson 10 asked
#   memory   lets the client delete what is remembered
#
# The arguments a confirmation must show, per tool, are TOOL_ARGS below; they
# are the arguments of the proposals in lesson 10. The exit status is 1 while
# any screen breaks a rule.
import argparse
import json
import os
import re

AUTOMATED = re.compile(r"\b(automated|AI|artificial intelligence|language model)\b", re.I)
WHY = re.compile(r"\b(can only|cannot|because|limit|today)\b", re.I)
TOOL_ARGS = {"issue_refund": ["account", "job", "cents"]}

p = argparse.ArgumentParser(prog="guard uxcheck")
p.add_argument("file")
a = p.parse_args()
with open(a.file, encoding="utf-8") as f:
    screens = json.load(f)


def problems(s):
    out = []
    acts = s.get("actions", [])
    if s["kind"] == "chat":
        if not AUTOMATED.search(s["text"]):
            out.append("does not say the assistant is automated")
        if "talk-to-a-person" not in acts:
            out.append("offers no person")
    if s["kind"] == "reply" and "report" not in acts:
        out.append("a reply cannot be reported")
    if s["kind"] == "refusal":
        if not WHY.search(s["text"]):
            out.append("does not say why")
        if "talk-to-a-person" not in acts:
            out.append("offers no person")
        if acts == ["retry"]:
            out.append("only offers to try again")
    if s["kind"] == "confirm":
        missing = [x for x in TOOL_ARGS[s["tool"]] if x not in s.get("shows", [])]
        if missing:
            out.append("does not show " + ", ".join(missing))
    if s["kind"] == "memory" and not {"delete-one", "delete-all"} & set(acts):
        out.append("nothing can be deleted")
    return out


bad = 0
for s in screens:
    found = problems(s)
    bad += bool(found)
    print("%-15s %-8s %s" % (s["id"], s["kind"], "ok" if not found else found[0]))
    for f in found[1:]:
        print("%-15s %-8s %s" % ("", "", f))
print("%d screens, %d breaking a rule" % (len(screens), bad))
raise SystemExit(1 if bad else 0)
```

```
ana@lab:~/guard$ guard uxcheck data/ui-copy.json; echo "exit status $?"
chat-welcome    chat     does not say the assistant is automated
reply           reply    a reply cannot be reported
refusal-budget  refusal  does not say why
                         offers no person
                         only offers to try again
refusal-scope   refusal  ok
confirm-refund  confirm  does not show account, job, cents
memory-panel    memory   ok
6 screens, 4 breaking a rule
exit status 1
```

Quatro de seis quebram uma regra. Esta seção trata das duas primeiras; a próxima trata das outras
duas.

## Dizer que é um modelo

A `chat-welcome` cumprimenta o cliente com simpatia e nunca diz o que está respondendo. **Um cliente
que não sabe que fala com um modelo lê as respostas dele como palavra da Tarefa**: um preço que ele
inventa vira orçamento, uma data que ele chuta vira promessa, e o cliente age sobre as duas. A aula 2
mediu com que frequência um modelo afirma o que ninguém escreveu. As boas-vindas são onde o cliente
aprende a conferir, e isso custa uma frase: *o assistente automatizado da Tarefa*. A regra procura as
palavras que dizem isso e recusa umas boas-vindas sem elas.

A mesma tela oferece uma pessoa, e continua oferecendo. Um assistente automatizado sem saída para
além dele é uma parede, e um cliente que precisa de uma pessoa e não a encontra tenta fazer o
assistente fazer o que uma pessoa faria, que é exatamente o uso que ninguém projetou.

## Toda resposta pode ser denunciada

A `reply` oferece copiar o texto e nada mais. **O cliente é quem vê todas as respostas**, inclusive as
que nenhuma verificação pegou: a fila errada da aula 14, o erro confiante do `q1` da aula 15. Um botão
de denúncia em toda resposta é o monitoramento mais barato que existe, e a aula 22 parte dele. Não
custa nada mostrá-lo e custa muito pouco ler o que chega, desde que cada denúncia venha com o que a
aula 20 registrou da chamada, para que alguém encontre a resposta, a versão do prompt e o modelo, e não
uma captura de tela e um palpite.
