---
title: Changing a contract without breaking it
version: 1
---

**Once a client depends on your API, every change is safe or breaking, and which one it is depends
as much on how the client reads as on what you changed.** A field added to a response breaks nobody
who ignores what they did not ask for, and breaks every client that refuses anything unexpected.
Lesson 1 gave breaking changes a version number; this section is about needing that number less
often.

## The tolerant reader

The careful-sounding way to write a client is to check that every response looks exactly as
expected and to fail on anything else. Here is that client's idea of a book, as a schema with
`additionalProperties: false`, against the catalogue's real book:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books/1 > one.json
ana@api:~/shelf$ echo '{"type": "object", "required": ["id", "title"], "additionalProperties": false, "properties": {"id": {}, "title": {}}}' > strict.json
ana@api:~/shelf$ jsonschema -i one.json strict.json; echo "exit $?"
{'id': 1, 'isbn': '9786500000016', 'title': 'Dom Casmurro', 'author_id': 1, 'year': 1899, 'price': {'amount_cents': 3990, 'currency': 'BRL'}, 'stock': 12, 'in_stock': True}: Additional properties are not allowed ('author_id', 'in_stock', 'isbn', 'price', 'stock', 'year' were unexpected)
exit 1
```

Six fields the client never needed, and it fails on all of them; the next field the catalogue adds
would break it too. The tolerant version asks for what it uses and ignores the rest:

```
ana@api:~/shelf$ echo '{"type": "object", "required": ["id", "title"], "properties": {"id": {}, "title": {}}}' > tolerant.json
ana@api:~/shelf$ jsonschema -i one.json tolerant.json; echo "exit $?"
exit 0
```

That is the **tolerant reader**: read the fields you need, ignore the ones you do not, and treat an
enum value you have never seen as "something else". It is the same schema keyword pointing the other
way from the section on validation. **On input the server is strict, because a field it ignores is a
client's mistake it hides; on output the client is tolerant, because a field it refuses is a server's
improvement it turns into an outage.**

## What breaks, and what does not

| change | breaks a tolerant client? | why |
|---|---|---|
| add a field to a response | no | it reads only what it needs |
| add an optional field to a request | no | old clients do not send it, and the default applies |
| add an endpoint, a filter or a sort field | no | nothing old uses it |
| add a value to an enum in a response | no, if the contract said it may grow | a client that listed every value fails on the new one |
| remove or rename a field | **yes** | whoever read it now reads nothing |
| change a field's type | **yes** | lesson 1's version 2 did this to the price |
| make an optional request field required | **yes** | old clients never send it |
| tighten validation, such as a shorter `maxLength` | **yes** | requests that were accepted are now refused |
| change an error's `type` | **yes** | clients branch on it |
| change what a field means, keeping its name and type | **yes, silently** | every client is now wrong and none of them fails |

**The last row is the worst one, because nothing reports it.** Say `in_stock` starts meaning
"can be shipped today" instead of "at least one copy". Every response is still a boolean in the right
place; the schema passes, the tests pass, and every client acts on a fact that changed under it. A
new meaning gets a new name, `ships_today`, and the old field keeps its old meaning until it is
retired the way lesson 1 retires a version.

## The contract is what clients use

A contract is not only what the documentation says. Hyrum Wright's observation, known as Hyrum's law,
is that with enough users every observable behaviour of an API is depended on by somebody: the order
of a list nobody promised to sort, the wording of a `detail`, how long a request takes. So before a
change, the useful question is not "did we document this?" but "does anybody read this?", and the
reliable way to know is to ask the clients, or to have them write down what they use. That is
called **consumer-driven** design, and when clients' expectations are kept as tests that run against
the server, consumer-driven contract testing.

Two habits make changes safer, and the rest of the course uses both. Lesson 6 writes the whole
contract as an OpenAPI document, which a tool can compare between two releases to flag the rows of
the table above. And when a breaking change cannot be avoided, it goes out as a new version, beside
the old one, as lesson 1 showed.
