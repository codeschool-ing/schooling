---
title: Actions: doing something to the rows you tick
version: 1
---

The list page has a menu of **actions**, and every model starts with one, *Delete selected*. An
action is a function that receives the rows ticked on the page as a QuerySet and does something with
them. Organisers want the list of who registered, in a spreadsheet, so agenda has one that answers
with a CSV file: `registrations_csv` in the admin file, listed in `EventAdmin.actions`.

The page sends a POST with the action's name and the ids of the ticked rows; curl sends the same,
ticking Django Night and the Testing dojo:

```
ana@vm:~/agenda$ TOKEN=$(grep csrftoken ~/admin-cookies.txt | cut -f7); curl -s -b ~/admin-cookies.txt -d "csrfmiddlewaretoken=$TOKEN&action=registrations_csv&_selected_action=1&_selected_action=3" http://127.0.0.1:8000/admin/events/event/
event,name,email,registered
django-night,Bruno,bruno@example.org,2026-10-16T23:11:13.033333+00:00
testing-dojo,Carla,carla@example.org,2026-10-16T23:11:19.992427+00:00
testing-dojo,Davi,davi@example.org,2026-10-16T23:11:19.995688+00:00
```

**The function's return value is the response**, so an action can redirect, render a confirmation
page or, as this one does, answer with a file. Returning nothing sends the person back to the list.
The query uses lesson 4's `select_related`, so the file costs one query however many registrations
it lists.

Two habits for actions. Give each one a `description`, because that is what the menu shows. And
remember that **an action runs on as many rows as somebody ticked**, possibly every row in the
table, so one that changes data should either be quick and idempotent, or hand the work to a
background task, which is lesson 13.
