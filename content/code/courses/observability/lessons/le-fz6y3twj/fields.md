---
title: Fields: the names are the interface
version: 1
---

A structured line is only as useful as its field names are consistent. **The names are an
interface**, read by every query, dashboard and alert built on the logs, and they break the same way
an API breaks when somebody renames a field.

The failures are ordinary. One service writes `order_id`, another `orderId`, a third `order`, and a
search for one order finds a third of its lines. One service writes durations in milliseconds as
`duration_ms` and another in seconds as `duration`, and a query comparing them is off by a
thousand. One writes `level` and another `severity`. None of these is an error anybody sees; each
is a question that quietly returns less than it should.

The shop's answer is the cheapest there is: **one formatter, shared by every service**, so the
fields every line carries are written in one place. For the event's own fields, three rules hold
across the catalogue of this course:

- **Names in `snake_case`, and the unit in the name** when there is one: `duration_ms`,
  `amount_cents`, `size_bytes`.
- **The same name for the same thing everywhere**, and where OpenTelemetry already has a name, its
  name: `trace_id`, `span_id`, and the semantic conventions' attribute names when a log line
  describes an HTTP call or a query.
- **Values of one type per field**: `order_id` is always a number, never sometimes `"none"`. A
  backend that indexes fields, as lesson 9's Elasticsearch does, decides a field's type from the
  first value it sees and refuses or drops the lines that disagree.

OpenTelemetry has its own **log data model**, with a body, a severity, attributes and the trace
context as fields of the record, and the Collector maps the shop's JSON into it on the way in:
lesson 1's Loki query found the lines by `service_name` because the Collector copied the `service`
field into the resource. A service that logs through OpenTelemetry's logging bridge produces that
model directly; one that prints JSON, as the shop does, relies on the pipeline to map it, and both
end in the same place.
