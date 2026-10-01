---
title: "The repeater: distance, and nothing else"
version: 1
---

A signal on a cable gets weaker and more distorted the further it travels. Past some length the
card at the far end can no longer tell a 1 from a 0. **A repeater receives the signal before it
reaches that point, regenerates it as a clean signal with fresh timing, and sends it on.** That is
its whole job. It reads no address, keeps no table and decides nothing, which puts it at layer 1
with the cable it extends. **This lab has no repeater**: its cables are software and never weaken,
so this section shows no output.

The limit it works against is written into each Ethernet standard. For twisted-pair copper, the
cable in every office wall, **a run between two devices may be 100 metres long**, and that figure
is what decides where the switches in a building go: every desk has to be within 100 metres of
cable from one. Fibre reaches much further, which is why links between buildings are fibre.

The wrong idea worth naming is that a repeater makes a network bigger. It makes a **cable** longer.
Everything on both sides of it still shares one signal: a frame sent on one side is repeated on the
other whether anybody there needs it or not, and two machines transmitting at once on opposite
sides still collide. **A repeater extends one collision domain**, which lesson 18 defines; it never
splits one.

That is also why the hub of lesson 1 is described as a **repeater with several ports**. It
regenerates whatever arrives on one port and sends it out of all the others, which is the same job
done in several directions at once, with the same consequences.

## Where you meet one today

Hardly anybody installs a box called a repeater on an Ethernet network now, because a switch does
the job better: it regenerates the signal too, since it receives each frame and sends it again, and
it does not pass on what the other side does not need. The idea survives in three places:

- **Media converters and fibre links.** When 100 metres is not enough, the answer is a switch at
  each end of a fibre, not a chain of repeaters on copper.
- **Signal regeneration inside other equipment.** Long-distance fibre and the provider's lines
  have amplifiers and regenerators along the way, out of sight of the networks they carry.
- **Wi-Fi "repeaters" sold for houses.** Despite the name, these receive whole frames and send them
  again, so they work at layer 2, and every frame they relay crosses the air twice, which shares
  the channel's air time between the two hops.

The useful habit from this section is a question to ask of any device sold as extending a network:
does it only carry the signal further, or does it read the frames? A repeater only carries; lesson
1's switch reads, and the bridge in the next section is where that difference started.
