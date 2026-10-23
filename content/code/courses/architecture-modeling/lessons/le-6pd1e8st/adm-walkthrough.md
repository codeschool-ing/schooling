---
title: Carcará around the cycle once
version: 1
---

**A walk around the ADM is easiest to understand with one change.** Carcará's board decided: *by the
end of 2027, every passenger boards with a digital ticket, and the stations stop printing.* Tainá
led the architecture work, with Joana as analyst. This is what each phase produced, kept to the size
a company of Carcará's size can afford.

## Preliminary

Carcará had never done enterprise architecture deliberately. The Preliminary phase took two weeks and
produced three things: **who does it** (Tainá, half her time, with Joana and one person from each
team on call), **eight architecture principles** (the third section from the end shows two), and
**the tailoring**: which deliverables they would produce, in which tool, and which they would skip.

## A. Architecture Vision

A **Statement of Architecture Work** of two pages: scope, stakeholders, the vision in one paragraph,
the constraints (*Frota stays*, *the LGPD*), and the measure of success: *every boarding at the 26
stations uses a digital ticket; ticket printing at stations ends; station agents' time per sale falls
from four minutes to two*. The board approved it in one meeting.

## B. Business Architecture

The baseline: agents sell paper tickets for cash and cards; some passengers, mostly older and in
rural stations, have no smartphone. The target: agents sell **digital tickets** that are sent by SMS
or printed once as a QR code on a receipt, and the receipt is the ticket. The gap found the
uncomfortable part: **a passenger with no phone and no e-mail**. The business answer, a QR receipt
that the driver scans, came from this phase, not from any engineer.

## C. Information Systems Architectures

Data: a ticket gains a **delivery channel** and a passenger may have no account. Applications: the
station back office is **retired**; agents use a new counter mode of the passenger web app, which
already talks to ticketing. The boarding app must accept a QR code from paper as well as from a
phone. Each change became a work item and, where it was hard to reverse, a decision record.

## D. Technology Architecture

The 26 stations' receipt printers stay, now printing QR receipts; the PCs are replaced by tablets in
2026. **The station internet links became the critical dependency**: a counter that cannot reach
ticketing cannot sell. The requirement went into the centre, and Phase B was revisited: agents get an
offline sale mode for up to fifty tickets, reconciled later. That loop is the ADM working as designed.

## E and F. Opportunities, solutions and migration

The gaps were grouped into four work packages and three **transition architectures**, one per
quarter, because 26 stations cannot switch on the same day: pilot at two stations, then the
coastal routes, then the rest. The roadmap and plan were one spreadsheet and one diagram.

## G and H. Governance and change

During implementation, each team's design was checked against the target in a 30-minute
**compliance review** before it shipped. In month five, the payment company announced the new
settlement format from lesson 7, and Phase H raised it as a change: small enough to handle inside
the current work, so no new cycle was started.
