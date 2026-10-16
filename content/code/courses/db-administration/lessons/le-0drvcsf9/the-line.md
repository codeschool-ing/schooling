---
title: The line between the administrator and the developer
version: 1
---

Most arguments in this job happen on one line: where the developer's responsibility ends and the
administrator's begins. The line is not where people usually draw it — "the developer writes code,
the DBA runs the database" — because the most important thing in the database, its schema, is
written by both.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 286\" role=\"img\" aria-label=\"Six layers from the application down to the machine. The application and its queries belong to the developer. The schema is shared. Roles and grants, the server's configuration, memory and maintenance, and upgrades, logs and capacity belong to the DBA. The machine underneath is shared with whoever runs the operating system.\"><text x=\"560\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">who answers for it</text><rect x=\"10\" y=\"30\" width=\"440\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the application and its queries</text><rect x=\"470\" y=\"30\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">developer</text><rect x=\"10\" y=\"72\" width=\"440\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the schema: tables, keys, indexes</text><rect x=\"470\" y=\"72\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">shared</text><rect x=\"10\" y=\"114\" width=\"440\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">roles, grants and privileges</text><rect x=\"470\" y=\"114\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">DBA</text><rect x=\"10\" y=\"156\" width=\"440\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the server: configuration, memory, maintenance</text><rect x=\"470\" y=\"156\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">DBA</text><rect x=\"10\" y=\"198\" width=\"440\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">upgrades, logs and capacity</text><rect x=\"470\" y=\"198\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">DBA</text><rect x=\"10\" y=\"240\" width=\"440\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"257\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the machine: disk, filesystem, operating system</text><rect x=\"470\" y=\"240\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"257\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">shared</text></svg>", "caption": "The line runs through the schema. Above it the developer decides; below it the DBA does; the schema is where the two have to agree."}
```

**Above the line, the developer decides.** What the application asks, in which order, inside which
transactions, and how it reacts when the database says no. A query that reads a million rows to show
twenty is the developer's to fix, and an administrator who silently adds an index to hide it has
fixed nothing: the next query will do the same.

**Below the line, the administrator decides.** How the server is configured, how much memory it
uses and for what, how often it is maintained, which version it runs, what it logs, who may log in
and from where, and whether the disk will last. A developer who changes `shared_buffers` on the
production server because a blog post said so has crossed the line in the other direction.

**The schema is shared, and that is on purpose.** The developer knows what the data means; the
administrator knows what a change will cost on a table of two hundred million rows. Adding a column
is a line of code to one and a lock on the busiest table in the company to the other, and lesson 22
is about doing it so that both are right.

## What that looks like on an ordinary week

| situation | who acts | who is told |
|---|---|---|
| a new feature needs a table | developer writes the migration | administrator reviews it before it runs on production |
| a query became slow after a release | developer, with the administrator's numbers | both |
| the disk is 80% full | administrator | the team, with a date it will be 100% |
| a new service needs read access to two tables | administrator creates the role and grants | the developer, with the role's name |
| a minor release fixes a security bug | administrator schedules it | everybody, with the time of the restart |
| autovacuum cannot keep up with one table | administrator tunes it | the developer, if the cause is how the table is written |

The pattern in the last column is the point. **Neither side works on the database without telling
the other**, because each one's decisions land on the other's half: an unannounced restart breaks an
application that does not reconnect, and an unannounced migration takes a lock nobody planned for.
