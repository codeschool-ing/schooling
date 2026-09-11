---
title: A ticket, and a table
version: 1
---

The previous readings gave you a place to put a small piece of text. This one is about what to put
there, and the answer is: as little as possible.

## The shape

A cookie holds an **identifier** and nothing else. Everything that identifier stands for lives on
the server, in a table the browser never sees.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The browser holds a short opaque identifier. The server holds a table in which that identifier is a row carrying who the visitor is, when the session began and anything else the application needs.\"> <rect x=\"20\" y=\"34\" width=\"260\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"150\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">what the browser holds</text> <rect x=\"40\" y=\"80\" width=\"220\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"150\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">session=8f3c1a9e</text> <path d=\"M286 89 L434 89\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <text x=\"360\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">finds one row</text> <rect x=\"440\" y=\"34\" width=\"260\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"570\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">what the server holds</text> <text x=\"570\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">8f3c1a9e</text> <text x=\"570\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">user: ana</text> <text x=\"570\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">signed in at 09:14</text> <text x=\"570\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">role: student</text> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">thirty bytes cross the network; the rest never leaves the building</text> <text x=\"360\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and because the truth is in the table, deleting the row ends it everywhere at once</text> </svg>", "caption": "A cloakroom ticket. Worth nothing by itself, and the only thing that finds the right row."}
```

The cookie is a cloakroom ticket. The ticket is worth nothing by itself, it says nothing about what
is in the cloakroom, and the only thing it does is let somebody behind a counter find the right
row.

This gets you four things at once. The cookie stays tiny, so the tax on every request stays tiny.
The visitor cannot change what is in it, because the value is meaningless. Nothing sensitive
crosses the network after the first time. And you can end a session immediately, from your side,
by deleting the row — which is a bigger deal than it sounds, and the next reading is about what it
costs to give up.

## The identifier has to be unguessable

Not a number that increases. Not a username with something added. Not anything derived from
anything a visitor knows.

If session `1041` exists, somebody will try `1040`, and if that works they are now signed in as
whoever owns it. The attack needs no skill and no tools, and it has been found in production
systems of every size.

The requirement is a long random value from a source meant for security rather than from an
ordinary random function. In practice this is one call to whatever your language calls its secure
random, and the reason to know the rule is to recognise the shape of a mistake: a session
identifier that looks like a number, or looks like an email address, is a defect regardless of
what else is right.

## Regenerate it at the door

Here is an attack that is not obvious and has a one-line fix.

Somebody arranges for you to visit their link, which carries a session identifier they chose. Your
browser now holds it. You sign in — and if the server keeps the same identifier and simply attaches
your account to it, then the identifier the attacker already knows is now a signed-in session.

The fix is to **issue a new identifier at the moment the visitor signs in**, and throw the old one
away. It costs one line, it closes the whole class, and it is the reason frameworks have a function
whose name is some version of *regenerate*.

## Two clocks

A session should end, and there are two different ways of deciding when.

**Idle timeout**: it ends a period after the last request. Convenient, and what keeps somebody who
walked away from a shared machine from staying signed in indefinitely.

**Absolute timeout**: it ends a fixed time after it began, active or not. Less convenient and much
harder to argue with, which is why anything handling money tends to have one.

Most systems use both, with the idle clock short and the absolute clock long. Neither is a
substitute for the third thing, which is ending it on purpose.

## Logging out means deleting the row

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Logging out by clearing the cookie alone leaves the row alive on the server, so a copied value still works. Deleting the row first ends the session for every copy of the value.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">clearing the cookie alone</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">this browser forgets the value</text> <rect x=\"20\" y=\"86\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the row is still there</text> <rect x=\"20\" y=\"136\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">any copy of it still signs in</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">deleting the row first</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the row is gone</text> <rect x=\"380\" y=\"86\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">every copy of the value is now worthless</text> <rect x=\"380\" y=\"136\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">then clear the cookie, for tidiness</text> <text x=\"360\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the cookie is a copy; the row is the session</text> </svg>", "caption": "Two steps, in this order. The one that matters is the one the visitor cannot see."}
```

If logging out only clears the cookie, then the session is still alive on the server. The cookie is
gone from that browser, and anybody who copied the value earlier — from a shared machine, from a
log file that recorded a header, from a script — can still use it.

So logging out is two actions: delete the row, and then clear the cookie. In that order, because
the row is the one that matters and the cookie is only a browser's copy.

## Sessions before anybody signs in

The opening video asked who says the three things in the basket are yours, and the answer is this
mechanism working before there is any account at all.

A visitor who has never signed in still gets a session: an identifier, a row, and a basket in the
row. Nothing about the arrangement requires a person to be known — it requires only that the same
browser comes back with the same ticket.

Signing in then does not create the session. It **attaches an account to one that already exists**,
which is what makes the basket survive the login instead of emptying at the worst possible moment.
And since the previous section said to issue a new identifier at that point, the row is carried
across to the new one rather than abandoned with the old.

It is worth seeing clearly, because it is the difference between a shop that works and a shop
people give up on: the anonymous session and the signed-in session are the same machinery, and only
one field of the row changed.

## Where the table actually lives

One practical thing, because it is the first surprise when a site grows past one machine.

If the table is in the server's memory, then restarting the server signs everybody out, and running
two servers signs people out at random — half their requests reach the machine that has never heard
of them. This is the statelessness of the previous lesson arriving to collect: the protocol allows
any machine to answer, and you have just made that false.

The answer is to put the table somewhere both machines can reach — a shared store built for it, or
the database you already have. The cost is one lookup per request, which is the price of being able
to revoke anything instantly. The next reading is about the people who decided that price was too
high.
