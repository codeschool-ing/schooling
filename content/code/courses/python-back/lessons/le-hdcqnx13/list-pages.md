---
title: List pages people can work with
version: 1
---

A list of titles is a start. An organiser wants the date, the venue, how full each event is, a way
to search and a way to narrow the list. All of it is configuration on a **`ModelAdmin`** class.
This is the whole of `events/admin.py` for the rest of the lesson; the inline, the action and the
registrations' page are the next three sections' subjects:

```schooling-example
{"language": "python", "file": "events/admin.py", "parts": [{"code": "# events/admin.py\nimport csv\n\nfrom django.contrib import admin\nfrom django.db.models import Count\nfrom django.http import HttpResponse\n\nfrom .models import Event, Registration\n\n\n", "note": "Everything the admin shows is configured here, in the `events` app's own `admin.py`."}, {"code": "class RegistrationInline(admin.TabularInline):\n    model = Registration\n    fields = [\"name\", \"email\", \"created_at\"]\n    readonly_fields = [\"created_at\"]\n    extra = 0\n\n\n", "note": "**An inline** puts one model's rows inside another's page: each event's registrations, as a table. `extra = 0` adds no empty rows beyond the one for adding."}, {"code": "@admin.action(description=\"Download registrations as CSV\")\ndef registrations_csv(modeladmin, request, queryset):\n    response = HttpResponse(content_type=\"text/csv\")\n    writer = csv.writer(response)\n    writer.writerow([\"event\", \"name\", \"email\", \"registered\"])\n    for r in Registration.objects.filter(event__in=queryset).select_related(\"event\"):\n        writer.writerow([r.event.slug, r.name, r.email, r.created_at.isoformat()])\n    return response\n\n\n", "note": "**An action** is a function the list page offers for the rows you tick. This one answers with a CSV file instead of a page."}, {"code": "@admin.register(Event)\nclass EventAdmin(admin.ModelAdmin):\n    list_display = [\"title\", \"starts_at\", \"venue\", \"capacity\", \"taken\"]\n    list_filter = [\"venue\"]\n    search_fields = [\"title\", \"description\"]\n", "note": "**`@admin.register`** registers the model with this configuration. `list_display` chooses the columns, `list_filter` the sidebar, `search_fields` what the search box searches."}, {"code": "    prepopulated_fields = {\"slug\": [\"title\"]}\n    inlines = [RegistrationInline]\n    actions = [registrations_csv]\n\n", "note": "`prepopulated_fields` fills the slug from the title as you type, in the browser."}, {"code": "    def get_queryset(self, request):\n        return super().get_queryset(request).annotate(taken=Count(\"registrations\"))\n\n", "note": "**One query for the whole list**: lesson 4's `annotate`, so the seats-taken column does not cost one `COUNT` per row."}, {"code": "    @admin.display(ordering=\"taken\", description=\"seats taken\")\n    def taken(self, event):\n        return event.taken\n\n\n", "note": "A column that is not a field, sortable through the annotation."}, {"code": "@admin.register(Registration)\nclass RegistrationAdmin(admin.ModelAdmin):\n    list_display = [\"name\", \"email\", \"event\", \"created_at\"]\n    list_filter = [\"event\"]\n    search_fields = [\"name\", \"email\"]\n", "note": "The registrations get a list page of their own, filtered by event."}]}
```

The list page, after `runserver` reloads:

```
ana@vm:~/agenda$ page /admin/events/event/ | sed -n "/^Select event to change/,/^[0-9]* events/p"
Select event to change

  * Add event

Filter

Show counts

By venue

  * All
  * Community Centre, room 3
  * Public Library, lab 2

Search events

Search [                                        ] [Search]
Action: [- Select an option -         ] Run 0 of 3 selected

[ ]         Title                                        Venue           Capacity Seats taken
                                Starts at
[ ]     Django Night      Nov. 12, 2026, 7 p.m. Community Centre, room 3 40       1
[ ] Async Python workshop Nov. 19, 2026, 2 p.m. Public Library, lab 2    12       12
[ ]     Testing dojo      Nov. 26, 2026, 7 p.m. Community Centre, room 3 20       2

Pagination events

3 events
```

**Every column in `list_display` is a column on the page**, and `Seats taken` is the annotation:
the method `taken` returns the number lesson 4's `Count` put on each row, and `ordering="taken"` makes
the column sortable by it. The date is formatted in São Paulo's time, from `TIME_ZONE`, exactly as
the site's own templates do. The sidebar, `By venue`, comes from `list_filter`, with one link per
distinct value.

## Search

The search box looks in every field of `search_fields`, case-insensitively:

```
ana@vm:~/agenda$ page "/admin/events/event/?q=dojo" | sed -n "/^Select event to change/,/^[0-9]* event/p"
Select event to change

  * Add event

Filter

Show counts

By venue

  * All
  * Community Centre, room 3
  * Public Library, lab 2

Search events

Search [dojo                                    ] [Search] 1 result (3 total)
Action: [- Select an option -         ] Run 0 of 1 selected

[ ]    Title                                    Venue           Capacity Seats taken
                       Starts at
[ ] Testing dojo Nov. 26, 2026, 7 p.m. Community Centre, room 3 20       2

Pagination events

1 event
```

`1 result (3 total)` is the admin being precise about what it filtered. Behind it is lesson 4's
`icontains` on each field, joined by `OR`. A search field that follows a relation, such as
`registrations__email`, searches across the join, and on a large table it is a query worth looking
at with `explain()` first.

## Three settings worth knowing

| | what it does |
|---|---|
| `list_per_page` | rows per page, 100 by default |
| `date_hierarchy = "starts_at"` | a row of links to drill down by year, month and day |
| `list_select_related` | follows foreign keys in the list's one query, lesson 4's `select_related` |

**The query count of an admin list is your problem, not Django's.** A `list_display` column that
reads a related object, `event.organiser.email` for instance, runs one query per row unless the
queryset joins it. `get_queryset` is where that is fixed, as `taken` already is here.
