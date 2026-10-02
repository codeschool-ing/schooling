---
title: Comparing the four, and when an agent earns its place
version: 1
---

Lesson 18 and this one have now shown the same small job four times: a directory, a page, a
configuration file, and something that runs only when the configuration changes. **Under the different
syntax, all four tools share one model**: resources with a desired state, a run that checks each one and
acts only where it differs, and a way to say that one resource depends on another. What differs is
everything around that model.

| | Ansible | Puppet | Chef | Salt |
|---|---|---|---|---|
| written in | YAML, with Jinja | Puppet's own language | Ruby | YAML, with Jinja |
| on each machine | nothing but SSH and Python | an agent | an agent, `chef-client` | an agent, the minion |
| who starts a run | the control machine, when somebody runs it | the agent, every 30 minutes by default | the client, on a timer | the master, at once; or the minion |
| order | the tasks, as written | a graph of relationships, then the manifest | the resources, as written | the file, unless a requisite says otherwise |
| without a server | it never needs one | `puppet apply` | `chef-client --local-mode` | `salt-call --local` |
| "only when that changed" | a handler | `notify` and `refreshonly` | `notifies` | `onchanges` |

Two rows deserve a sentence each.

**Who starts a run** is the row that changes how a team works, for the reasons in the first section of
this lesson: an agent corrects drift on its own schedule, including the drift somebody meant. **Order**
is the row that changes how a description is read. In Ansible and Chef, top to bottom is the truth. In
Puppet, the relationships are, and top to bottom is only a fallback. Salt numbers states in file order
and lets requisites move them.

The companies behind them have changed hands, which matters when you look for documentation, support or
a licence. Chef has belonged to Progress Software since 2020. Puppet was bought by Perforce in 2022.
SaltStack was bought by VMware in 2020, and VMware by Broadcom, so Salt now sits there. Ansible belongs
to Red Hat, which is part of IBM.

## When an agent earns its place

Start from what the machines are. **Long-lived machines that are repaired rather than replaced are where
an agent pays for itself**: hundreds of servers that must stay as described for years, under an audit
that asks for proof, are kept right by something that checks every half hour and reports what it fixed.
If you join a team that runs Puppet, Chef or Salt, that is the likely reason, and recognising the model
is the skill you need there.

Where machines are short-lived the argument turns round. A machine that is replaced, not edited, has
little time to drift and nobody to log in and edit it, and configuration moves into the image it is
built from. That is lesson 20, with Packer, and it is the immutable side of the trade lesson 1 set out.
For the configuration that is still needed at boot or on a few long-lived hosts, an agentless tool run
from a pipeline is lighter: nothing to install, no server, no certificates. That is why lesson 18
teaches Ansible and this lesson only shows the others.

What carries across, whichever tool a job puts in front of you, is the set of questions from this
lesson: what does a resource declare, what does a run do when it already matches, what happens to a
hand edit, and who decides the order.
