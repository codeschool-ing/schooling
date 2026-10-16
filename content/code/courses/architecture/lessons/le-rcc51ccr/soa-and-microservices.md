---
title: SOA and microservices, side by side
version: 1
---

Microservices are often described as "SOA done right", which is close enough to be misleading. Both
build a system out of services with contracts. **They differ in where the intelligence lives, who
owns what, and how big the moving parts are**, and each difference is a reaction to something that
hurt.

| | SOA as it was practised | microservices |
| --- | --- | --- |
| scope | integrating existing applications across a whole enterprise | building one system out of independently deployable parts |
| where the logic is | often in the bus: routing, transformation, orchestration | in the services; the pipe only carries |
| data | services often fronted a shared enterprise database | each service owns its data |
| contracts | WSDL and SOAP, heavy and strongly typed | usually HTTP with JSON, or a binary protocol such as gRPC, or events |
| governance | central: an integration team and a service registry | per team, with shared platform conventions |
| deployment | services released on the enterprise's schedule | each service on its own team's schedule |

Two of those rows are the lesson of SOA for anyone building services today.

**Keep the pipe dumb.** A queue, a load balancer and a gateway are fine; lesson 19 has a gateway in
it. The moment a piece of middleware starts holding business rules, every team depends on the team
that owns it, and the middleware becomes the release train lesson 1 described.

**Own the data.** A service that is a thin wrapper over a table everybody else also reads is not a
boundary; it is an extra hop in front of the same coupling.

## Orchestration and choreography

The ESB's habit of running a process as a central flow has a name, **orchestration**: one component
knows the steps and tells each service what to do, in order. The alternative is **choreography**:
each service reacts to events from the others and nobody holds the whole flow. Both are legitimate
in a system of microservices, and lesson 14 builds a saga each way. The difference from the ESB is
not that orchestration is forbidden. It is that **the orchestrator is a service owned by the team
that owns the process**, not a shared product owned by somebody else.
