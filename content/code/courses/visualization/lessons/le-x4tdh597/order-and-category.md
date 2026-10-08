---
title: What a channel can say
version: 1
---

Before choosing a channel, ask what kind of value it has to carry. There are only two kinds that
matter at this point.

- **A quantity** has an amount: orders, minutes, reais, kilometres. One value can be twice another,
  and the gap between 10 and 20 is the same as the gap between 30 and 40.
- **A category** is a name: a region, a product line, a payment method. Categories are different
  from each other, and that is all.

Some categories do have an order without having an amount: *small, medium, large*, or the months of
a year. They sit between the two kinds and borrow from both, which matters again in lesson 12.

## Channels with an order, and channels without

The common mistake is to think of colour as one channel. It is at least two, and they behave in
opposite ways.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 200\" role=\"img\" data-fig=\"l01-ordered\" aria-label=\"Two rows of six squares. The top row changes lightness, from pale to dark blue, and anybody can put it in order. The bottom row changes hue, red, orange, green, blue, purple and pink, and there is no order to put it in that two people would agree on.\"><rect x=\"250.0\" y=\"30.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#dbe4f7\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"250.0\" y=\"120.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#d1495b\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"302.0\" y=\"30.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#b0c4ee\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"302.0\" y=\"120.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#ed8b2d\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"354.0\" y=\"30.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#7f9fe3\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"354.0\" y=\"120.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#5aa65a\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"406.0\" y=\"30.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#5079d4\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"406.0\" y=\"120.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#3b7dd8\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"458.0\" y=\"30.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#2b52c9\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"458.0\" y=\"120.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#8a5cc7\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"510.0\" y=\"30.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#1a3380\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"510.0\" y=\"120.0\" width=\"44.0\" height=\"44.0\" rx=\"3\" fill=\"#d665a8\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"236.0\" y=\"52.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lightness: anyone can sort it</text><text x=\"236.0\" y=\"142.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hue: nobody agrees on the order</text></svg>", "caption": "A channel that has an order can carry a quantity. Hue has none, so it is for telling categories apart and never for saying which is more."}
```

**Lightness has an order.** Show anybody six squares from pale to dark blue and they will sort them
the same way, so lightness can carry a quantity, if roughly. **Hue has no order.** Red, green and
purple are different, and no reader agrees on which comes first. Hue is for telling categories
apart.

That gives a rule that settles most choices before they start:

| channel | carries a quantity? | separates categories? |
|---|---|---|
| position on a common scale | yes, precisely | yes |
| length | yes, precisely | poorly on its own |
| angle, slope | yes, roughly | no |
| area | yes, poorly | no |
| lightness, saturation | yes, roughly, as an order | a few at most |
| hue | **no** | **yes** |
| shape | **no** | yes, a handful |

## The two errors this prevents

**A quantity drawn in hue.** A map where each state's order count picks a colour from a rainbow
gives a reader no way to tell whether purple is more than orange without a legend, and they will
read the legend wrongly half the time. Lesson 12 is about the palettes that fix this.

**A category drawn in an ordered channel.** Five product lines drawn as five shades of one blue
make the reader look for an order that is not there: the darkest line looks like the most
important. Five categories want five hues, or five positions.

Neither chart is broken in the sense that software can detect. Both draw correctly, and both say
something the data does not.
