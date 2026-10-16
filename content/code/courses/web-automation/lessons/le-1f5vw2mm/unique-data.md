---
title: A name nobody else has
version: 1
---

**The cure for the fixed name is a name that cannot already exist.** If every run of every test
makes up a new customer, no earlier run and no other test can have taken it, and the test stops
depending on history. The work is choosing where the uniqueness comes from, because there are
several obvious sources and two of them are not unique in the way that matters.

The common wrong idea is that a *different* value per test is enough. Different from what is the
question: from the other tests running at the same moment, or from every run that has ever touched
this server? The first is uniqueness in space, the second uniqueness in time, and the fixed-name
failure in the last section was a failure in time.

## Four candidates, printed

Playwright hands every test a `testInfo` object, the second argument of the test function, and two
of its fields look like identities. Node gives you the other two: the clock, and
`crypto.randomUUID()`, which returns 122 random bits written as a UUID. A test that prints all
four, so you can compare them across workers and across runs. Save it as `tests/names.spec.js`:

```javascript
import { test } from '@playwright/test';
import { randomUUID } from 'node:crypto';

// Prints four candidates for a unique name, to compare across runs.
test('four ways to make a name', async ({}, testInfo) => {
  console.log(`worker ${testInfo.workerIndex}  test ${testInfo.testId}  time ${Date.now()}  uuid ${randomUUID()}`);
});
```

`--repeat-each 2` runs the test twice in the same run, and `--workers 2` lets the two copies run
at the same time in two worker processes, which is what two tests in a real suite do. Run it, then
run it again:

```
%%CAP names%%
```

Read it column by column.

| source | unique between workers? | unique between runs? | what else it tells you |
|---|---|---|---|
| `testInfo.workerIndex` | yes, while they run | **no**: 0 and 1 come back every run | which worker, nothing about the test |
| `testInfo.testId` | yes, even for two copies of one test | **no**: the same two ids come back | which test made the data, if you keep a map |
| `Date.now()` | almost: the two copies were 13 ms apart, and could have shared a millisecond | yes, the clock moves on | **when** it was made, which helps when reading a database later |
| `randomUUID()` | yes | yes | nothing; it is noise to a person |

The first two are built for a different job. `workerIndex` exists so that each worker can have a
resource of its own, an account or a database, kept for that worker; Playwright's documentation
uses it that way. `testId` names the test, and is stable on purpose so that reports can follow a
test across runs. **Both are unique in space and repeat in time**, so a name made from either alone
fails exactly as `maria` did, on the second run against a shop that stays up.

The clock is unique in time and nearly unique in space. Two workers that start a test in the same
millisecond get the same number, and on a fast machine that is not rare. The UUID is unique in
both, and the price is that `maria-3f1c7a02-…` tells the person reading a failed run nothing.

## Readable at the front, random at the back

The usual answer combines them: a fixed prefix that says what made the data, and a random tail that
makes it unique. Eight hexadecimal characters of a UUID are 32 random bits, about four thousand
million values, which is plenty for the customers one suite creates. If you want to read the date
from the name later, a timestamp in the middle costs nothing. Save it as `tests/signup.spec.js`:

```javascript
import { test, expect } from '@playwright/test';
import { randomUUID } from 'node:crypto';

// A name no other test and no earlier run has used: readable at the
// front, random at the back.
const newName = (who) => `${who}-${randomUUID().slice(0, 8)}`;

test('a new customer can sign up', async ({ page }) => {
  const name = newName('maria');
  await page.goto('/signup.html');
  await page.getByLabel('Name').fill(name);
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.getByRole('status')).toHaveText(`Welcome, ${name}`);
});
```

With the shop left running, which was the condition that failed before, twice:

```
%%CAP unique-twice%%
```

**The expected greeting is built from the same variable as the name typed.** That line is the one
people forget: a test that types a unique name and then checks for `Welcome, maria` has only moved
the bug.

## What unique data does not fix

A unique name protects a test from the data of others when the test **creates** what it needs. It
does nothing for data the test only **reads** and somebody else can change, and it does nothing for
something there is only one of. The shop's basket is the second kind: there is no *basket of
maria-3f1c7a02* to make, only the basket. The section on shared state comes back to it. And
unique data piles up. Every run adds customers that nobody deletes, which in a shop in memory is
harmless and in a real database is a table that grows by thousands of rows a week; the section on
cleanup is about that.
