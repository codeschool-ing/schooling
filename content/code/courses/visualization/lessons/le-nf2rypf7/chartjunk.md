---
title: Chartjunk
version: 1
---

Tufte's name for decoration that carries no information is **chartjunk**. Most of it arrives by
default, from a template or a theme, rather than by anybody's decision. The common kinds:

- **Frames and backgrounds.** A box around the plot and a coloured fill inside it. The axes already
  mark where the chart is.
- **Heavy gridlines.** Dark lines at every tick that compete with the data for the eye.
- **Shadows, gradients and glossy fills.** A shadow behind a bar is a second, fainter bar the reader
  has to discount. A gradient makes one end of a bar look longer than the other.
- **A legend for one series.** If there is one colour, it names nothing. The title or the axis can
  say what the bars are.
- **Redundant labels.** The same value as a bar's length, a number on the bar, and a gridline beneath
  it. Pick the ones the reader needs.
- **Pictures behind the data.** A photograph of vegetables behind a revenue chart sets a mood and
  hides the gridlines.
- **The third dimension**, from lesson 16, which is chartjunk that also distorts.

The test for each is the same question: **if I delete this, does the reader lose anything?** If not,
delete it. If they lose a little, make it fainter rather than removing it.

## Defaults are decisions too

Tools differ in how much junk they start with. matplotlib starts with a white background but a full black
frame on all four sides; many spreadsheet templates add gradients and borders. Whatever the tool, its
defaults were chosen by somebody who has never seen your data. Treat them as a first draft.
