---
title: Exporters: metrics for things that have none
version: 1
---

The shop's services publish their own metrics because the course wrote them to. A Linux machine, a
PostgreSQL database or a website you do not own publishes nothing in Prometheus's format. **An
exporter is a small program that asks such a thing about itself and answers Prometheus's scrape with
the result.** It asks in whatever way the thing can be asked. The lab runs three, and RabbitMQ has
one built in:

| target | what it translates | how it asks |
|---|---|---|
| `node-exporter` | the Linux machine: processors, memory, disks, network | reads `/proc` and `/sys` |
| `postgres-exporter` | PostgreSQL | runs queries against its statistics views |
| RabbitMQ's own plugin | queues, connections, messages | from inside the broker |
| `blackbox-exporter` | the storefront, from outside | sends a request and times it |

One metric from each:

```
ana@obs:~/shop$ ./promq 'node_load1'
__name__=node_load1 instance=node-exporter:9100 job=node  0.5
ana@obs:~/shop$ ./promq 'pg_up'
__name__=pg_up instance=postgres-exporter:9187 job=postgres  1
ana@obs:~/shop$ ./promq 'rabbitmq_queue_messages_ready'
__name__=rabbitmq_queue_messages_ready instance=rabbitmq:15692 job=rabbitmq  0
ana@obs:~/shop$ ./promq 'probe_success'
__name__=probe_success instance=http://storefront:8080/health job=blackbox  1
```

The machine's load average over the last minute, the database answering, an empty queue, and the
outside probe succeeding. **The last one is different in kind.** The other three report what a
system says about itself. The blackbox exporter acts like a client and reports what it experienced,
broken down by phase:

```
ana@obs:~/shop$ ./promq 'probe_http_duration_seconds'
__name__=probe_http_duration_seconds instance=http://storefront:8080/health job=blackbox phase=connect  0.000294823
__name__=probe_http_duration_seconds instance=http://storefront:8080/health job=blackbox phase=processing  0.001231325
__name__=probe_http_duration_seconds instance=http://storefront:8080/health job=blackbox phase=resolve  0.000709531
__name__=probe_http_duration_seconds instance=http://storefront:8080/health job=blackbox phase=tls  0
__name__=probe_http_duration_seconds instance=http://storefront:8080/health job=blackbox phase=transfer  0.000096116
```

Resolving the name, connecting, the server's processing and the transfer, each a few tenths of a
millisecond on one machine, and no TLS because the lab speaks plain HTTP inside. **A probe from
outside catches what no internal metric can**: a service that reports itself healthy while the load
balancer in front of it sends nobody there. Lesson 14 comes back to it.

For almost anything a team runs there is already an exporter, written by the project or by the
community, and the first question about a new component is which one. Writing an exporter is the
last resort, and it is rarely more than a loop that asks and a page that answers.
