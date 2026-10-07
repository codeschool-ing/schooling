---
title: What the architect owns in operations
version: 1
---

An architect's design is judged twice: once when it is built, and for years afterwards by the people who run it. Most of what makes a system pleasant or miserable to operate is decided in the design, which is why ITIL's practices are an architect's concern even though the architect rarely runs any of them.

## Designing for incident management

Restoring service quickly depends on decisions made long before the first incident:

- **Can the system tell you it is broken?** Health checks, meaningful logs and metrics of what users experience — the subject of the `observability` course — decide whether an incident is detected by monitoring or by a clinic phoning the help desk.
- **Can it be restored without a fix?** Rolling back a deployment, switching to a standby, disabling a feature with a flag: each is a workaround that has to be designed in.
- **Can it fail in parts?** A booking system where a failure in SMS reminders also stops bookings has turned a priority 4 into a priority 1.

## Designing for change enablement

A change is cheap and safe when the system allows small, reversible, automatically tested deployments. An architecture that can only be deployed as one unit, at night, with a manual database migration, forces every change into the normal route of this lesson's fifth section and makes the change board necessary. Designing for frequent, independent deployment is designing for standard changes.

## Designing for service levels

An availability target is an architectural requirement. **99.5%** of the fourteen-hour daily booking window over a thirty-day month — 420 hours — allows **126 minutes** of unavailability in the month; it rules out a design with a weekly hour of planned downtime. Before an SLA is signed, the architect is the person who can say whether the system, the hosting and the suppliers can meet it, and what it would cost to meet a stricter one.

## Operational readiness

Many organisations require a **service transition** or **operational readiness** review before a new system goes live: is there a runbook, are the alerts defined, who is on call, what are the known errors, how is it backed up and restored. An architect who treats that review as a checklist to pass at the end will find it full of design decisions that are too late to change. Writing the answers as part of the design, from the first iteration, is the operational equivalent of putting non-functional requirements in the Definition of Done.
