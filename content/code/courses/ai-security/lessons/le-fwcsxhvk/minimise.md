---
title: Sending what the purpose needs, and a placeholder for the rest
version: 1
---

The principle of necessity is easy to agree with and hard to apply by hand: a developer building
the summary feature sends the whole ticket, because the whole ticket is what the code has, and
deciding field by field is somebody else's job. **The way to apply it is to write the purpose down
as a list of the fields it needs**, so that a field nobody listed is dropped without anybody having
to remember it. In `~/guard` that list is `purposes.json`:

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

`guard minimise` applies the purpose to the ticket. On the first run it writes nothing:

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
placeholders can be turned back into one that uses the names. The reply below **was written by the
course, not by a model**; it stands for what a provider would return, so that the last step has
something to work on:

```
ana@lab:~/guard$ cat data/reply-4471.txt
Summary: <NAME_1> paid R$ 1.200,00 for a logo due on 10 September and has received nothing. <NAME_2> says a health matter stopped the work and offers to deliver by Friday. <NAME_1> wants a refund and asked to be called on <PHONE_1>.

Draft reply to the client: Hello <NAME_1>, I'm sorry the logo for your bakery is late. <NAME_2> has offered to deliver it by Friday. If you would rather not wait, answer this message and we will start the refund today.
ana@lab:~/guard$ guard restore vault/TK-4471.json data/reply-4471.txt
Summary: Marcos Teixeira paid R$ 1.200,00 for a logo due on 10 September and has received nothing. Juliana Prado says a health matter stopped the work and offers to deliver by Friday. Marcos Teixeira wants a refund and asked to be called on +55 11 98765-4321.

Draft reply to the client: Hello Marcos Teixeira, I'm sorry the logo for your bakery is late. Juliana Prado has offered to deliver it by Friday. If you would rather not wait, answer this message and we will start the refund today.
```

The support agent reads the restored text, with the names and the phone number back in place, and
the provider never saw any of them. `guard restore` also reports a placeholder the vault does not
know, such as a `<NAME_3>` that a model invented, and exits with status 4 instead of passing it
through.

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
