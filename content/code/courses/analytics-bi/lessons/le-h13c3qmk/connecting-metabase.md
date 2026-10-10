---
title: The first visit, and connecting the layer
version: 1
---

Open `http://localhost:3000` in your browser (on UTM, the machine's address instead of
`localhost`). Metabase greets a new installation with a setup that takes four short steps, and
everything in it can be changed later in its admin settings.

1. **Let's get started**, then **What should we call you?** Your name, an e-mail and a password.
   This is the first administrator of this Metabase, and the e-mail is only a login: nothing is
   sent to it.
2. **What will you use Metabase for?** *Self-service analytics for my own company*. The answer only
   decides which hints Metabase shows afterwards.
3. **Add your data.** Choose **PostgreSQL**, and fill in the form:

   | field | value |
   |---|---|
   | Display name | `Lantern` |
   | Host | `localhost` |
   | Port | `5432` |
   | Database name | `lantern` |
   | Username | `metabase` |
   | Password | the one you gave the role |
   | Schemas | *Only these...*, then `semantic` |

   The last line is the one that matters most. With *All*, Metabase would offer every schema the
   role can see; with only `semantic`, the people who use it find the layer and nothing else, even
   if somebody later grants the role more than it should have. Then **Connect database**.
4. **Usage data preferences.** A box, ticked by default, allows Metabase to collect anonymous
   usage events about how the product is used. Untick it if you prefer; it never includes your
   data. Then **Finish**, and **Take me to Metabase**.

Metabase now **syncs** the database: it reads the list of tables and columns, and their comments,
into its own records. That is quick for six objects, and it repeats on a schedule, which is worth
knowing for the day you add a column and Metabase does not show it yet.

Metabase also installs a **Sample Database** of its own, a small shop called *Sample Database*, for
people with no data to try it on. It does no harm. It can be removed in the admin settings, under
*Databases*, so that nobody builds a chart on it by mistake.
