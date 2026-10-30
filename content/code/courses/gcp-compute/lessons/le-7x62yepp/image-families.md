---
title: Families, deprecation and the image you will get
version: 1
---

A family is the reason a boot disk created on Monday and another created on Friday can differ
without anybody changing a line. **A family always points to its newest image that is not
deprecated, and that pointer moves every time a new image is published into it.** That is a
feature when you want security patches and a hazard when you want two machines to be identical.

## The pointer, and what moves it

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The family shop-web on the left, with an arrow to the image shop-web-v2. Three images stand in a row by age: shop-web-v1, deprecated; shop-web-v2, active; shop-web-v3, the newest, deprecated after it broke something. The family skips v3 and points at v2, so every new boot disk is made from v2.\"><defs><marker id=\"l2f-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"24\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">older</text><text x=\"696\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">newer</text><path d=\"M250 30 L470 30\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"40\" y=\"150\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop-web</text><text x=\"115.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the family</text><rect x=\"230\" y=\"60\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"300.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop-web-v1</text><text x=\"300.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DEPRECATED</text><rect x=\"390\" y=\"60\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop-web-v2</text><text x=\"460.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ACTIVE</text><rect x=\"550\" y=\"60\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"620.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop-web-v3</text><text x=\"620.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DEPRECATED</text><path d=\"M190 165 L455 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2f-ah)\"></path><text x=\"560\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">newest, but it broke</text><text x=\"560\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">something: skipped</text><text x=\"300\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">every new boot disk is made from v2</text></svg>", "caption": "A family points to its newest image that is not deprecated. Deprecating a bad build moves the pointer back, which is the rollback."}
```

Every image carries a **deprecation state**, and the state is what the family reads. The four states
are documented in gcloud's own help, which works without an account:

```
ana@laptop:~/gcp$ gcloud compute images deprecate --help | sed -n '/^     --state=STATE/,/^OPTIONAL/p'
     --state=STATE
        The deprecation state to set on the image. STATE must be one of:

         ACTIVE
            The image is currently supported.
         DELETED
            New uses result in an error. Setting this state will not
            automatically delete the image. You must still make a request to
            delete the image to remove it from the image list.
         DEPRECATED
            Operations which create a new DEPRECATED resource return
            successfully, but with a warning indicating that the image is
            deprecated and recommending its replacement.
         OBSOLETE
            New uses result in an error.

OPTIONAL FLAGS
```

**Note what the help says about `DELETED`**: setting a state does not remove an image. The image
stays, and keeps being billed for its storage, until somebody deletes it. Deprecation is a label
for the people and tools that read it, and the family is one of those tools.

So a family moves in two ways. Publishing a newer image into it moves the pointer forward, and
deprecating the newest image moves it back to the one before. The second is the rollback: if
Friday's image breaks something, marking it `DEPRECATED` makes every new machine boot Thursday's
again, without editing any template.

## Pinning, or following

Two habits come out of this, and a team has to choose one per environment:

- **Follow the family** in development, so every new machine gets the latest patches without
  anybody remembering to look.
- **Pin the dated name** where two machines must be identical: in a managed group, where lesson 4
  shows that an instance template fixes its image, and wherever an incident report needs to say
  exactly what was running.

The pin costs a decision every time a new image is published, which is the work the family saves.
The family costs the certainty that two machines are the same, which is what the pin buys. Neither
is free, and neither is wrong.

## Your own families

A family is not only for public images. When you build your own, as section 04 shows, giving every
build the same family turns it into a release channel: `shop-web` points to the newest build of the
shop's web image, deprecating a bad build rolls it back, and an instance template can name
`projects/planner-dev/global/images/family/shop-web` the way it names `debian-cloud/debian-12`.
The command that does the rollback is `gcloud compute images deprecate` with `--state=DEPRECATED`;
it needs an account and is not run here.
