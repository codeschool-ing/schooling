---
title: Output formats, and asking for one field
version: 1
---

**Every Azure CLI command that answers with data answers with JSON, and everything else is a view of
that JSON.** `--output` chooses the view and `--query` chooses the part of it, and both are applied by
the CLI on your computer after the answer has arrived. In this lab the richest answer that needs no
account is the list of clouds lesson 1 met, so it serves as the data for this section.

## The same answer, four ways

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l24-pipeline\" aria-label=\"What happens to an answer inside the Azure CLI, left to right. The answer arrives as JSON. The query, written in JMESPath, keeps the part asked for. The output format then prints it as json, table, tsv or yaml. Both steps run on your computer, after the answer has arrived.\"><defs><marker id=\"l24-pipeline-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"680.0\" height=\"170.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"36.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">your computer</text><rect x=\"50.0\" y=\"70.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the answer</text><text x=\"130.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">JSON</text><rect x=\"280.0\" y=\"70.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the query</text><text x=\"360.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">--query</text><rect x=\"510.0\" y=\"70.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the view</text><text x=\"590.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">--output</text><path d=\"M211.0 105.0 L279.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l24-pipeline-af-ah-paper-dim)\"></path><path d=\"M441.0 105.0 L509.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l24-pipeline-af-ah-paper-dim)\"></path><text x=\"360.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[?name=='AzureCloud'] .endpoints  | [0]</text><text x=\"130.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">[ {...}, {...}, ... ]</text><text x=\"590.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">json  table  tsv  yaml</text><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">nothing in either step is sent to Azure: both cut what already came back</text></svg>", "caption": "The query picks the part, the output chooses how to print it, both after the answer is in."}
```

```
ana@laptop:~/azure/cli$ az cloud list --query "[].name" --output tsv
AzureCloud
AzureChinaCloud
AzureUSGovernment
AzureBleuCloud
ana@laptop:~/azure/cli$ az cloud list --query "[].{name: name, active: isActive}" --output table
Name               Active
-----------------  --------
AzureCloud         True
AzureChinaCloud    False
AzureUSGovernment  False
AzureBleuCloud     False
ana@laptop:~/azure/cli$ az cloud show --query "{resourceManager: endpoints.resourceManager}" --output yaml
resourceManager: https://management.azure.com/
ana@laptop:~/azure/cli$ az cloud show --query endpoints.resourceManager --output json
"https://management.azure.com/"
```

The views worth knowing:

| `--output` | what it prints | for |
|---|---|---|
| `json` | the whole answer, indented; the default | reading by eye, and `jq` |
| `jsonc` | the same, in colour | reading by eye only: the colour codes break a pipe |
| `table` | columns, with headers, for the top-level fields | a quick look at a list |
| `tsv` | values separated by tabs, no keys, no quotes | shell scripts |
| `yaml` | the answer as YAML | configuration files |
| `none` | nothing | commands run for their effect |

**`tsv` is the one for scripts, and it drops the keys**, so the columns come out in the order the
JSON had them, which is not a promise the CLI makes. Ask for exactly the fields you want with
`--query`, and the order is yours.

## `--query` is JMESPath

The language behind `--query` is **JMESPath**, a query language for JSON with a published
specification. Four of its pieces cover most of what a working day needs:

```
ana@laptop:~/azure/cli$ az cloud list --query "[?name=='AzureCloud'].endpoints.resourceManager | [0]" --output tsv
https://management.azure.com/
ana@laptop:~/azure/cli$ az cloud list --query "length([])"
4
ana@laptop:~/azure/cli$ az cloud list --query "sort_by([], &name)[].{name: name, active: isActive}"
[
  {
    "active": false,
    "name": "AzureBleuCloud"
  },
  {
    "active": false,
    "name": "AzureChinaCloud"
  },
  {
    "active": true,
    "name": "AzureCloud"
  },
  {
    "active": false,
    "name": "AzureUSGovernment"
  }
]
```

Read the first one left to right: `[?name=='AzureCloud']` keeps the entries whose `name` is
`AzureCloud`, `.endpoints.resourceManager` takes one field from each, and `| [0]` turns the list of one
into the value itself, which is why `tsv` printed a bare address with no brackets. The second counts
the list with `length`. The third sorts by name and builds a new object per entry with `{name: name,
active: isActive}`, renaming a field on the way. Inside `sort_by`, `&name` is a reference to the field
rather than its value.

| piece | means |
|---|---|
| `[]` | every entry of a list |
| `[?expr]` | the entries where `expr` is true; strings are in single quotes |
| `.field` | one field |
| `{a: x, b: y}` | a new object made of chosen fields |
| `\| [0]` | stop treating it as a list, and take the first |
| `length()`, `sort_by()`, `contains()`, `starts_with()` | functions |

**Quote the whole query in double quotes and the strings inside it in single quotes.** The shell then
leaves the single quotes alone and JMESPath receives them; the other way round, the shell eats them,
and the query fails with an error about a field that does not exist.

## An empty answer is not an error

The command a script runs most often to check where it is, and what it says here:

```
ana@laptop:~/azure/cli$ az account list; echo "exit code $?"
WARNING: Please run "az login" to access your accounts.
[]
exit code 0
```

**A warning, an empty list, and an exit code of 0.** The CLI treats *you have no subscriptions* as a
correct answer, which it is, and a script that only checks the exit code carries on as if all were
well, then fails three commands later on something that has nothing to do with the cause. Check what
came back: `az account show` fails with an exit code when nobody has signed in, and a list can be
counted with `--query "length([])"`.

## When to reach for `jq` instead

`--query` is enough for anything the CLI itself answered. The lessons of this course also use `jq`,
because a compiled Bicep template is a file, not a CLI answer, and `--query` only works on the
answer of the command it is given to. The rule is short: **`--query` for an `az` answer, `jq` for
everything else**, and never parse a `table` with `grep` and `awk`, because its column widths depend on
the longest value in it.
