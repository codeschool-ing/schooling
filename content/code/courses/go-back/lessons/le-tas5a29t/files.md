---
title: Configuration files, and when you need one
version: 1
---

Flags and variables are flat: a name and a string. boxoffice's seven settings fit that comfortably. A
configuration file earns its place when the settings stop being flat: a list of allowed sites, a timeout
per route, a block of settings per tenant. Writing those as `BOXOFFICE_ROUTE_3_TIMEOUT` is where
variables stop helping.

When that day comes, the standard library already reads one format: **`encoding/json` decodes a file
into the same `config` struct** section 07 fills from flags, with `DisallowUnknownFields` from lesson 3
refusing a misspelt key instead of ignoring it. YAML and TOML read more comfortably by hand and allow
comments, and each needs a library.

## The library that does everything

**Viper** is the best-known Go configuration library: it reads JSON, YAML, TOML and other formats, merges
them with variables and flags, and can watch a file for changes. It is a large dependency for a small job,
and the cost can be measured. Here is an empty program that only imports it, compared with `knobs`:

```
ana@vm:~/vipertry$ go mod init example.com/vipertry 2>/dev/null; go get github.com/spf13/viper@v1.21.0 2>&1 | grep -c "^go: added"
13
ana@vm:~/vipertry$ go list -m all | wc -l; go build -o vipertry . && ls -l vipertry ~/knobs/knobs
27
-rwxr-xr-x 1 ana ana 2501577 Oct 22 19:43 /home/ana/knobs/knobs
-rwxr-xr-x 1 ana ana 6312912 Oct 22 19:43 vipertry
```

Adding Viper added 13 modules to the project, and its module graph holds 27. The program that does
nothing with it is 6.3 MB, against 2.5 MB for `knobs`, which parses flags and reads a variable. Every one
of those modules is code you ship, update and trust. **For a command-line tool with dozens of settings in
several formats, that can be a fair price; for a server with seven settings, `flag` and `os.Getenv` do the
same job in sixty lines you can read.**

## `.env` files

A `.env` file is a list of `NAME=value` lines kept beside the code, a convenience for development so a
developer does not type the same variables into every terminal. Two habits keep it harmless. **It is never
committed**, because sooner or later it holds a secret: it goes in `.gitignore`, and an `.env.example` with
the names and no values is committed in its place. **And the program does not read it.** The shell loads it
into the environment, and the program reads the environment as always:

```sh
set -a; . ./.env; set +a
./boxoffice
```

`set -a` exports every variable the file sets, and `set +a` turns that off again. Libraries that load
`.env` from inside the program exist, and they create a second way for configuration to arrive that only
works on developers' machines. Production has no `.env`; container platforms and systemd take variables,
or a file of them, in their own way, which lesson 16 uses.
