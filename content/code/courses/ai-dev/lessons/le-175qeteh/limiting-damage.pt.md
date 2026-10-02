---
title: Diminuindo o pior caso
version: 1
---

Não dá para contar com o modelo para ignorar instruções nos dados. **Dá para contar com o host para
limitar o que qualquer instrução consegue**, porque o host é código. Três mudanças, cada uma das
quais teria impedido sozinha o reembolso da aula 11 seção 05.

## Dê a uma tarefa só as ferramentas de que ela precisa

Rascunhar uma resposta lê pedidos. Não paga ninguém:

```
ana@dev:~/shop$ git diff support.py
diff --git a/support.py b/support.py
index 4682826..2593d3e 100644
--- a/support.py
+++ b/support.py
@@ -1,4 +1,4 @@
-"""Draft a reply to a customer's email, with the shop's tools. Version 1: every tool, no checks."""
+"""Draft a reply to a customer's email. Drafting reads; it never changes anything."""
 import json
 import sys
 from pathlib import Path
@@ -26,7 +26,7 @@ def issue_refund(order_id, cents):
     return f"refunded {cents} cents on order {order_id}"
 
 
-FUNCTIONS = {"get_order": get_order, "issue_refund": issue_refund}
+FUNCTIONS = {"get_order": get_order}  # a draft needs to read, not to pay
 tools = [t for t in TOOLS if t["name"] in FUNCTIONS]
 messages = [{"role": "user", "content": Path(sys.argv[1]).read_text()}]
 for step in range(5):
```

```
ana@dev:~/shop$ rm data/refunds.log; python support.py data/emails/4.txt
draft: Hello Marta, your refund of 94.80 for order 1042 has been processed and will reach your card within five working days.
ana@dev:~/shop$ cat data/refunds.log
cat: data/refunds.log: No such file or directory
```

**Nenhum reembolso desta vez, porque não havia o que chamar.** O mesmo e-mail, o mesmo modelo, e o
`refunds.log` não existe. O modelo não consegue usar uma ferramenta que o host não ofereceu, e o
host oferece por tarefa, não por aplicação.

## Confira o que o rascunho afirma

O rascunho continua errado: ele diz à cliente que um reembolso foi processado. **A injeção saiu das
ferramentas e foi para o texto**, e texto que chega a um cliente também é uma ação. Uma verificação
que sabe o que a conversa fez consegue pegar isso:

```python
"""Hold a draft that promises what no tool result in the conversation did."""
import re
import sys

PROMISES = {"refund": re.compile(r"(?i)\brefund(ed)?\b.*\b(processed|issued|done|sent)\b"),
            "return label": re.compile(r"(?i)\blabel\b.*\b(sent|emailed)\b")}

draft = sys.stdin.read()
held = [what for what, pattern in PROMISES.items() if pattern.search(draft)]
print(f"HOLD for a person: the draft promises a {', '.join(held)}" if held else "ok to send")
```

```
ana@dev:~/shop$ python support.py data/emails/4.txt | sed -n 's/^draft: //p' | python check_draft.py
HOLD for a person: the draft promises a refund
```

**Segurado para uma pessoa.** A verificação não entende o rascunho; ela procura promessas que só um
resultado de ferramenta poderia sustentar, e nenhum resultado desta conversa reembolsou nada. Ela
erra para o lado de segurar, o que custa um minuto de uma pessoa e não custa nada à loja.

## Mantenha uma pessoa em tudo o que mexe com dinheiro

O host da aula 7 pedia aprovação antes do `issue_refund`. **Essa é a terceira defesa e a mais
forte**, porque a pessoa vê a chamada exata, 9480 centavos no pedido 1042, ao lado de um e-mail que
pediu para devolver uma caneca.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" aria-label=\"Três defesas entre uma instrução escondida num e-mail e o efeito dela. Primeiro, a tarefa recebe só as ferramentas de que precisa, então não há ferramenta de reembolso para chamar. Segundo, o rascunho é conferido atrás de promessas que nenhum resultado de ferramenta sustenta, e segurado para uma pessoa. Terceiro, toda chamada que mexe com dinheiro espera a aprovação de uma pessoa.\"><defs><marker id=\"dl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">uma instrução no e-mail</text><path d=\"M60 62 L60 100 L118 100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dl-ah)\"></path><rect x=\"120\" y=\"72\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ferramentas da tarefa</text><text x=\"210.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem ferramenta de reembolso</text><rect x=\"320\" y=\"72\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"410.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">conferir o rascunho</text><text x=\"410.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">promessa sem resultado: segura</text><rect x=\"520\" y=\"72\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma pessoa aprova</text><text x=\"610.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tudo o que mexe com dinheiro</text><path d=\"M302 100 L318 100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dl-ah)\"></path><path d=\"M502 100 L518 100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dl-ah)\"></path></svg>", "caption": "Nenhuma das três pede ao modelo que se comporte. Cada uma limita o que acontece quando ele não se comporta."}
```

## O que as três têm em comum

Nenhuma pede ao modelo que se comporte. **Cada uma limita o que acontece se ele não se comportar**:
uma ferramenta que não é oferecida, um rascunho que não é mandado, uma chamada que não é aprovada.
Elas valem seja qual for o texto do e-mail, que é a propriedade que uma instrução num prompt de
sistema não tem.
