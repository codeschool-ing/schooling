---
title: Which one, and why this course teaches both
version: 1
---

Picking a framework is a decision with a long tail: the code you write in the first month is code
you maintain for years. So it deserves a reason that will still be true in a year, and "it is the
newer one" or "it benchmarks faster" are rarely that reason.

## Start from what you are building

| if the application is mostly… | the better fit | because |
|---|---|---|
| pages of HTML, forms, people logging in | **Django** | templates, forms, sessions and users are built in |
| data that staff edit by hand | **Django** | the admin is a back office you do not have to build (lesson 5) |
| a JSON API for a front end or a mobile app | either | Django with Django REST Framework (lesson 6), or FastAPI |
| a typed contract other teams generate clients from | **FastAPI** | the OpenAPI document comes from the type hints (lesson 8) |
| requests that mostly wait on other services | **FastAPI** | ASGI and `async def` from the first line (lesson 9) |
| a small service with one job | **FastAPI** | nothing in it that the service does not use |

Two things often decide it before the table does. **What the team already knows** is the cheapest
expertise there is: a team fluent in Django ships a JSON API in Django faster than in a framework
it is learning. And **what is already running** matters more than either framework's merits: a
second framework in one company is a second set of answers to every row of the first section's
table, maintained by the same people.

## The speed question

FastAPI has *fast* in its name, and its benchmarks are real. But for most requests in most
applications, the time goes to the database query and the network, not to the framework's own
code, and a slow query is equally slow under both. Where FastAPI is faster in a way users notice is
the case the table names: many requests waiting on something slow at once. Lesson 9 measures that,
and measures a case where it buys nothing.

## How this course is laid out

The course builds **one application twice**, so each framework's choices can be compared on the
same problem. It is **agenda**, a small site for a community's events: people browse what is on,
register for an event with a limited number of seats, and organisers manage the events and see who
is coming.

| lessons | what is built |
|---|---|
| 2 to 6 | agenda in **Django**: the project, its pages, its models on PostgreSQL, the admin, and a JSON API with Django REST Framework |
| 7 to 10 | the same API in **FastAPI**: routes, Pydantic models, its documentation, async, and SQLAlchemy with Alembic on the same database server |
| 11 to 13 | for **both**: logging in, permissions, and work done outside the request with Celery |
| 14 to 17 | for **both**: tests, configuration, serving in production, and containers |

From lesson 2 on, every lesson continues the project the one before it left. Each lesson that adds
a tool installs it before the first command that needs it, and each says at the top where it
starts.
