---
title: Validating live answers with Ajv
version: 1
---

**A schema does nothing until a validator reads it, and Ajv is the validator most JavaScript tools
are built on.** It compiles a schema into a function and runs answers through it, reporting every rule
an answer breaks. `ajv-formats` adds the checks for `format`, which Ajv leaves out unless asked. Both
come from npm, into the project lesson 6 gave a `package.json`:

```
ana@laptop:~/boxoffice$ npm install --save-dev --save-exact ajv@8.20.0 ajv-formats@3.0.1

added 5 packages, changed 2 packages, and audited 154 packages in 5s

23 packages are looking for funding
  run `npm fund` for details

19 vulnerabilities (7 moderate, 11 high, 1 critical)

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

## A short checker

The checker reads JSON from its standard input and a schema from the file it is given, so it works
with anything that can print JSON: curl, a saved file, another program.
Save it as `schemas/check.mjs`:

```js
// schemas/check.mjs: check JSON from standard input against a schema.
//   curl -s localhost:8080/v1/shows/sh-103 | node schemas/check.mjs schemas/show.json
import { readFileSync } from 'node:fs';
import Ajv2020 from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';

const schema = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const data = JSON.parse(readFileSync(0, 'utf8'));

const ajv = new Ajv2020({ allErrors: true });
addFormats(ajv);
const validate = ajv.compile(schema);

if (validate(data)) {
  console.log(`valid against ${schema.title}`);
} else {
  for (const e of validate.errors) {
    const where = e.instancePath || '(the whole body)';
    const which = e.params.additionalProperty ?? e.params.allowedValues?.join(', ');
    console.log(`${where} ${e.message}${which ? `: ${which}` : ''}`);
  }
  process.exit(1);
}
```

Three details carry the weight. **`Ajv2020` is the build for the 2020-12 draft**; the default `Ajv`
class reads draft-07 and would refuse the `$schema` line. `allErrors: true` reports every broken rule
instead of stopping at the first, which is what a person reading a failure wants. And **the exit
code is 1 on a failure**, so a shell script or a pipeline step can tell the difference without
reading the text.

boxoffice is running in its terminal, as in every lesson. The show it answers with:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | node schemas/check.mjs schemas/show.json
valid against Show
ana@laptop:~/boxoffice$ echo $?
0
```

Then a show made up to break every rule at once, to see what the messages look like:

```
ana@laptop:~/boxoffice$ echo '{"id":"sh-1","title":"","starts_at":"8/11 18h","price_cents":65.5,"seats_left":-1,"venue":"Sala 2"}' | node schemas/check.mjs schemas/show.json
(the whole body) must NOT have additional properties: venue
/title must NOT have fewer than 1 characters
/starts_at must match format "date-time"
/price_cents must be integer
/seats_left must be >= 0
ana@laptop:~/boxoffice$ echo $?
1
```

Each line names a field by its JSON Pointer, `/title` for the `title` at the top level, and the rule
it broke. The date, the fraction of a cent, the negative count, the empty title and the stray
`venue` are all there, which no single `assert` would have caught together.

## When the schema is wrong

Get a token, then place an order and check it:

```
ana@laptop:~/boxoffice$ TOKEN=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
```

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":2}' | node schemas/check.mjs schemas/order.json
valid against Order
```

Valid. Now cancel that order, which lesson 1's methods table said `DELETE` does, and check it again:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -X DELETE localhost:8080/v1/orders/ord-1001 -H "authorization: Bearer $TOKEN"
204
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders/ord-1001 -H "authorization: Bearer $TOKEN" | node schemas/check.mjs schemas/order.json
/status must be equal to one of the allowed values: confirmed, declined, failed
```

`204`, and then **the cancelled order breaks the schema**: `cancelled` is not among the allowed
statuses. The obvious reading is that boxoffice is wrong, and it is not. Lesson 2's `openapi.yaml`
lists `cancelled` among the statuses, and boxoffice's code sets it on purpose. The schema was written
from the answers of the create path, and the cancel path produces a value its author never saw.

**When a schema and an API disagree, decide which one is wrong before filing anything.** Read the
contract, read what the code is meant to do, and if both say the answer is right, the defect is in
the schema. Here it is a one-word fix. Add `"cancelled"` to the `enum` and
save it as `schemas/order.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://boxoffice.example/schemas/order.json",
  "title": "Order",
  "description": "One order, as POST /v1/orders and GET /v1/orders/{id} answer it.",
  "type": "object",
  "required": ["id", "show_id", "seats", "total_cents", "status"],
  "additionalProperties": false,
  "properties": {
    "id": { "type": "string", "pattern": "^ord-[0-9]+$" },
    "show_id": { "type": "string", "pattern": "^sh-[0-9]+$" },
    "seats": { "type": "integer", "minimum": 1, "maximum": 6 },
    "total_cents": { "type": "integer", "minimum": 0 },
    "status": { "enum": ["confirmed", "declined", "failed", "cancelled"] },
    "payment": { "type": "string" }
  },
  "if": { "properties": { "status": { "const": "confirmed" } } },
  "then": { "required": ["payment"] }
}
```

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders/ord-1001 -H "authorization: Bearer $TOKEN" | node schemas/check.mjs schemas/order.json
valid against Order
```

The other direction happens too, and is the reason schemas earn their keep: a field that comes back
as a string where the contract says integer, a `null` where a value is required, a field that should
never have left the server. All three are defects of the API, and each fails a schema in exactly the
way above.
