---
title: Environment variables
version: 1
---

Every process starts with a list of `NAME=value` strings, its environment, copied from the process that
started it. A shell adds to the list with `export`, and a variable written before a command is set for that
command only. Go reads the list with `os.Getenv` and `os.LookupEnv`, and the difference between the two is
the first thing worth knowing. `knobs` prints what `LookupEnv` says about `BOXOFFICE_REGION`:

```
ana@vm:~/knobs$ BOXOFFICE_REGION= ./knobs | tail -1
BOXOFFICE_REGION: "", set: true
ana@vm:~/knobs$ BOXOFFICE_REGION=sao-paulo ./knobs | tail -1
BOXOFFICE_REGION: "sao-paulo", set: true
```

Section 03's runs all said `set: false`. Here the first run sets the variable to nothing, and `LookupEnv`
says it is set and empty, while `os.Getenv` would have returned `""` for both cases. **Most programs treat
empty as unset**, and boxoffice does too: a container definition with `BOXOFFICE_ORIGIN=` and nothing after
it almost always means somebody left it blank, not that the site is the empty string. Use `LookupEnv` when
the difference matters to you.

```
ana@vm:~/knobs$ export BOXOFFICE_REGION=sao-paulo; ./knobs | tail -1; bash -c 'echo "a child sees $BOXOFFICE_REGION"'
BOXOFFICE_REGION: "sao-paulo", set: true
a child sees sao-paulo
```

**An exported variable reaches every process started after it**, the child shell included. That is how a
platform hands configuration to a program, and it is also the first thing section 05 has against secrets
in the environment.

## Strings, every one of them

An environment holds only strings. A port, a pool size or a timeout has to be parsed, and a value that does
not parse is the program's problem to report, with the variable's name in the message, because a message
that says `parse error` without saying which of thirty variables caused it sends somebody reading through
all thirty. Section 07 reuses the flag package's parsers for this, so `BOXOFFICE_WRITE_TIMEOUT=90s` is read
by exactly the same code as `-write-timeout 90s`.

## Names

Two conventions keep the names out of trouble:

- **A prefix for the program's own settings**, `BOXOFFICE_` here. Short names like `PORT`, `ADDR` or `DEBUG`
  are set by other tools and platforms for their own reasons, and a program that reads them can pick up a
  value that was never meant for it.
- **The well-known names as they are.** `DATABASE_URL` stays without the prefix because other tools read it
  by that name: lesson 8's `sqlc.yaml` does, and several hosting platforms set it for the database they
  provide.

A variable is read once, when the program starts. Changing it afterwards changes nothing in the running
process, so new configuration means a restart, which lesson 17's graceful shutdown makes cheap.
