---
title: Checking the document itself
version: 1
---

**Two different questions get asked of a specification, and they need two different programs.**
The first is whether the document is a valid OpenAPI document at all: every `$ref` lands somewhere,
every path parameter is declared, every response has a description. The second is whether the API
behaves the way the document says. This section answers the first; the contract test, two sections
on, answers the second. A file can pass either one and fail the other.

The tool for the first is `openapi-spec-validator`, a Python program Ubuntu does not package. It is
the one thing in this course that does not come from Ubuntu's archive, and the one download, which
lesson 1 announced when it installed `python3-venv` and `python3-pip`.

## A virtual environment, and why

The obvious command is refused, and it says why:

```
ana@api:~/shelf$ pip install openapi-spec-validator==0.9.0
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.
    
    If you wish to install a non-Debian-packaged Python package,
    create a virtual environment using python3 -m venv path/to/venv.
    Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    sure you have python3-full installed.
    
    If you wish to install a non-Debian packaged Python application,
    it may be easiest to use pipx install xyz, which will manage a
    virtual environment for you. Make sure you have pipx installed.
    
    See /usr/share/doc/python3.12/README.venv for more information.

note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
hint: See PEP 668 for the detailed specification.
```

**Ubuntu 24.04 will not let `pip` install into the system's Python.** Every Python package on the
machine so far came from `apt`, and `apt` keeps track of them; a package `pip` wrote over one of
them would break something `apt` thinks is intact. The way out the message suggests is a **virtual
environment**: a directory with its own copy of the interpreter's entry points and its own
`site-packages`, where `pip` may do as it likes.

Make one inside the project, then install into it with that environment's own `pip`. This step
needs the VM to reach the internet:

```
ana@api:~/shelf$ python3 -m venv ~/shelf/.venv
ana@api:~/shelf$ .venv/bin/pip install openapi-spec-validator==0.9.0 | tail -1
Successfully installed PyYAML-6.0.3 annotated-types-0.8.0 attrs-26.1.0 jsonschema-4.26.0 jsonschema-path-0.5.0 jsonschema-specifications-2025.9.1 lazy-object-proxy-1.12.0 openapi-schema-validator-0.9.0 openapi-spec-validator-0.9.0 pathable-0.6.0 pydantic-2.14.0 pydantic-core-2.50.0 pydantic-settings-2.15.0 python-dotenv-1.2.4 referencing-0.37.0 rfc3339-validator-0.1.4 rpds-py-2026.9.1 six-1.17.0 typing-extensions-4.16.0 typing-inspection-0.4.4
```

`python3 -m venv` printed nothing, which is how it reports success. The second command printed
`pip`'s last line only, and that line is worth reading. You asked for one package and got twenty.
**`==0.9.0` pins the validator and nothing else**: the nineteen packages it depends on were
resolved on the day this was recorded, and on the day you run it some of their versions may be
later. In a project that difference matters, and `pip freeze` is the command that writes every
installed version down, so that a second machine can install the same set.

`.venv` starts with a dot so that `ls` does not list it, and nothing else about the name is
special. Nothing in it needs activating either: running `.venv/bin/openapi-spec-validator` by its
path uses the environment's Python, and running plain `python3` uses Ubuntu's. The two keep their
own copies of a library they both have:

```
ana@api:~/shelf$ .venv/bin/python -c 'import jsonschema; print(jsonschema.__file__)'
/home/ana/shelf/.venv/lib/python3.12/site-packages/jsonschema/__init__.py
ana@api:~/shelf$ python3 -c 'import jsonschema; print(jsonschema.__file__)'
/usr/lib/python3/dist-packages/jsonschema/__init__.py
```

So the contract test, which runs with `python3`, uses the `jsonschema` lesson 1 installed with
`apt`, and the validator uses its own. Deleting `.venv` removes everything the download brought,
and nothing else on the machine notices.

## The validator, on a good file and a broken one

On shelf's document it prints one line, and its exit status is 0:

```
ana@api:~/shelf$ .venv/bin/openapi-spec-validator openapi.yaml; echo "exit $?"
openapi.yaml: OK
exit 0
```

To see what it catches, make a copy with one mistake: rename the path `/authors/{id}` to
`/authors/{author}` and leave everything under it alone. It is the kind of edit that happens while
tidying names, and the file is still perfectly good YAML:

```
ana@api:~/shelf$ sed 's|^  /authors/{id}:|  /authors/{author}:|' openapi.yaml > broken.yaml
ana@api:~/shelf$ diff openapi.yaml broken.yaml
111c111
<   /authors/{id}:
---
>   /authors/{author}:
ana@api:~/shelf$ .venv/bin/openapi-spec-validator broken.yaml; echo "exit $?"
broken.yaml: Validation Error: Path parameter 'author' for 'get' operation in '/authors/{author}' was not resolved
exit 1
```

The path now has a parameter called `author` that no `parameters` list declares. By default the
validator stops at the first error; `--validation-errors all` shows that there is a second one, the
mirror of the first, since the `id` that is declared no longer appears in the path:

```
ana@api:~/shelf$ .venv/bin/openapi-spec-validator --validation-errors all broken.yaml
broken.yaml: Validation Error: [1] Path parameter 'author' for 'get' operation in '/authors/{author}' was not resolved
broken.yaml: Validation Error: [2] Path parameter 'id' for 'get' operation in '/authors/{author}' was not resolved
broken.yaml: 2 validation errors found
```

**The exit status is what a pipeline reads**, `0` for a valid file and `1` for a broken one, so the
same command in CI turns a broken description into a failed build before anybody publishes it.

## What a valid document can still get wrong

The validator compares the document with the rules of OpenAPI, and only with those. It never sees
`rest.py`. A document that promised a field shelf never sends, a status code it never uses or an
address it does not have would pass, as long as it promised them in correct OpenAPI.

shelf's own document is an instance. It passed with one line of output, and it still contains a
rule, the ISBN's thirteen digits, that `rest.py` does not keep. Finding that needs a program that
holds the document in one hand and the running server in the other.
