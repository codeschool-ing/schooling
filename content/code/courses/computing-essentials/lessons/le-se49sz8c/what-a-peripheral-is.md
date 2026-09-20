---
title: A peripheral is a translator, and that says where the failures are
version: 1
---

The last two lessons were about parts that compute. Nothing in this one computes anything. A
peripheral sits on the boundary between a machine that only holds numbers and a world that does
not, and its entire job is **turning one into the other**.

| device | what it translates | which way |
|---|---|---|
| keyboard | a finger on a key | world → numbers |
| mouse | a movement on a desk | world → numbers |
| scanner | light off a sheet of paper | world → numbers |
| monitor | numbers | numbers → world |
| printer | numbers | numbers → world |
| touchscreen | both, in the same glass | both |

Input, output, or both. That is the whole taxonomy, and it is worth naming because it predicts
the shape of every fault in this lesson.

## What a peripheral can and cannot be

**It cannot be slow the way storage is slow.** A hard disk makes you wait because a physical arm
has to move. A monitor has nothing to wait for; it redraws on a fixed schedule whether or not
anything changed. If a screen feels sluggish, the screen is almost never the thing that is
sluggish.

**It can translate badly.** A keyboard that cannot type `ç` without a workaround, a printer that
renders a photograph as a grid of visible dots, a scanner that invents detail it never saw — each
is a translation that lost something, and none of them shows up as an error message.

**It can be expensive in a way the price tag hides.** Three of the five devices here have running
costs: ink, toner, paper. One of them is sold below what it costs to make, on the understanding
that you will pay the difference later. That is the printers section, and it is the single
largest avoidable expense in this course.

## The one rule that covers all of them

**A peripheral is chosen against a person, not against the rest of the machine.** A processor is
chosen against the work; a monitor is chosen against your eyes and your desk, a keyboard against
your hands and your language, a mouse against your grip.

Which is why the advice here cannot be a number. Nobody can tell you the right keyboard, and
anybody who does is selling one. What this lesson can do is tell you **which numbers on the box
are real and which are marketing**, so that when you do choose, you are choosing on the facts.
