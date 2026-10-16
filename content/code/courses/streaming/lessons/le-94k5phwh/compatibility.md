---
title: Compatibility, and the registry saying no
version: 1
---

**A compatibility mode is a rule the registry applies to every new version of a subject before it
accepts it: can the new schema and the old one read each other's data, and in which direction?** It
is checked once, when the version is offered, and never again. That is the whole point: the
argument about whether a change breaks a reader happens at registration, in one place, instead of
in every consumer on the morning after a deploy.

The modes are named for the direction they protect:

| mode | the new schema must be able to… | what it allows |
|---|---|---|
| `BACKWARD` | read data written with the previous version | add a field **with a default**; remove a field |
| `FORWARD` | be read by a reader still on the previous version | add a field; remove a field **that had a default** |
| `FULL` | both | add or remove only fields with defaults |
| `NONE` | nothing is checked | anything |

Each has a `_TRANSITIVE` variant that checks the new version against **every** earlier one rather
than only the last. The difference shows over three steps: removing a field in version 2 and adding
it back with another type in version 3 passes two checks against the previous version each, and
leaves version 3 unable to read version 1.

## The default is not the same everywhere

Confluent's registry starts every subject at `BACKWARD`. Apicurio's Confluent-compatible API does
not, as the first command shows; the second sets the mode for this lesson's subject:

```
ubuntu@stream:~/work$ curl -s localhost:8080/apis/ccompat/v7/config; echo
{"compatibilityLevel":"NONE"}
ubuntu@stream:~/work$ curl -s -X PUT -H 'Content-Type: application/vnd.schemaregistry.v1+json' --data '{"compatibility": "BACKWARD"}' localhost:8080/apis/ccompat/v7/config/sales-avro-value; echo
{"compatibility":"BACKWARD","normalize":false}
```

**`NONE` means the registry you started in this lesson accepts any change at all** until it is told
otherwise, which is the reason the first thing to do with a new subject is to set its mode. The
`PUT` above set `BACKWARD` for `sales-avro-value` alone; without the subject's name at the end of
the address it would have changed the default for every subject.

## A change it accepts

The tills are to report which till rang up each sale. `jq` writes a version 2 of the schema with a
`till` field and a default, for the sales written before the field existed. Then the producer tries
to send with it, and the version is offered to the registry:

```
ubuntu@stream:~/work$ jq '.fields += [{"name": "till", "type": "string", "default": "unknown"}]' sale.avsc > sale-v2.avsc
ubuntu@stream:~/work$ python avro_tills.py --schema sale-v2.avsc --count 1 2>&1 | tail -1
confluent_kafka.schema_registry.error.SchemaRegistryError: The given schema does not match any schema under the subject sales-avro-value (HTTP status code 404, SR code 40403)
ubuntu@stream:~/work$ ./register.sh sales-avro-value sale-v2.avsc
{"id":2}
```

The producer would not send with version 2 yet: with `auto.register.schemas` off, a schema the
registry does not have is a 404, and the sale is never written. Registering it is a separate,
deliberate step, and the registry checked it against version 1 under `BACKWARD` before giving it id 2. A new field with a default passes, because a reader on version 2 can fill `till` with `unknown`
for every sale written before it existed.

## A change it refuses

Now the rename from the first section of this lesson, `cents` to `amount`, as a schema:

```
ubuntu@stream:~/work$ jq '.fields[4].name = "amount"' sale.avsc > sale-renamed.avsc
ubuntu@stream:~/work$ ./register.sh sales-avro-value sale-renamed.avsc
{"message":"io.apicurio.registry.rules.violation.RuleViolationException: Incompatible artifact: sales-avro-value [AVRO], num of incompatible diffs: {1}, list of diff types: [amount at /fields/4]","error_code":409}
ubuntu@stream:~/work$ curl -s localhost:8080/apis/ccompat/v7/subjects/sales-avro-value/versions; echo
[1,2]
```

**409, Conflict**, and the subject still has only versions 1 and 2. The message names the field the
check stopped on, `amount`, at position 4 of the field list.

To Avro, a rename is two changes: `cents` removed and `amount` added. Removing is allowed under
`BACKWARD`; adding a field **with no default** is not, because a reader on the new schema cannot
fill `amount` from a sale written before it existed. The registry said so before a single message
was written, which is the difference between this run and the Monday at the start of the lesson.

If a field really has to be renamed, there are two honest ways. One is the alias from the Avro
section, with a default on the new name, which is a change in **both** schemas and an order of
upgrade, as the next section explains. The other is a new field beside the old one, written by the
producers for a while and read by the consumers when they are ready, with the old one removed only
when nothing reads it. Slower, and it never breaks anybody.
