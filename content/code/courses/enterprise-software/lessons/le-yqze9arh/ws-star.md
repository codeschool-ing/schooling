---
title: WS-*, the standards that filled the header
version: 1
---

SOAP's `Header` was designed to be extended. Anything the infrastructure needed to say about a
message — who sent it, whether it may be read in transit, where the reply should go, which
transaction it belongs to — could become a header block with its own namespace, defined by its own
specification. Between about 2002 and 2007, vendors and standards bodies wrote dozens of them, and
the family became known as WS-\*, read "WS-star". The common view now is that WS-\* was
over-engineering. **Each specification solved a real problem; what sank the family was that they
had to be combined, and every combination was a new place for two vendors' toolkits to disagree.**

## The four you will meet

| specification | body, year | the problem it solved |
|---|---|---|
| WS-Addressing | W3C Recommendation, 2006 | a message says where it is going and where the reply should go, inside the envelope, so it can cross MQ or a second hop and still be answered |
| WS-Security | OASIS standard, 2004 | parts of a message are signed and encrypted, and identity tokens travel in the header, so protection stays with the message through every intermediary |
| WS-ReliableMessaging | OASIS standard, 2007 | a sequence of messages arrives, once each and in order, over a connection that drops, by numbering them and acknowledging what arrived |
| WS-AtomicTransaction | OASIS standard, 2007 | several services commit together or not at all, with a coordinator running a two-phase commit across them |

Around those four sat WS-Policy (a service declares what it requires, such as "every request
signed"), WS-Trust and WS-SecureConversation (issuing and reusing security tokens), WS-Federation,
WS-Coordination, and WS-BPEL, the orchestration language lesson 7 described. A complete WS-\*
stack was thousands of pages of specification.

## WS-Addressing: the envelope that knows its way

Over plain HTTP, the reply goes back on the connection the request came in on. Put the same message
on an MQ queue, or pass it through a bus that holds it for an hour, and there is no connection to
reply on. WS-Addressing put the routing facts in the header: `To`, `Action`, `MessageID`, `ReplyTo`
and, on the reply, `RelatesTo`, carrying the id of the message it answers. That last pair is the
correlation identifier, and lesson 11 shows it is a pattern rather than a SOAP invention. **The idea survived
everywhere; the header did not.** Brokers now carry the same facts as message properties, and an
HTTP API carries them as headers of its own.

## WS-Security: protection that travels with the message

TLS protects a connection, from one end to the other. When a message crosses a bus, there are two
connections, and in the middle the bus reads the message in clear, because it has to route and
transform it. **WS-Security moved protection from the connection to the message**: XML Signature
over the body proves who wrote it and that nobody changed it, XML Encryption hides chosen elements
from everybody but the final receiver, and the bus in the middle can still read the parts it needs.

That is a genuine capability, and it is exactly what TLS cannot give you. It was also the hardest
part of WS-\* to get right. A signature over XML is computed over a canonical form of the document,
and two toolkits that disagreed by one detail of canonicalisation, a namespace declaration moved or
a line break normalised, produced signatures the other could not verify.

What most services actually used was much simpler: a `UsernameToken` in the header. FarmRegistry
demands one, which is why the request in the previous section was incomplete:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
    xmlns:fr="http://schemas.serraalta.example/farm-registry/2016">
  <soap:Header>
    <wsse:Security soap:mustUnderstand="1">
      <wsse:UsernameToken>
        <wsse:Username>rota-planner</wsse:Username>
        <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">********</wsse:Password>
      </wsse:UsernameToken>
    </wsse:Security>
  </soap:Header>
  <soap:Body>
    <fr:GetFarmTank>
      <fr:farmCode>0412736</fr:farmCode>
    </fr:GetFarmTank>
  </soap:Body>
</soap:Envelope>
```

Two details carry the lesson. `mustUnderstand="1"` tells the receiver that if it does not know what
a `wsse:Security` block is, it must refuse the message with a fault rather than ignore it; without
it, a service that skipped security would process the call as if nothing were missing. And
`PasswordText` means the password is in the message as written. **A `UsernameToken` with a plain
password is exactly as safe as the TLS around it, and no safer**: it is message-level in form and
connection-level in protection. FarmRegistry and the 14 services that Salesforce calls all work this way,
with one shared account per calling system, and none of the 70 flows signs or encrypts anything.

The capability did not disappear where it is needed. An NF-e is an XML document signed with XML
Signature, using the issuer's digital certificate, so the tax authority, the customer and an
auditor years later can each check who issued it and that nothing in it changed. The signature is
inside the invoice rather than in a SOAP header, because it is the document that has to be proven,
not one trip it made.

## WS-ReliableMessaging and WS-AtomicTransaction

WS-ReliableMessaging gave SOAP over HTTP what a message broker gives anything: each message in a
sequence is numbered, the receiver acknowledges ranges, and the sender retransmits what was not
acknowledged. It worked, and it asked both ends to keep sequence state. **Companies that already
had a broker, as Serra Alta has IBM MQ, got the same guarantee without asking anything of the
endpoints**, and lesson 10 shows the remaining duty the broker cannot take away: a consumer that
can receive the same message twice without doing the work twice.

WS-AtomicTransaction brought the database's two-phase commit to services. A coordinator asks every
participant to prepare, and each one holds its locks until the coordinator says commit or abort.
Inside one data centre with one owner, that is workable. Across services owned by different teams,
it means one team's database waits, locks held, on another team's coordinator. Across companies, a
supplier's outage holds your rows. Very few organisations switched it on. The idea that replaced it
is lesson 7's compensation: do each step for real, and when a later step fails, undo the earlier
ones with an action of their own.

## Why the weight pushed everybody away

No single specification was the problem. The trouble was in the joins:

- Interoperability had to be negotiated. The WS-I organisation existed to publish profiles
  saying which options of which specification two toolkits should use, so that a Java service and a
  .NET client could talk.
- Tooling was the only way to write a message. A developer could not build a signed, addressed,
  reliable SOAP request by hand and check it by eye, so the toolkit's bugs became the system's.
- Size and speed suffered: a request with three header blocks and a signature was many times the size
  of its payload, and parsing it cost real time on the hardware of 2005.
- The browser and the phone could not take part. JavaScript in a page could make an HTTP call
  and read JSON; it could not run a WS-Security stack.

Roy Fielding had described REST in his doctoral dissertation in 2000, and JSON had been specified
as RFC 4627 in 2006. In the decade after 2005, public APIs moved to JSON over HTTP, with TLS for
the connection and tokens such as OAuth's for identity, and enterprise teams followed when they
built new services. **What was given up was message-level security and a machine-readable contract;
the first is rarely missed, and the second came back as OpenAPI.**

Inside companies like Serra Alta, WS-\* did not die. It stopped growing. The 14 services Salesforce calls
still expect a `UsernameToken`, the NF-e services still carry signed XML, and Rui's team still keeps
a SOAP test tool open on every screen. Joana's job is not to remove any of it in a hurry. It is to
make sure nothing new is built that way, and that the services which remain are wrapped well, which
is section 06 of this lesson.
