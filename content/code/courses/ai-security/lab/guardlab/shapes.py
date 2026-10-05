"""Checking what goes into a model call and what comes out of it.

INPUTS are checked against data/input-rules.json: which fields may be
present, their types, their lengths, the values a closed field may take, and
a list of invisible characters that have no business in a job description.

OUTPUTS are checked against data/output-schema.json with validate() below, a
small subset of JSON Schema written out in the standard library so that every
rule it applies can be read: type, required, properties,
additionalProperties, enum, maxLength, minimum, maximum, pattern, items and
maxItems. Two rules a schema cannot express are applied after it: links must
point at an allowlisted host, and a suggested price may not exceed twice the
client's budget.

THE MODEL OUTPUTS IN data/outputs.jsonl WERE WRITTEN BY THE COURSE. No model
produced them; each one is the kind of reply the lesson needs to show being
caught, and the lesson says so where it quotes them.
"""
import json
import re
from urllib.parse import urlsplit

INVISIBLE = {0x200B: "zero width space", 0x200C: "zero width non-joiner",
             0x200D: "zero width joiner", 0x200E: "left-to-right mark",
             0x200F: "right-to-left mark", 0x202A: "left-to-right embedding",
             0x202B: "right-to-left embedding", 0x202C: "pop directional formatting",
             0x202D: "left-to-right override", 0x202E: "right-to-left override",
             0x2066: "left-to-right isolate", 0x2067: "right-to-left isolate",
             0x2068: "first strong isolate", 0x2069: "pop directional isolate",
             0xFEFF: "zero width no-break space"}
TYPES = {"string": str, "integer": int, "array": list, "object": dict}


def check_input(req, rules):
    problems = []
    for name in req:
        if name not in rules["fields"]:
            problems.append("field %r is not accepted" % name)
    for name, rule in rules["fields"].items():
        if name not in req:
            if rule.get("required"):
                problems.append("field %r is missing" % name)
            continue
        value = req[name]
        want = TYPES[rule["type"]]
        if not isinstance(value, want) or isinstance(value, bool):
            problems.append("%s: expected %s, got %s" % (name, rule["type"], type(value).__name__))
            continue
        if "enum" in rule and value not in rule["enum"]:
            problems.append("%s: %r is not one of %s" % (name, value, ", ".join(rule["enum"])))
        if "maxLength" in rule and len(value) > rule["maxLength"]:
            problems.append("%s: %d characters, limit %d" % (name, len(value), rule["maxLength"]))
        if "minimum" in rule and value < rule["minimum"]:
            problems.append("%s: %d is below %d" % (name, value, rule["minimum"]))
        if "maximum" in rule and value > rule["maximum"]:
            problems.append("%s: %d is above %d" % (name, value, rule["maximum"]))
        if isinstance(value, str):
            seen = {}
            for ch in value:
                if ord(ch) in INVISIBLE or (ord(ch) < 32 and ch not in "\n\t"):
                    seen[ord(ch)] = seen.get(ord(ch), 0) + 1
            for cp, n in sorted(seen.items()):
                problems.append("%s: U+%04X %s x%d" % (
                    name, cp, INVISIBLE.get(cp, "control character"), n))
    return problems


def validate(value, schema, path="$"):
    """Every way value breaks schema, as a list of strings. An empty list is
    a pass. It keeps going after the first problem, so that a retry can be
    told everything that was wrong at once."""
    out = []
    t = schema.get("type")
    if t and (not isinstance(value, TYPES[t]) or isinstance(value, bool)):
        return ["%s: expected %s, got %s" % (path, t, type(value).__name__)]
    if "enum" in schema and value not in schema["enum"]:
        out.append("%s: %r is not one of %s" % (path, value, ", ".join(schema["enum"])))
    if isinstance(value, str):
        if "maxLength" in schema and len(value) > schema["maxLength"]:
            out.append("%s: %d characters, limit %d" % (path, len(value), schema["maxLength"]))
        if "pattern" in schema and not re.search(schema["pattern"], value):
            out.append("%s: %r does not match %s" % (path, value, schema["pattern"]))
    if isinstance(value, int) and not isinstance(value, bool):
        if "minimum" in schema and value < schema["minimum"]:
            out.append("%s: %d is below %d" % (path, value, schema["minimum"]))
        if "maximum" in schema and value > schema["maximum"]:
            out.append("%s: %d is above %d" % (path, value, schema["maximum"]))
    if isinstance(value, list):
        if "maxItems" in schema and len(value) > schema["maxItems"]:
            out.append("%s: %d items, limit %d" % (path, len(value), schema["maxItems"]))
        for i, item in enumerate(value):
            out += validate(item, schema.get("items", {}), "%s[%d]" % (path, i))
    if isinstance(value, dict):
        props = schema.get("properties", {})
        for name in schema.get("required", []):
            if name not in value:
                out.append("%s: %r is required" % (path, name))
        for name, v in value.items():
            if name in props:
                out += validate(v, props[name], path + "." + name)
            elif schema.get("additionalProperties") is False:
                out.append("%s: %r is not allowed" % (path, name))
    return out


def check_output(text, schema, hosts, budget):
    try:
        value = json.loads(text)
    except json.JSONDecodeError as e:
        return ["not JSON: %s" % e.msg + " at character %d" % e.pos]
    problems = validate(value, schema)
    if isinstance(value, dict):
        for i, link in enumerate(value.get("links", []) if isinstance(value.get("links"), list) else []):
            host = urlsplit(link).hostname if isinstance(link, str) else None
            if host and host not in hosts:
                problems.append("$.links[%d]: host %s is not on the allowlist" % (i, host))
        price = value.get("price_suggestion_cents")
        if isinstance(price, int) and budget and price > 2 * budget:
            problems.append("$.price_suggestion_cents: %d is more than twice the budget of %d"
                            % (price, budget))
    return problems
