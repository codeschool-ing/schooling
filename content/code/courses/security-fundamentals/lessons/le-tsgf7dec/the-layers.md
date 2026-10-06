---
title: The layers, from the building to the data
version: 1
---

A useful way to list the layers is from the outside in: what a threat has to cross, in order, to
reach the data. Each layer has its own controls and its own typical holes.

```schooling-figure
{"svg": "<svg id=\"sf-layers\" viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Defence in depth as nested layers. From the outside in: policy and people, physical, perimeter, internal network, host, application, and data at the centre. A threat from outside has to cross every ring to reach the data.\"><rect x=\"20\" y=\"14\" width=\"680\" height=\"272\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"25.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">policy and people</text><rect x=\"64\" y=\"34\" width=\"592\" height=\"232\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"74\" y=\"45.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">physical</text><rect x=\"108\" y=\"54\" width=\"504\" height=\"192\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"118\" y=\"65.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">perimeter</text><rect x=\"152\" y=\"74\" width=\"416\" height=\"152\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"162\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">internal network</text><rect x=\"196\" y=\"94\" width=\"328\" height=\"112\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"206\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">host</text><rect x=\"240\" y=\"114\" width=\"240\" height=\"72\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"250\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">application</text><rect x=\"284\" y=\"134\" width=\"152\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">data</text></svg>", "caption": "Seven layers between the outside and the data. Each has its own controls and its own holes."}
```

| layer | what it protects | controls at the shop | a typical hole |
|---|---|---|---|
| **policy and people** | everything, by deciding what is allowed | an acceptable use policy, training, a process for leavers | a rule nobody was told about |
| **physical** | the hardware itself | a locked office, a locked rack, a visitor book | a door propped open |
| **perimeter** | the boundary with the internet | a firewall at the edge (lesson 5) | a rule that allows too much |
| **internal network** | traffic between the shop's own machines | segments the office cannot cross (lesson 5) | a flat network where everything reaches everything |
| **host** | each computer | patches, disk encryption, few installed programs | a missing update |
| **application** | each program that serves people | login, permission checks (lesson 8), input checks | a page that forgot to check |
| **data** | the information itself | encryption, backups (lesson 12), file permissions | a copy left somewhere unprotected |

Two rows are easy to leave out, and each is a lesson in itself.

**Policy and people sit around everything else.** A firewall rule exists because somebody decided
what traffic is allowed; without the decision, the rule is a guess. Training is a control like any
other, with the same strengths and holes: it lowers the chance a person clicks the fake invoice,
and it never brings that chance to zero, which is why the layers inside it still matter.

**Data is the last layer, and the one that travels.** Every other layer protects a place. Data
leaves places: it is copied to a laptop, attached to an email, put in a backup. Controls on the
data itself, like encryption and permissions that go with the file, are the only ones still
protecting it once it is somewhere the other layers do not reach.

The order also says something about cost. Controls near the outside are shared: one firewall
protects every machine behind it. Controls near the centre are specific: each application needs
its own permission checks, written and tested by whoever wrote it. A good design uses both,
because the outer layers are cheap per asset and coarse, and the inner ones are expensive and
precise.
