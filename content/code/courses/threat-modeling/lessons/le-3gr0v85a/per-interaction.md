---
title: STRIDE per interaction
version: 1
---

**STRIDE per interaction** applies the letters to a flow together with the two elements at its
ends, and only to flows that cross a trust boundary. It is the variant behind Microsoft's free
Threat Modeling Tool, and it suits the way threats actually happen: across a line, between a
sender and a receiver that trust each other differently.

For each crossing, the questions come in a fixed order, from the sender's side to the receiver's:

| | about | asks |
|---|---|---|
| **S** | the source | is the sender who it claims to be? |
| **T, I** | the flow | can the data be changed or read on the way? |
| **D** | the flow and the receiver | can the receiver be flooded, or the flow cut? |
| **E** | the receiver | can the receiver be made to do something the sender may not ask for? |
| **R** | both | if the sender later denies it, is there a record? |

### Flow 7, interaction by interaction

The payment webhook goes from the gateway (vendors' zone) to the portal (Vereda's cloud), and it
changes a booking from unpaid to paid.

- S, the source: is the request from the gateway? The portal does not check. **This is T01**,
  and it is the threat lesson 1 started from. The gateway signs each call; the fix is verifying
  the signature.
- T, the flow: could the amount or the booking id be changed on the way? It travels over HTTPS
  from the gateway, so on the way, no. Once anybody can send the request, the question is moot:
  they write whatever they like.
- I, the flow: the webhook carries a booking id and a status, nothing worth reading.
- D: a flood of fake webhooks could load the portal; the same answer as for any public address.
- E, the receiver: marking a booking paid is more than an anonymous request should be able to
  do. It is S and E describing the same flaw from two ends.
- R: if the gateway and the portal disagree about whether a session was paid, does Vereda keep
  the original webhook? Nobody knows, which is itself worth writing down.

Six questions, one serious threat, two "check this", and three answered. That ratio is normal. The
value of working the letters in order is that **the one serious threat could not hide in a
category nobody asked about.**

### Which variant to use

Per element for a first pass over a whole system, because it is quick and covers everything. Per
interaction on the flows that cross the boundaries you care about most, because that is where
the serious threats concentrate. Most real models use both, in that order.
