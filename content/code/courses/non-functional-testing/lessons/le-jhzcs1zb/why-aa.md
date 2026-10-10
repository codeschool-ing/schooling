---
title: Why AA is the usual target
version: 1
---

Almost every accessibility requirement you will be handed says "WCAG 2.x AA". **AA is the level
that laws, public procurement and the standards built on them point at**, and that is the whole
reason it is the default: a team rarely chooses it, it inherits it from a contract or a
regulation. A tester does not need to be a lawyer, and nothing here is legal advice. What a tester
does need is to know which document a requirement came from, because that document decides the
version, the level and which pages are in scope.

Three jurisdictions cover most of what you will meet, and each one reaches WCAG by a different
route.

## The European Union

**The European Accessibility Act**, Directive (EU) 2019/882, has applied since 28 June 2025 to a
defined list of products and services sold in the EU: among them e-commerce, consumer banking,
e-books, and websites and apps that sell passenger transport tickets. Microenterprises that
provide services are exempt. The Act itself does not name WCAG. It states requirements, a
product is presumed to meet them when it meets the harmonised European standards, and the
reference used for the web is **EN 301 549**, whose web clauses incorporate WCAG 2.1 at level AA. An older directive, (EU) 2016/2102,
already applied the same standard to the websites of public-sector bodies.

A train operator's booking page is named in the list. Whether a small theatre's box office is
covered is the kind of question to hand to somebody qualified, before the test plan is written
rather than after.

## The United States

**Section 508 of the Rehabilitation Act** applies to the information and communication technology
of federal agencies: what they build, buy and use. Its 2017 revision incorporates WCAG 2.0 levels
A and AA by reference, for web pages and also, by extension, for documents and software. A
company selling software to a federal agency meets it through the contract, which is why vendors
publish conformance reports. Other US laws, such as the Americans with Disabilities Act, also
reach websites, and how far is a matter of courts and regulations this course does not try to
summarise.

## Brazil

**The Lei Brasileira de Inclusão**, Lei 13.146/2015, also called the Estatuto da Pessoa com
Deficiência, makes accessibility mandatory in its article 63 for websites kept by companies with
a seat or commercial representation in the country and by government bodies, "according to the
accessibility practices and guidelines adopted internationally". It does not name a version or a
level, and WCAG is the guideline that phrase is read as pointing to.

**eMAG**, the Modelo de Acessibilidade em Governo Eletrônico, is the federal government's own
model for its websites. Its version 3.1 is built on WCAG 2.0 and adapted to Brazilian public
services, with recommendations of its own such as a fixed set of accessibility shortcut keys.
It binds the government's websites; a private shop meets the LBI, not eMAG.

## What that means in a test plan

The three routes land on different versions: 2.0 for Section 508, 2.1 through EN 301 549, and an
unnamed "international guideline" in Brazil. **Testing against WCAG 2.2 AA covers all of them**,
because each version contains the one before it at the same level. That is why lesson 1 wrote 2.2
AA into the requirement, and why the platform this course is served on holds every one of its
own screens to the same line.

Write the scope down with the level:

> The booking flow (`book.html` and the confirmation it shows) conforms to WCAG 2.2 at level AA,
> checked with an automated audit and by hand with a keyboard and a screen reader, before
> release.

The last clause is the half people leave out. A requirement that names only the level invites a
team to run one tool and call the result conformance, and lesson 13 shows how much a tool leaves
unseen.
