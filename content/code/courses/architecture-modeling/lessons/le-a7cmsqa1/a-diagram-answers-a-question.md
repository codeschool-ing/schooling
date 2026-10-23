---
title: A diagram answers a question
version: 1
---

**A diagram is worth drawing when it answers a question somebody has, for a reader who will act on
the answer.** Name the question and the reader first, and most of the decisions about what to draw
make themselves.

The common failure is the opposite order: the drawing comes first, because a document is expected
to have one, and the question is never asked. What comes out is a picture of everything, which
answers nothing in particular.

## Carcará's picture on the wall

On Bento's first day, Rui pointed at a printout taped beside the Platform team's desks: "That's the
architecture." It looked like the left half of this figure. There were the logos of the cloud
provider, the database and the message broker, a phone, a bus, a cloud shape, and arrows between
most of them. None of the arrows had a word on it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l01-decorated\" aria-label=\"Two drawings of Carcará. On the left, the printout on the wall: eight boxes named after products, such as PostgreSQL, Redis, RabbitMQ, the cloud provider and a phone, joined by nine arrows with no words on them. On the right, the diagram drawn to answer one question, which service takes the money when somebody buys a ticket: a passenger, the passenger app, the ticketing API, the booking database and the payment gateway, each with its type, joined by four labelled lines.\"><defs><marker id=\"l01-decorated-am-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l01-decorated-am-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the printout on the wall</text><text x=\"545.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">drawn for one question</text><path d=\"M360.0 30.0 L360.0 315.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"28.0\" y=\"55.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Phone</text><rect x=\"158.0\" y=\"45.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Cloud</text><rect x=\"258.0\" y=\"95.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">PostgreSQL</text><rect x=\"48.0\" y=\"155.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Redis</text><rect x=\"178.0\" y=\"145.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">RabbitMQ</text><rect x=\"258.0\" y=\"215.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Payments</text><rect x=\"38.0\" y=\"255.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Bus</text><rect x=\"158.0\" y=\"265.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">PostgreSQL</text><path d=\"M112.0 66.8 L154.6 63.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-ah-paper-dim)\"></path><path d=\"M230.0 75.0 L267.6 93.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-ah-paper-dim)\"></path><path d=\"M203.0 75.0 L216.8 143.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-ah-paper-dim)\"></path><path d=\"M178.0 163.2 L135.4 166.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-ah-paper-dim)\"></path><path d=\"M87.0 155.0 L73.2 86.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-ah-paper-dim)\"></path><path d=\"M237.1 175.0 L281.5 213.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-ah-paper-dim)\"></path><path d=\"M300.0 215.0 L300.0 126.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-ah-paper-dim)\"></path><path d=\"M99.1 255.0 L199.4 176.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-ah-paper-dim)\"></path><path d=\"M217.5 175.0 L202.7 263.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-ah-paper-dim)\"></path><circle cx=\"440.0\" cy=\"56.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><rect x=\"394.0\" y=\"70.0\" width=\"92.0\" height=\"44.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Passenger</text><rect x=\"545.0\" y=\"52.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"68.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Passenger app</text><text x=\"620.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[web and mobile]</text><rect x=\"545.0\" y=\"152.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"168.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Ticketing API</text><text x=\"620.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Kotlin service]</text><rect x=\"375.0\" y=\"247.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"263.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Booking database</text><text x=\"450.0\" y=\"276.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[PostgreSQL]</text><rect x=\"545.0\" y=\"262.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"620.0\" y=\"278.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Payment gateway</text><text x=\"620.0\" y=\"291.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[external system]</text><path d=\"M486.0 80.0 L543.0 76.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-decorated-am-ah-paper)\"></path><text x=\"514.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">buys</text><path d=\"M620.0 98.0 L620.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-decorated-am-ah-paper)\"></path><text x=\"628.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">HTTPS: create booking</text><path d=\"M560.0 198.0 L490.0 245.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-decorated-am-ah-paper)\"></path><text x=\"538.0\" y=\"205.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">SQL: writes</text><path d=\"M620.0 198.0 L620.0 260.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-decorated-am-ah-paper)\"></path><text x=\"650.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">HTTPS: charges</text></svg>", "caption": "The left picture asserts that eight things are connected. The right one says what each thing is and what travels along each line, so a reader can check it, and disagree with it."}
```

Bento asked three questions that week, and the printout answered none of them:

1. *When somebody buys a ticket, which service takes the money?* The picture has a box with the
   payment gateway's logo, and three arrows touch it. It does not say which one is the purchase.
2. *If the payment gateway is slow, does the seat stay held?* Nothing on the picture is about time,
   so it cannot say.
3. *Where is a passenger's CPF stored?* There are two database logos and no way to tell which data
   is in which.

The right half of the figure is what Tainá drew when Bento asked the first question. It shows five
elements instead of twelve, and **every one of them is named, typed and joined by a line that says
what travels along it.** It cannot answer the third question either, and it does not need to: that
one gets its own picture, which lesson 3 draws.

## Decoration and communication

A decorated diagram is not useless because it is ugly. It may be very handsome. It fails because it
**asserts things the reader cannot check**: that these parts exist, that they are connected, that
the connection matters. The reader fills in the meaning of every line from their own guess, and two
readers guess differently without knowing that they did.

Three signs say a diagram is decoration:

- **It is the same picture for every audience.** The board, the new engineer and the auditor were
  all handed the printout. They need different things, so it served none of them well.
- **Nothing on it could be wrong.** A diagram that makes no specific claim, such as which service
  calls which over what protocol, cannot be contradicted by the system. That is what makes it
  useless as a reference.
- **The logos carry the meaning.** A logo says which product is used. It does not say what that
  product does in this system, and the same database product may be three different stores.

## Start from the question

Before drawing, write two lines at the top of the page:

> **Question:** when a passenger buys a ticket, which parts take part, and in what order?
> **Reader:** Bento, a new engineer on the Sales team.

With those two lines, the drawing has a scope. The boarding app is not in it, because boarding is
not part of buying. The order matters, so a sequence diagram from lesson 2 might serve better than
boxes. The reader is an engineer, so the protocols and technologies belong on the lines.

**Draw it yourself.** Pick a system you know, from work or from a course project. Write a question
somebody new would ask about it, and the reader who would ask it. Then draw only what answers that
question, and count the elements: if there are more than about a dozen, the question is too broad,
or the diagram is answering a second one as well.
