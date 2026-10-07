---
title: Sending what the purpose needs, and a placeholder for the rest
version: 2
---

The principle of necessity is easy to agree with and hard to apply by hand: a developer building
the summary feature sends the whole ticket, because the whole ticket is what the code has, and
deciding field by field is somebody else's job. **The way to apply it is to write the purpose down
as a list of the fields it needs**, so that a field nobody listed is dropped without anybody having
to remember it. For this lesson that list is `data/purposes.json`. Paste it:

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

`needs` is what the summary has to read. `pseudonymise` is what it has to talk *about* without
knowing: the summary has to say that the client and the freelancer disagree, and it does not need
their names to say it.

## The tool refuses first

`guard minimise` applies the purpose to the ticket. It uses `detect.py` from lesson 5 for the free
text, and a word list of its own for sensitive data, which the next section is about. Save it as
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

On the first run it writes nothing:

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

Read the report from the top. `kept` is the purpose's list. `dropped` is everything else, nine
fields named one by one: both CPFs, the client's e-mail, phone, birth date and address, the Pix key,
the job's id and the date the ticket was opened. `renamed` replaced the two names with placeholders.
`in text` is the free text: the client wrote Juliana's first name in a message and their own phone
number in another, and both became placeholders as well.

**The names in the messages could be found because the ticket says what they are.** Lesson 11 showed
that no pattern finds a name in free text. Here the structured fields hold `Marcos Teixeira` and
`Juliana Prado`, so the tool knows which words to look for, first names included. A third person
mentioned only in a message, a lawyer or a relative, would get through, and that limit belongs in
the same sentence as the result.

Then the line that stopped it: `sensitive messages[1]: health (hospital, infection) HOLD`. The exit
status is 3 and neither `outbox/` nor `vault/` exists. The next section is about that line. Here,
take the option it names:

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

909 bytes became 542, and what was cut is what identified people. The order of the keys changed,
because the tool builds the outbox from the purpose's list; a model reading JSON is not affected by
that.

## The placeholders and the vault

The second file stays on Tarefa's machine:

```
ana@lab:~/guard$ cat vault/TK-4471.json
{
 "<NAME_1>": "Marcos Teixeira",
 "<NAME_2>": "Juliana Prado",
 "<PHONE_1>": "+55 11 98765-4321"
}
```

The provider receives `<NAME_1>`; Tarefa holds what `<NAME_1>` means. A reply that uses the
placeholders can be turned back into one that uses the names. Two programs do the round trip:
`summarise.py` sends the outbox, and only the outbox, to `llama3.2:3b` with the purpose and an
instruction to keep every placeholder as written, and `restore.py` puts the names back:

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

The placeholders made the round trip: the model never saw a name or a number, and the restored text has
both back in place. `guard restore` also reports a placeholder the vault does not know, such as a
`<NAME_3>` a model invented, and exits with status 4 instead of passing it through. `[Your Name]` at the
end is not one of its placeholders, and goes through as it came.

Read the draft reply again, though. **It offers the client a refund and says Tarefa will proceed with
it.** Nobody at Tarefa decided that. The purpose asked for a draft, and the model wrote a promise, the
same kind of promise lesson 2 showed a tribunal holding an airline to. That is why the purpose says
*draft*, and why a person sends it rather than the model. Minimisation protects what the provider
sees; it does nothing about what the model writes. Your reply may be worded differently and go wrong
in a different way, or not at all.

## Pseudonymous is not anonymous

It is tempting to call the outbox anonymised, and the law draws the line precisely where that
temptation goes wrong. **Anonymised data is not personal data** under art. 12, but only while the
anonymisation cannot be reversed with reasonable effort. The vault reverses this one in a single
command, so for Tarefa the outbox is *pseudonymised*, the term art. 13, §4 defines: data that can
no longer be tied to a person without additional information that the controller keeps separately.
Pseudonymised data is still personal data, with every obligation that comes with it.

What the technique buys is real all the same. The provider holds no CPF, no address and no name,
so a leak at the provider, or a provider that keeps the prompts longer than it should, exposes far
less. And what is left can still identify somebody: `TK-4471`, a logo for a bakery, R$ 1.200,00,
10 September. Nothing outside Tarefa can use the ticket number, but in a small town a bakery whose
logo is late may be one bakery. Minimisation lowers the risk; it does not reach zero, and the vault
has to be deleted when the ticket's own retention ends, because it is the key to everything the
outbox hid.
