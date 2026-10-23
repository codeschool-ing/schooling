---
title: Two philosophies, and what each one assumes
version: 1
---

Both frameworks are good, and both are used by large companies for serious work. **The useful
question is not which is better. It is what each one assumes about the application you are
building**, because a framework is fast to work with exactly where its assumptions hold and
awkward where they do not.

## Django assumes a website with a database behind it

Django was written in 2003 and 2004 at a newspaper in Kansas, the *Lawrence Journal-World*, and
released as open source in 2005. Its job was publishing: pages of HTML built from rows in a
database, edited by staff through forms, on deadlines. Everything it assumes follows from that.

- **There is a relational database**, and Django owns the tables: you describe them as Python
  classes and it writes the SQL and the migrations (lesson 4).
- **The server renders HTML.** Templates are built in (lesson 3), and so are forms.
- **People log in.** Users, passwords, sessions and permissions come in the box (lessons 11
  and 12).
- **Somebody has to edit the data.** The admin, a complete back office generated from your models,
  comes in the box too (lesson 5).
- **A project is several apps**, each a folder with its own models, views and templates, which a
  settings file switches on.

Its motto is "the web framework for perfectionists with deadlines", and the deadline is the half
that explains the design. When most of those assumptions hold, a team writes almost nothing that
is not about its own problem.

## FastAPI assumes an API, and type hints as the contract

FastAPI was published in 2018 by Sebastián Ramírez. It is built on two other libraries:
**Starlette**, which handles HTTP and ASGI, and **Pydantic**, which validates data against Python
type hints. Its job is the other half of today's web: JSON for a JavaScript front end, a mobile
app or another service.

- **The response is JSON**, not a page. There are no templates in the box, and no forms.
- **Type hints are the specification.** `name: str` in a function's signature is what FastAPI reads
  to parse the request, validate it, and describe the endpoint to the world (lessons 7 and 8).
- **You choose the database layer.** Nothing is assumed; this course uses SQLAlchemy and Alembic
  (lesson 10).
- **Waiting is the common case.** A route can be an `async def`, and the server can handle other
  requests while one is waiting for a network answer (lesson 9).
- **An application is a module**, which grows into a package when you want it to.

## The same assumptions, side by side

| | Django | FastAPI |
|---|---|---|
| the typical answer | an HTML page, or JSON with Django REST Framework | JSON |
| data | its own ORM and migrations | whatever you install |
| validation | forms and serializers | Pydantic models from type hints |
| logging in | built in | libraries you choose |
| a back office | the admin, built in | none |
| the contract with the server | WSGI, and ASGI since version 3.0 | ASGI |
| documentation of the API | a library, `drf-spectacular` or similar | OpenAPI, generated, built in |

**Read the empty cells as work, not as freedom.** "Whatever you install" is a decision, a version to
keep current and a set of answers your team has to agree on. In exchange, nothing is there that the
application does not use.

## A third one you will meet

**Flask** sits between the two: a small core like FastAPI's, synchronous like classic Django,
extended with plug-ins. It is older than FastAPI and still common, and most of what this course
says about FastAPI's routing, about SQLAlchemy and about serving in production applies to it
unchanged. The course teaches the two that sit at the ends of the range, because seeing both ends
is what makes the middle legible.
