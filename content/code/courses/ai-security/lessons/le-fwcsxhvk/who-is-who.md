---
title: One API call, read the way the LGPD reads it
version: 1
---

The intuition most developers bring is that a model provider is infrastructure, like a database or
a queue: a place data passes through on its way to an answer, and so nothing the privacy law has
much to say about. **The LGPD reads it the other way.** Sending a ticket to a provider's API is
*tratamento*, the law's word for anything done with personal data, and art. 5, X lists
transferring and communicating data among the operations it covers. It is done by another company,
on that company's computers, and usually outside Brazil.

This lesson's ticket is the kind of thing a support team would like a model to summarise. Like
everything in `~/guard`, it was written by the course, and the people in it are invented:

```
ana@lab:~/guard$ cat data/ticket-4471.json
{
 "ticket": "TK-4471",
 "opened": "2026-09-18",
 "client": {
  "name": "Marcos Teixeira",
  "cpf": "529.982.247-25",
  "email": "marcos.teixeira@example.com.br",
  "phone": "+55 11 98765-4321",
  "birth_date": "1984-02-11",
  "address": "Rua Augusta 1500, ap 32, São Paulo"
 },
 "freelancer": {
  "name": "Juliana Prado",
  "cpf": "111.444.777-35",
  "pix_key": "juliana.prado@example.com"
 },
 "job": {
  "id": "4471",
  "title": "Logo for a bakery",
  "price_cents": 120000,
  "due": "2026-09-10"
 },
 "messages": [
  {
   "from": "client",
   "text": "Juliana, the logo was due on 10 September and I have nothing. I paid R$ 1.200,00."
  },
  {
   "from": "freelancer",
   "text": "Sorry, I was in hospital for a week with a kidney infection and couldn't work. I can deliver by Friday."
  },
  {
   "from": "client",
   "text": "I don't care, I want my money back. Call me on +55 11 98765-4321."
  }
 ]
}
```

Two people, two CPFs, a phone number, an address, a birth date, a Pix key and a hospital stay. The
purpose is a summary for the support agent and a draft reply to the client, and the question the
rest of this lesson answers is how much of that the summary needs.

## The roles

The law sorts the parties to this call before it asks anything else:

| | who | what the law expects of them |
|---|---|---|
| **titular** (data subject) | Marcos and Juliana | rights over their data, art. 18 |
| **controlador** (controller) | Tarefa, which decides why and how the ticket is processed | the legal basis, the purpose, the answers to the data subjects |
| **operador** (processor) | the model provider, processing on Tarefa's behalf | to process only according to the controller's instructions, art. 39 |

The table holds only while the provider stays inside the processor's role. **A provider that uses
the prompts for a purpose of its own**, such as training its models, is deciding something about
the data that Tarefa did not instruct, and deciding the purpose is what a controller does. Whether that happens is written in the provider's terms, and for many providers in a setting on the account. It has to be read before the first ticket is sent, because Tarefa's privacy notice has to tell Marcos and Juliana who receives their data and why.

## The four questions, applied to this call

**Is it personal data?** Art. 5, I covers information about a person who is identified or
*identifiable*. The CPFs and the names are obvious. So are the messages: *"Call me on +55 11
98765-4321"* identifies its writer as well as a name does.

**On what legal basis?** Art. 7 lists ten. For a dispute between two parties to Tarefa's own
service, the performance of a contract (art. 7, V) is the usual candidate, and legitimate interest
(art. 7, IX) another; whichever is chosen has to be recorded. A basis covers a purpose, not a
feature: it does not stretch by itself to a new use of the same data.

**Is each field necessary for that purpose?** Art. 6 lists the principles, and two of them decide
this lesson: *finalidade*, processing for a specific purpose that was stated, and *necessidade*,
processing limited to the minimum that purpose requires. The summary of a late logo does not need
Marcos's birth date. The next section turns that principle into a file.

**Does it leave Brazil?** If the provider runs the model abroad, sending the ticket is an
international transfer, and art. 33 allows one only in the cases it lists: a country the ANPD
recognises as giving adequate protection, or guarantees the controller provides, of which the
common one is a contract with the ANPD's standard clauses, published in Resolution CD/ANPD nº 19
of 2024. Where the model runs is therefore part of choosing a provider, along with its price and
its quality.

One more question is on the list, and the ticket answers yes to it: **is any of it sensitive?**
Juliana's message mentions a hospital and an infection, and health data is sensitive under art. 5,
II. That changes which legal bases are available at all, and it has its own section in this lesson.

*This lesson reads the law as it stood in 2026. The LGPD and the ANPD's regulations change on a legislature's schedule. A decision about real data is made with the current text, and with the company's encarregado, the person the law requires the controller to name for exactly these questions (art. 41).*
