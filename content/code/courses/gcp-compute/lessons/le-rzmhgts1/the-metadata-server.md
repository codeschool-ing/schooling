---
title: The metadata server
version: 1
---

Every Compute Engine machine can reach an address that belongs to no network you created:
`169.254.169.254`, also known by the name `metadata.google.internal`. **It is answered by the
host the machine runs on, and it is how the machine learns everything about itself**: its name,
its zone, the attributes you set, and the access token of its service account. The startup script
in the last section asked it two questions; this section is about what else it answers and what it
refuses.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Inside the host, the metadata server at 169.254.169.254 holds three kinds of value: project attributes, instance attributes and the service account's token. A process on the instance sends a GET with the header Metadata-Flavor: Google and receives the value. A request without the header is refused with 403. Nothing outside the host can reach the address.\"><defs><marker id=\"md7-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"16\" width=\"688\" height=\"298\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">the host</text><rect x=\"40\" y=\"56\" width=\"250\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"165.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">metadata server</text><text x=\"165.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">169.254.169.254</text><rect x=\"40\" y=\"128\" width=\"250\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"165.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">project attributes</text><rect x=\"40\" y=\"172\" width=\"250\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"165.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">instance attributes</text><rect x=\"40\" y=\"216\" width=\"250\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"165.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the service account's token</text><rect x=\"440\" y=\"56\" width=\"240\" height=\"194\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">the instance</text><rect x=\"470\" y=\"100\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"560.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a process</text><text x=\"560.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">curl, an SDK, the agent</text><path d=\"M470 116 L292 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#md7-ah)\"></path><text x=\"381\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Metadata-Flavor: Google</text><path d=\"M292 98 L470 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#md7-ah)\"></path><text x=\"381\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the value</text><rect x=\"470\" y=\"190\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"560.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">a request with no header</text><path d=\"M470 210 L380 210\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#md7-ah)\"></path><text x=\"330\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">403</text><text x=\"360\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing outside the host can reach the address</text></svg>", "caption": "One address per machine, answered by the host it runs on. The header is the price of every answer; the token is the most valuable thing behind it."}
```

## Asking it

Every value has a path under `/computeMetadata/v1/`, in two trees. `project/` holds what applies to
every machine in the project, such as `project/project-id` and the project-wide attributes under
`project/attributes/`. `instance/` holds what belongs to this one: `instance/name`,
`instance/zone`, `instance/network-interfaces/0/ip`, the attributes you set under
`instance/attributes/`, and `instance/service-accounts/`, which the next section opens.

**Every request must carry the header `Metadata-Flavor: Google`**, and every answer carries it
back. Google's documentation says a request without the header is refused with `403 Forbidden`,
and so is any request carrying `X-Forwarded-For`, the header a proxy adds when it passes a request
on. Two query parameters are worth knowing. `?recursive=true` returns a whole tree as JSON instead
of one value. `?wait_for_change=true` makes the request wait until the value changes, so a script
can react to a new attribute without asking every few seconds; it is how the guest environment
itself notices a new SSH key.

From your laptop the address leads nowhere, which is easy to confirm:

```
ana@laptop:~/gcp/meta$ curl -sS -m 5 -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/project/project-id; echo "exit status $?"
curl: (7) Failed to connect to 169.254.169.254 port 80 after 0 ms: Couldn't connect to server
exit status 7
```

This lab has no route at all to `169.254.169.254`, so `curl` failed at once with status 7. On a
laptop on an ordinary network, the same request usually waits until its five-second timeout
instead, because nothing answers; either way the answer is the same. Everything else in this
section is Google's documented behaviour and was not run.

## Why the header exists

The header is Google's answer to one class of bug, **server-side request forgery**. A great deal
of software on a server will fetch an address somebody else chose: an application that downloads
a picture from a URL the user typed, a webhook sender, a PDF renderer following links. Point one
of them at `http://169.254.169.254/...` and it makes the request from inside the machine, where
the metadata server will answer it.

What such software can rarely do is add a header of the attacker's choosing. So the server refuses
any request without `Metadata-Flavor: Google`, and the forged fetch gets a `403` instead of the
service account's token. The `X-Forwarded-For` rule closes the other common route: a reverse
proxy on the machine, tricked into forwarding a request to the metadata address, adds that header
on its way through and is refused for it.

**The header is a filter, not a lock.** Software the attacker controls completely, a shell on the
machine or a dependency that turned malicious, sends the header like anything else and gets the
token. Nothing on the machine is protected from the machine itself, which is why the next two
sections are about making the token worth as little as possible.

## Values worth not putting there

Metadata is readable by every process on the machine and by everybody with permission to view the
instance, and it appears in a Terraform plan word for word, as the last section showed. So it is
the right place for the shop's environment name and the wrong place for a database password. A
secret belongs in Secret Manager, fetched at boot with the machine's own identity; `gcp-operations`
covers it.
