---
title: Application events, sent at least once
version: 1
---

**An application event is a record the app sends on purpose, one for each thing a person did, and it
arrives at least once rather than exactly once.** The app's database keeps the state of things: this
ride is open, this customer has this card. Events keep the actions, including the ones that change
nothing in any database. A customer opened the map, looked at Batel, saw no bicycles and closed the
app. No row anywhere records that, and it is exactly what Marta wants to know when she asks where
demand goes unmet.

The app's developers decide which events exist and add a line to the app for each one. When something
happens, the app builds a small JSON object and sends it to a collector, a service whose only job is to
receive events and write them down. Products such as Snowplow and Segment do this work, and some teams
build their own. A ride being started looks something like this:

```json
{
  "event_id": "5f0c2a9e-3b71-4c55-9d0e-7a1f6c2b8e40",
  "name": "ride_started",
  "occurred_at": "2025-09-15T08:03:12-03:00",
  "customer_id": "C0412",
  "app_version": "3.4.0",
  "properties": {"station": "ST02", "bike_id": "B017"}
}
```

## Names agreed before they are sent

The list of events, their names and the fields each one carries is called a **tracking plan**, and it
is a document the product team and the data team agree on before a line of the app is written. Without
one, each developer names events as they please. Version 3.3 of the app sends `rideStarted`, version
3.4 sends `ride_started`, and both are in the data at once, because customers do not all update on the
same day. Every count of rides started is then wrong in a way that depends on how many phones are still
on 3.3. An event has a schema like a table does; it is just written down somewhere else, if it is
written down at all, and lesson 5 is about where a schema lives.

## Why the same event arrives twice

A phone sends an event, the collector writes it down and answers "received". If that answer is lost,
on a bus going under a bridge or in a lift, the phone cannot tell a lost answer from a lost event, so it
sends the event again. The alternative is worse: a phone that never resent anything would lose every
event sent into a dead connection. So the app is built to resend until it hears back, which is called
**at-least-once delivery**, and its price is that some events are written down twice.

The two copies are identical, including `event_id`, a random identifier the phone gave the event when
it was created. That field is what makes the duplicate removable: two events with one id are one
event. Without it, two `ride_started` events from one customer a second apart could be a retry or a
customer who tapped twice, and nobody can say which. **Ask for the id before the first event is sent**,
because it cannot be added to events already collected. Lesson 8 names the delivery guarantees and what
each one costs.

## Two clocks on every event

`occurred_at` comes from the phone's clock. The collector adds its own time, when the event reached it.
They differ for two reasons, and both are normal:

- **The phone was offline.** Events made in a tunnel are kept on the phone and sent when it reconnects,
  minutes or days later. An event for Monday can arrive on Wednesday, after Monday's numbers were
  published.
- **The phone's clock is wrong.** It belongs to the customer, who can set it to anything. An event
  that occurred, by the phone's account, in 2031 is a real thing a collector receives.

Keep both times. The phone's is the one the question is usually about, and the collector's is the one
you can trust; which to use, and what to do with an event that arrives after its day was counted, are
lesson 8's subject.
