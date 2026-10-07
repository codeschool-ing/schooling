---
title: Enviar o que a finalidade precisa, e um marcador para o resto
version: 2
---

O princípio da necessidade é fácil de aceitar e difícil de aplicar à mão: quem constrói o recurso de
resumo envia o ticket inteiro, porque o ticket inteiro é o que o código tem, e decidir campo a campo
é trabalho de outra pessoa. **O jeito de aplicá-lo é escrever a finalidade como a lista dos campos
de que ela precisa**, para que um campo que ninguém listou fique de fora sem que alguém precise
lembrar dele. Nesta aula essa lista é o `data/purposes.json`. Cole-o:

```sh
cat > ~/guard/data/purposes.json <<'EOF'
{
 "summarise-dispute": {
  "what": "a summary of the dispute for the support agent, and a draft reply to the client",
  "needs": [
   "ticket",
   "job.title",
   "job.price_cents",
   "job.due",
   "messages"
  ],
  "pseudonymise": [
   "client.name",
   "freelancer.name"
  ]
 }
}
EOF
```

```
ana@lab:~/guard$ cat data/purposes.json
{
 "summarise-dispute": {
  "what": "a summary of the dispute for the support agent, and a draft reply to the client",
  "needs": [
   "ticket",
   "job.title",
   "job.price_cents",
   "job.due",
   "messages"
  ],
  "pseudonymise": [
   "client.name",
   "freelancer.name"
  ]
 }
}
```

`needs` é o que o resumo precisa ler. `pseudonymise` é aquilo sobre o que ele precisa *falar* sem
conhecer: o resumo tem de dizer que o cliente e a freelancer discordam, e não precisa dos nomes para
dizer isso.

## A ferramenta recusa primeiro

O `guard minimise` aplica a finalidade ao ticket. Ele usa o `detect.py` da aula 5 para o texto livre,
e uma lista de palavras própria para dados sensíveis, que é o assunto da próxima seção. Salve-o como
`~/guard/tools/minimise.py`:

```python
# minimise.py: what leaves Tarefa when a ticket is sent to a third-party model.
#
#   guard minimise TICKET --purpose NAME [--sensitive remove]
#
# A purpose in data/purposes.json names the fields it needs; everything else in
# the ticket is dropped. The names it needs to talk ABOUT, but not to know,
# become placeholders like <NAME_1>, and the free text goes through detect.py
# with each match replaced the same way. The placeholders and what they stand
# for go to vault/, which never leaves the machine; what the provider gets
# goes to outbox/. Sensitive data in the text stops the run (exit status 3)
# unless --sensitive remove takes those sentences out.
#
# THE SENSITIVE-DATA CHECK IS A WORD LIST, below, and as crude as that sounds:
# it stops the obvious case and makes somebody decide. restore.py and
# sensitive.py import from here.
import argparse
import json
import os
import re

from detect import find

SENSITIVE = {
    "health": ["hospital", "infection", "diagnos", "surgery", "pregnan",
               "depress", "medication", "therapy", "cancer", "hiv"],
    "religion": ["church", "mosque", "synagogue", "terreiro", "religio"],
    "union": ["trade union", "sindicato"],
}
SENTENCE = re.compile(r"[^.!?]+[.!?]?\s*")


def sensitive_terms(text):
    low = text.lower()
    return {cat: [w for w in words if w in low]
            for cat, words in SENSITIVE.items() if any(w in low for w in words)}


def get(obj, path):
    for part in path.split("."):
        obj = obj[part]
    return obj


def put(obj, path, value):
    parts = path.split(".")
    for part in parts[:-1]:
        obj = obj.setdefault(part, {})
    obj[parts[-1]] = value


def leaves(obj, prefix=""):
    """Every scalar field as a dotted path, so that a dropped field can be named."""
    if isinstance(obj, dict):
        for k, v in obj.items():
            yield from leaves(v, prefix + k + ".")
    else:
        yield prefix[:-1]


class Vault:
    def __init__(self):
        self.by_value, self.by_token, self.count = {}, {}, {}

    def token(self, kind, value):
        if value not in self.by_value:
            n = self.count[kind] = self.count.get(kind, 0) + 1
            self.by_value[value] = "<%s_%d>" % (kind.upper(), n)
            self.by_token[self.by_value[value]] = value
        return self.by_value[value]


def minimise(ticket, purpose, remove_sensitive):
    """(outbox, vault, report); outbox is None when sensitive data stopped it."""
    vault, out, report = Vault(), {}, []
    needs, renames = purpose["needs"], purpose.get("pseudonymise", [])
    for p in needs:
        put(out, p, json.loads(json.dumps(get(ticket, p))))
    names = {}
    for p in renames:
        names[get(ticket, p)] = vault.token("name", get(ticket, p))
        put(out, p, names[get(ticket, p)])
    report.append(("kept", ", ".join(needs)))
    report.append(("dropped", ", ".join(p for p in leaves(ticket)
                                        if not any(p == n or p.startswith(n + ".")
                                                   for n in needs + renames))))
    report.append(("renamed", ", ".join("%s -> %s" % (p, vault.by_value[get(ticket, p)])
                                         for p in renames)))
    replaced, held = {}, []
    for i, msg in enumerate(out.get("messages", [])):
        text = msg["text"]
        for value, tok in names.items():
            for part in {value, value.split()[0]}:
                if part in text:
                    replaced[tok] = replaced.get(tok, 0) + text.count(part)
                    text = text.replace(part, tok)
        pieces, at = [], 0
        for kind, a, b, ok in find(text):
            if ok:
                tok = vault.token(kind, text[a:b])
                replaced[tok] = replaced.get(tok, 0) + 1
                pieces += [text[at:a], tok]
                at = b
        text = "".join(pieces) + text[at:]
        found = sensitive_terms(text)
        if found:
            where = "messages[%d]" % i
            what = "; ".join("%s (%s)" % (c, ", ".join(w)) for c, w in found.items())
            if remove_sensitive:
                kept, gone = [], 0
                for s in SENTENCE.findall(text):
                    cats = sensitive_terms(s)
                    if cats:
                        gone += 1
                        kept.append("[removed: a %s matter]%s" % (" and ".join(cats),
                                                                   " " if s.endswith(" ") else ""))
                    else:
                        kept.append(s)
                text = "".join(kept)
                report.append(("sensitive", "%s: %s  removed %d sentence(s)" % (where, what, gone)))
            else:
                report.append(("sensitive", "%s: %s  HOLD" % (where, what)))
                held.append(where)
        msg["text"] = text
    report.append(("in text", ", ".join("%s x%d" % (t, n) for t, n in replaced.items())))
    return (None if held else out), vault, report


if __name__ == "__main__":
    p = argparse.ArgumentParser(prog="guard minimise")
    p.add_argument("ticket")
    p.add_argument("--purpose", required=True)
    p.add_argument("--sensitive", choices=["hold", "remove"], default="hold")
    a = p.parse_args()
    home = os.path.expanduser("~/guard/")
    with open(a.ticket, encoding="utf-8") as f:
        raw = f.read()
    ticket = json.loads(raw)
    with open(home + "data/purposes.json") as f:
        purpose = json.load(f)[a.purpose]
    out, vault, report = minimise(ticket, purpose, a.sensitive == "remove")
    print("purpose    %s: %s" % (a.purpose, purpose["what"]))
    for label, text in report:
        print("%-10s %s" % (label, text))
    if out is None:
        print("NOTHING WRITTEN: sensitive data in the text. Remove it with --sensitive remove, "
              "or record the legal basis that allows sending it (LGPD art. 11) and change the purpose.")
        raise SystemExit(3)
    body = json.dumps(out, ensure_ascii=False, indent=1) + "\n"
    name = ticket["ticket"] + ".json"
    for folder, data in (("outbox", body),
                         ("vault", json.dumps(vault.by_token, ensure_ascii=False, indent=1) + "\n")):
        os.makedirs(home + folder, exist_ok=True)
        with open(home + folder + "/" + name, "w", encoding="utf-8") as f:
            f.write(data)
    print("%-10s %d -> %d" % ("bytes", len(raw.encode()), len(body.encode())))
    print("%-10s outbox/%s (to the provider), vault/%s (stays here)" % ("wrote", name, name))
```

Na primeira execução ele não grava nada:

```
ana@lab:~/guard$ guard minimise data/ticket-4471.json --purpose summarise-dispute; echo "exit $?"
purpose    summarise-dispute: a summary of the dispute for the support agent, and a draft reply to the client
kept       ticket, job.title, job.price_cents, job.due, messages
dropped    opened, client.cpf, client.email, client.phone, client.birth_date, client.address, freelancer.cpf, freelancer.pix_key, job.id
renamed    client.name -> <NAME_1>, freelancer.name -> <NAME_2>
sensitive  messages[1]: health (hospital, infection)  HOLD
in text    <NAME_2> x1, <PHONE_1> x1
NOTHING WRITTEN: sensitive data in the text. Remove it with --sensitive remove, or record the legal basis that allows sending it (LGPD art. 11) and change the purpose.
exit 3
ana@lab:~/guard$ ls outbox vault 2>&1
ls: cannot access 'outbox': No such file or directory
ls: cannot access 'vault': No such file or directory
```

Leia o relatório de cima para baixo. `kept` é a lista da finalidade. `dropped` é todo o resto, nove
campos nomeados um a um: os dois CPFs, o e-mail, o telefone, a data de nascimento e o endereço do
cliente, a chave Pix, o id do trabalho e a data de abertura do ticket. `renamed` trocou os dois nomes
por marcadores. `in text` é o texto livre: o cliente escreveu o primeiro nome da Juliana numa
mensagem e o próprio telefone em outra, e os dois também viraram marcadores.

**Os nomes nas mensagens puderam ser achados porque o ticket diz quais são.** A aula 11 mostrou que
nenhum padrão acha um nome em texto livre. Aqui os campos estruturados trazem `Marcos Teixeira` e
`Juliana Prado`, então a ferramenta sabe quais palavras procurar, primeiros nomes inclusive. Uma
terceira pessoa citada só numa mensagem, um advogado ou um parente, passaria, e esse limite pertence
à mesma frase que o resultado.

Depois vem a linha que o parou: `sensitive messages[1]: health (hospital, infection) HOLD`. O status
de saída é 3, e nem `outbox/` nem `vault/` existem. A próxima seção trata dessa linha. Aqui, use a
opção que ela nomeia:

```
ana@lab:~/guard$ guard minimise data/ticket-4471.json --purpose summarise-dispute --sensitive remove
purpose    summarise-dispute: a summary of the dispute for the support agent, and a draft reply to the client
kept       ticket, job.title, job.price_cents, job.due, messages
dropped    opened, client.cpf, client.email, client.phone, client.birth_date, client.address, freelancer.cpf, freelancer.pix_key, job.id
renamed    client.name -> <NAME_1>, freelancer.name -> <NAME_2>
sensitive  messages[1]: health (hospital, infection)  removed 1 sentence(s)
in text    <NAME_2> x1, <PHONE_1> x1
bytes      909 -> 542
wrote      outbox/TK-4471.json (to the provider), vault/TK-4471.json (stays here)
ana@lab:~/guard$ cat outbox/TK-4471.json
{
 "ticket": "TK-4471",
 "job": {
  "title": "Logo for a bakery",
  "price_cents": 120000,
  "due": "2026-09-10"
 },
 "messages": [
  {
   "from": "client",
   "text": "<NAME_2>, the logo was due on 10 September and I have nothing. I paid R$ 1.200,00."
  },
  {
   "from": "freelancer",
   "text": "[removed: a health matter] I can deliver by Friday."
  },
  {
   "from": "client",
   "text": "I don't care, I want my money back. Call me on <PHONE_1>."
  }
 ],
 "client": {
  "name": "<NAME_1>"
 },
 "freelancer": {
  "name": "<NAME_2>"
 }
}
```

909 bytes viraram 542, e o que foi cortado é o que identificava pessoas. A ordem das chaves mudou,
porque a ferramenta monta a caixa de saída a partir da lista da finalidade; um modelo que lê JSON não
é afetado por isso.

## Os marcadores e o cofre

O segundo arquivo fica na máquina da Tarefa:

```
ana@lab:~/guard$ cat vault/TK-4471.json
{
 "<NAME_1>": "Marcos Teixeira",
 "<NAME_2>": "Juliana Prado",
 "<PHONE_1>": "+55 11 98765-4321"
}
```

O fornecedor recebe `<NAME_1>`; a Tarefa guarda o que `<NAME_1>` significa. Uma resposta que usa os
marcadores pode ser transformada numa que usa os nomes. Dois programas fazem a ida e a volta: o
`summarise.py` manda o outbox, e só o outbox, ao `llama3.2:3b` com a finalidade e a instrução de manter
cada marcador como está, e o `restore.py` devolve os nomes:

```python
# summarise.py: send a minimised ticket to the model for its purpose, and print the reply.
#
#   guard summarise OUTBOX_FILE --purpose NAME
#
# The model gets only the outbox, never the vault, and is told to keep every
# placeholder exactly as written so that `guard restore` can put the names
# back. Its reply is printed as it came.
import argparse
import json
import os

from ask import ask

p = argparse.ArgumentParser(prog="guard summarise")
p.add_argument("outbox")
p.add_argument("--purpose", required=True)
a = p.parse_args()

with open(os.path.expanduser("~/guard/data/purposes.json")) as f:
    purpose = json.load(f)[a.purpose]
with open(a.outbox, encoding="utf-8") as f:
    ticket = f.read()

SYSTEM = """You help Tarefa's support team. Write %s. Start the summary with
"Summary:" and the reply with "Draft reply to the client:". The ticket uses
placeholders such as <NAME_1> and <PHONE_1> in place of personal data: keep
every placeholder exactly as written, and never guess what it stands for.""" % purpose["what"]
print(ask(ticket, system=SYSTEM))
```

```python
# restore.py: a reply with every placeholder put back from the vault.
#
#   guard restore VAULT REPLY
#
# A placeholder the vault has never heard of is left as it was and reported,
# with exit status 4: a model can invent <NAME_3>, and filling in nothing
# would hide that it did.
import json
import re
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    vault = json.load(f)
with open(sys.argv[2], encoding="utf-8") as f:
    reply = f.read()
unknown = []


def back(m):
    if m.group(0) in vault:
        return vault[m.group(0)]
    unknown.append(m.group(0))
    return m.group(0)


sys.stdout.write(re.sub(r"<[A-Z]+_\d+>", back, reply))
if unknown:
    print("UNKNOWN placeholder(s), left as they were: " + ", ".join(unknown))
    sys.exit(4)
```

```
ana@lab:~/guard$ guard summarise outbox/TK-4471.json --purpose summarise-dispute > reply-4471.txt
ana@lab:~/guard$ cat reply-4471.txt
Summary:
The client, <NAME_1>, has expressed dissatisfaction with the logo design for their bakery, which was due on September 10, 2026. The client claims to have paid R$ 1,200.00 for the service, but has not received the logo. The freelancer, <NAME_2>, initially mentioned a health issue that may have caused a delay, but now claims to be able to deliver by Friday. The client is requesting a refund and has asked to be contacted on <PHONE_1>.

Draft reply to the client:
"Dear <NAME_1>, 

Thank you for reaching out to us about the issue with your logo design. We apologize for the delay and any inconvenience this has caused. We understand that you paid R$ 1,200.00 for the service, and we are willing to work with you to find a solution.

Regarding the freelancer's statement, we will look into the matter and provide an update as soon as possible. In the meantime, we would like to offer you a refund for the service, as per your request. Please let us know if this is acceptable to you, and we will proceed with the refund process.

If you would like to discuss this further or have any questions, please don't hesitate to contact us. We are here to help.

Best regards, [Your Name]"
ana@lab:~/guard$ guard restore vault/TK-4471.json reply-4471.txt; echo "exit $?"
Summary:
The client, Marcos Teixeira, has expressed dissatisfaction with the logo design for their bakery, which was due on September 10, 2026. The client claims to have paid R$ 1,200.00 for the service, but has not received the logo. The freelancer, Juliana Prado, initially mentioned a health issue that may have caused a delay, but now claims to be able to deliver by Friday. The client is requesting a refund and has asked to be contacted on +55 11 98765-4321.

Draft reply to the client:
"Dear Marcos Teixeira, 

Thank you for reaching out to us about the issue with your logo design. We apologize for the delay and any inconvenience this has caused. We understand that you paid R$ 1,200.00 for the service, and we are willing to work with you to find a solution.

Regarding the freelancer's statement, we will look into the matter and provide an update as soon as possible. In the meantime, we would like to offer you a refund for the service, as per your request. Please let us know if this is acceptable to you, and we will proceed with the refund process.

If you would like to discuss this further or have any questions, please don't hesitate to contact us. We are here to help.

Best regards, [Your Name]"
exit 0
```

Os marcadores fizeram a ida e a volta: o modelo nunca viu um nome nem um número, e o texto restaurado
tem os dois de volta no lugar. O `guard restore` também avisa de um marcador que o cofre não conhece,
como um `<NAME_3>` que um modelo inventou, e sai com status 4 em vez de deixá-lo passar. O
`[Your Name]` no fim não é um dos marcadores dele, e passa como veio.

Leia a minuta de resposta de novo, porém. **Ela oferece um reembolso ao cliente e diz que a Tarefa vai
seguir com ele.** Ninguém na Tarefa decidiu isso. A finalidade pedia uma minuta, e o modelo escreveu uma
promessa, o mesmo tipo de promessa que a aula 2 mostrou um tribunal cobrando de uma companhia aérea. É
por isso que a finalidade diz *draft*, e por isso que uma pessoa a envia, e não o modelo. A
minimização protege o que o fornecedor vê; não faz nada pelo que o modelo escreve. A sua resposta pode
vir com outras palavras e errar de outro jeito, ou não errar.

## Pseudonimizado não é anônimo

É tentador chamar a caixa de saída de anonimizada, e a lei traça a linha exatamente onde essa
tentação erra. **Dado anonimizado não é dado pessoal** pelo art. 12, mas só enquanto a anonimização
não puder ser revertida com esforço razoável. O cofre reverte esta num único comando, então para a
Tarefa a caixa de saída é *pseudonimizada*, o termo que o art. 13, §4 define: dado que não pode mais
ser associado a uma pessoa sem informação adicional que o controlador guarda separada. Dado
pseudonimizado continua dado pessoal, com todas as obrigações que vêm junto.

Mesmo assim, o que a técnica compra é real. O fornecedor não tem CPF, endereço nem nome, então um
vazamento no fornecedor, ou um fornecedor que guarda os prompts mais do que devia, expõe muito menos.
E o que sobra ainda pode identificar alguém: `TK-4471`, um logo para uma padaria, R$ 1.200,00, 10 de
setembro. Ninguém fora da Tarefa consegue usar o número do ticket, mas numa cidade pequena uma padaria
com o logo atrasado pode ser uma padaria só. Minimizar baixa o risco; não chega a zero, e o cofre
precisa ser apagado quando a retenção do próprio ticket acaba, porque ele é a chave de tudo o que a
caixa de saída escondeu.
