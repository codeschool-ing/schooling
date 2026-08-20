---
title: Everything is a box
---

Every element is a rectangle with four layers, from the inside out: **content**, **padding**, **border** and **margin**.

Padding is inner space — it pushes the content away from the border and takes the background colour. Margin is outer space — it separates this box from its neighbours and is transparent.

One detail confuses everybody once: **adjacent vertical margins merge**. Two paragraphs with 20px of margin below and above do not end up 40px apart; they end up 20 apart. That is *margin collapsing*, it only applies vertically, and it is the reason many people use flex/grid `gap` instead of margin.
