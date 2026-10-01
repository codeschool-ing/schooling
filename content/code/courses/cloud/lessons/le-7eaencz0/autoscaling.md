---
title: "Autoscaling groups: a number the provider keeps true"
version: 1
---

Autoscaling is usually introduced as "the cloud adds servers when traffic goes up". That is one
thing it does, and not the first. **An autoscaling group is a promise about a number**: there will
be this many healthy instances, launched from this template, and when reality disagrees the group
changes reality until it agrees again. Adding machines for traffic is that promise with a number
that moves.

## Three numbers and a template

A group is defined by three counts and a launch template.

- The minimum is the fewest instances the group will ever run, whatever the load.
- The maximum is the most, whatever the load. It is a ceiling on capacity and on the bill.
- The desired count is the number the group is working towards right now, always between the
  two. You can set it, and the scaling policies of the next section change it.

The launch template is the answer to "what does one instance look like", written down once as the
launch section described: the image, the type, the security groups, the user data. When the group
needs a machine it launches one from the template, and it never logs into one to fix it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"An Auto Scaling group with minimum 2, desired 3 and maximum 6, spread over two availability zones. A launch template feeds it. In zone a one instance is healthy and one has failed its health check and is being terminated; a replacement is launched from the template. Zone b holds one healthy instance. Dashed slots show room up to the maximum.\"><defs><marker id=\"asg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"108\" width=\"150\" height=\"124\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"91\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">launch template</text><text x=\"30\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">image</text><text x=\"30\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">instance type</text><text x=\"30\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">security group</text><text x=\"30\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">user data</text><rect x=\"196\" y=\"14\" width=\"508\" height=\"304\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"212\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Auto Scaling group</text><text x=\"688\" y=\"34\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">min 2   desired 3   max 6</text><rect x=\"212\" y=\"52\" width=\"230\" height=\"254\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"224\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">zone a</text><rect x=\"462\" y=\"52\" width=\"230\" height=\"254\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"474\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">zone b</text><rect x=\"228\" y=\"84\" width=\"96\" height=\"60\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">healthy</text><rect x=\"334\" y=\"84\" width=\"96\" height=\"60\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"382\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">failed check</text><text x=\"382\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">terminated</text><rect x=\"228\" y=\"196\" width=\"202\" height=\"56\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"329\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">replacement</text><text x=\"329\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">from the template</text><path d=\"M382 144 L382 190\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#asg-ah)\"></path><path d=\"M166 224 L222 224\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#asg-ah)\"></path><rect x=\"478\" y=\"84\" width=\"96\" height=\"60\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"526\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">healthy</text><rect x=\"588\" y=\"84\" width=\"96\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"478\" y=\"196\" width=\"96\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"588\" y=\"196\" width=\"96\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"636\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">room up to max</text></svg>", "caption": "The group holds a number, not a set of machines. When an instance fails its health check the group terminates it and launches another from the template, so the count goes back to desired; the zones are where it spreads them, which lesson 9 explains."}
```

## Health checks and replacement

Every so often the group asks whether each instance is healthy, and it has two ways of asking.

The provider's own check asks whether the virtual machine is running and reachable from the host:
whether it booted, whether the hypervisor can see it. It catches a crashed kernel or a failed host.
It does not catch a web server that has stopped answering on a machine that is otherwise fine.

A **load balancer's check** asks the application. The load balancer in front of the group, which
lesson 6 builds, requests a path such as `/health` on each instance, and an instance that stops
answering with a success is marked unhealthy. That is the check that sees what your users see, and
a group serving web traffic should use it.

**An unhealthy instance is not repaired, it is replaced.** The group terminates it and launches a
new one from the template, and the count is back where it was. Nobody is paged to log in, because
there is nothing on the old machine worth logging in for, which is exactly the property the last
section of this lesson insists on.

One setting stops this from going wrong in the obvious way. A new instance takes a while to boot
and run its user data, and during that time it fails its health check because it is not serving
yet. The **grace period** tells the group to ignore health checks for a while after launch; set too
short, a group kills every new instance before it finishes starting and launches another, forever.

## Spread across zones

A group can be given subnets in more than one availability zone, and it spreads its instances
across them and keeps them balanced. If a zone fails, the instances there fail their checks, and
the group launches their replacements in the zones that are still working. Lesson 9 says what a
zone is and why two of them rarely fail together; for now the point is that the group does the
spreading, so a single `SubnetId` chosen by hand is no longer the thing that decides where your
machines run.

**A group of one is useful too.** With minimum, desired and maximum all set to 1, a group never
scales, but it replaces its only instance when that instance fails a check. It is the cheapest way
to get a machine that comes back on its own, provided, again, that nothing on it needs to survive.
