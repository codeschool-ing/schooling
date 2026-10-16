---
title: The interface in your subnet, before 2019 and after
version: 1
---

For a function to have an address in your subnet, something has to sit in that subnet holding
the address: an elastic network interface, the same kind of object an EC2 instance's network card
is. **What changed in September 2019 is who that interface belongs to and when it is made**, and
the advice "keep Lambda out of VPCs" comes from the arrangement before it.

## One interface per environment

Until 2019, every execution environment of a function in a VPC got an interface of its own, and it
got it during its cold start. Creating an interface and attaching it took seconds, often ten or
more, and that wait was added to every cold start of every function in a VPC on top of the init
phase lesson 17 measured. A burst that started fifty environments created fifty interfaces.

That arrangement failed in three ways, and teams met all of them:

- **the cold start**, seconds long, on exactly the requests that arrived during a burst;
- **the subnet's addresses**, one per environment: a `/24` subnet has 251 usable addresses on AWS,
  and a function scaling to 300 environments in it simply ran out, with the rest of the subnet's
  machines competing for the same addresses;
- **the account's interface quota**, shared with every EC2 instance in the Region, which a
  scaling function could exhaust for everything else.

## One shared interface per subnet and security group

Since the change, Lambda uses **Hyperplane interfaces**, built on the same network virtualisation
AWS uses for NAT gateways and Network Load Balancers. An interface is created for each
combination of subnet and security group that a function names, **when the function is created or
its VPC configuration changes**, and every execution environment of the function in that subnet
reaches the VPC through it. Functions that share the same subnet and security group combination
share the interface too. The interface lives in your account, in your subnet, and Lambda owns it:
it appears in your list of network interfaces with Lambda as the requester, and you cannot detach
or delete it yourself.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two panels side by side. Before 2019: four execution environments in a subnet, each with its own network interface, created during its cold start. Since 2019: the same four environments all connected to one shared Hyperplane interface for that subnet and security group, created when the function is configured.\"><defs><marker id=\"en-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"16\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Before 2019</text><text x=\"16\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one interface per environment</text><rect x=\"16\" y=\"52\" width=\"332\" height=\"196\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"28\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">private subnet</text><rect x=\"28\" y=\"84\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"88\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">environment 1</text><path d=\"M150 99 L212 99\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"216\" y=\"84\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">its own ENI</text><rect x=\"28\" y=\"124\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"88\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">environment 2</text><path d=\"M150 139 L212 139\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"216\" y=\"124\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">its own ENI</text><rect x=\"28\" y=\"164\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"88\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">environment 3</text><path d=\"M150 179 L212 179\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"216\" y=\"164\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">its own ENI</text><rect x=\"28\" y=\"204\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"88\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">environment 4</text><path d=\"M150 219 L212 219\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"216\" y=\"204\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"276\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">its own ENI</text><text x=\"16\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">created during each cold start</text><text x=\"16\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">seconds per cold start, one address each</text><text x=\"372\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Since 2019</text><text x=\"372\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one shared interface per subnet and security group</text><rect x=\"372\" y=\"52\" width=\"332\" height=\"196\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"384\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">private subnet</text><rect x=\"384\" y=\"84\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">environment 1</text><path d=\"M506 99 L568 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"384\" y=\"124\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">environment 2</text><path d=\"M506 139 L568 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"384\" y=\"164\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">environment 3</text><path d=\"M506 179 L568 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"384\" y=\"204\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">environment 4</text><path d=\"M506 219 L568 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#en-ah)\"></path><rect x=\"572\" y=\"140\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"632\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">Hyperplane ENI</text><text x=\"632\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">shared</text><text x=\"372\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">created when the function is configured</text><text x=\"372\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing at cold start, few addresses</text></svg>", "caption": "What changed in 2019. An interface per environment made every cold start in a VPC wait for one to be created, and used a subnet address per environment. A Hyperplane interface is created once, when the function is configured, and every environment of that subnet and security group shares it."}
```

The consequences are the reverse of the old ones. **A cold start inside a VPC no longer waits for
a network interface**, because the interface was there before the first request. A burst of three
hundred environments uses the same few addresses it used for one. And the work of creating the
interface moved to deployment: on AWS a function whose VPC configuration has just been set is in
the state `Pending` while its interfaces are created, which can take a minute or more, and its
invocations fail until it is `Active`. A deployment pipeline that invokes a function immediately
after changing its subnets should wait for that state.

Two more behaviours from AWS's documentation, both of which surprise teams that never read it:

- **An idle function loses its interfaces.** If a function in a VPC is not invoked for some weeks,
  Lambda reclaims the unused Hyperplane interfaces and marks the function `Inactive`. The next
  invocation fails while they are recreated and the function returns to `Active`. A monthly job in
  a VPC meets this every month.
- **Deleting the security group or the subnet waits for Lambda.** The interface still exists for a
  while after the function that used it is deleted or moved, and the group or subnet it sits in
  cannot be deleted until Lambda has removed it.

## What moto shows of this, which is nothing

moto keeps the configuration and creates no interface. The function from the previous section is
in two subnets with one security group, and on AWS that is two Hyperplane interfaces, one per
subnet. Ask moto for the account's network interfaces:

```
@@CAP:enis@@
```

The list is empty. moto records a function's `VpcConfig` and does nothing with it, so the
interfaces, the `Pending` state and the reclaiming of idle ones are all AWS's documented behaviour
here, and none of it was run. The next section creates an interface endpoint, and there moto does
create interfaces in the subnets, which makes the absence above easy to see beside it.

**The cost the title of this lesson mentions is the cold start of before 2019, and it is gone.** A
function in a VPC today starts as fast as one outside it. What remains is the cost of the way out,
and that one is billed.
